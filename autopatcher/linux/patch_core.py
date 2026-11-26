"""Rebuild the game from the player's AM2R 1.1 copy and a release's port data."""
import hashlib
import json
import os
import platform
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path


class PatchError(Exception):
    pass


def base_dir():
    # Patch data sits next to this script / frozen executable.
    if getattr(sys, "frozen", False):
        return Path(sys.executable).resolve().parent
    return Path(__file__).resolve().parent


def find_xdelta3():
    # Prefer the bundled decoder for this platform, then fall back to a decoder on the executable path.
    system = platform.system()
    exe = "xdelta3.exe" if system == "Windows" else "xdelta3"
    plat = None
    if platform.machine().lower() in ("x86_64", "amd64"):
        plat = {"Windows": "windows-x64", "Linux": "linux-x64"}.get(system)
    elif system == "Linux" and platform.machine().lower() in ("aarch64", "arm64"):
        plat = "linux-arm64"
    if plat:
        vendored = base_dir() / "vendor" / "xdelta3" / plat / exe
        if vendored.is_file():
            return str(vendored)
    found = shutil.which("xdelta3")
    if found:
        return found
    raise PatchError(
        "No compatible xdelta3 decoder found. Install xdelta3 for your device's "
        "operating system and processor, or use the matching portable download.")


def sha256_file(path, chunk=1 << 20):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while True:
            b = f.read(chunk)
            if not b:
                break
            h.update(b)
    return h.hexdigest()


def read_manifest(bundle):
    try:
        with zipfile.ZipFile(bundle) as archive:
            return json.loads(archive.read("manifest.json"))
    except (OSError, KeyError, ValueError, zipfile.BadZipFile) as error:
        raise PatchError("The AM2ARM game data is missing or damaged. Extract the complete download again.") from error


def locate_datawin(source, expected_sha, progress, temporary_dir=None):
    """Find data.win inside the user's zip (any nesting) or folder.
    Returns a temp file path holding the verified data.win."""
    progress(0, 1, "Checking your AM2R 1.1 copy…")
    source = Path(source)
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".data.win", dir=temporary_dir)
    tmp_path = Path(tmp.name)
    try:
        # Search extracted copies for matching game data before copying a verified candidate into temporary storage.
        if source.is_dir():
            for cand in sorted(source.rglob("*")):
                if cand.is_file() and cand.name.lower() == "data.win":
                    if sha256_file(cand) == expected_sha:
                        tmp.close()
                        shutil.copyfile(cand, tmp_path)
                        return tmp_path
            raise PatchError(
                "No matching data.win found in that folder.\n"
                "Make sure it is the original AM2R 1.1 release.")
        if not zipfile.is_zipfile(source):
            raise PatchError(f"{source.name} is not a zip file.")
        with zipfile.ZipFile(source) as z:
            names = [n for n in z.namelist() if n.lower().endswith("data.win")]
            if not names:
                raise PatchError(
                    "That zip has no data.win inside.\n"
                    "You need the original AM2R 1.1 release (AM2R_11.zip).")
            # Hash each ZIP candidate before retaining its bytes as the delta source.
            for name in names:
                h = hashlib.sha256()
                with z.open(name) as f:
                    while True:
                        b = f.read(1 << 20)
                        if not b:
                            break
                        h.update(b)
                if h.hexdigest() == expected_sha:
                    with z.open(name) as f:
                        shutil.copyfileobj(f, tmp)
                    tmp.close()
                    return tmp_path
        raise PatchError(
            "The data.win inside that zip is not AM2R 1.1.\n"
            "This patcher needs the original, unmodified 1.1 release —\n"
            "a modded or Community-Updates copy will not work.")
    # Remove the temporary source if no acceptable copy could be returned to the patch operation.
    except Exception:
        tmp.close()
        tmp_path.unlink(missing_ok=True)
        raise


def build_port(source, bundle, port, progress):
    """Write the archive gmloader-next runs. Returns its SHA-256."""
    manifest = read_manifest(bundle)
    droid = manifest["game.droid"]
    bundle, port = Path(bundle), Path(port)
    xdelta = find_xdelta3()
    port.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".am2arm-build-", dir=port.parent) as folder, \
            zipfile.ZipFile(bundle) as release:
        work = Path(folder)
        members = [i for i in release.infolist() if i.filename.startswith(("assets/", "lib/")) and not i.is_dir()]
        total = droid["size"] + sum(i.file_size for i in members)
        if shutil.disk_usage(work).free < droid["size"] * 2 + total + 64 * 1024 * 1024:
            raise PatchError("More free space is needed on the game card.")

        # Rebuild game data in temporary storage and check it before using it.
        datawin = locate_datawin(source, manifest["datawin_sha256"], progress, work)
        progress(0, 1, "Rebuilding game data from your copy…")
        with release.open("game.xdelta") as delta, (work / "game.xdelta").open("wb") as out:
            shutil.copyfileobj(delta, out, 1 << 20)
        rebuilt = work / "game.droid"
        r = subprocess.run([xdelta, "-d", "-f", "-s", str(datawin), str(work / "game.xdelta"), str(rebuilt)],
                           capture_output=True, text=True)
        if r.returncode != 0:
            raise PatchError(f"xdelta3 failed:\n{r.stderr.strip()}")
        if rebuilt.stat().st_size != droid["size"] or sha256_file(rebuilt) != droid["sha256"]:
            raise PatchError("Rebuilt game data failed verification (corrupt download?).")
        datawin.unlink()

        done = 0
        pending = work / "port"
        # Level 1 keeps this quick on handhelds.
        with zipfile.ZipFile(pending, "w", zipfile.ZIP_DEFLATED, compresslevel=1) as out:
            def add(member, stream):
                nonlocal done
                with out.open(member, "w") as target:
                    while chunk := stream.read(1 << 20):
                        target.write(chunk)
                        done += len(chunk)
                        progress(done, total, "Building the game…")
            for member in members:
                with release.open(member) as stream:
                    add(member.filename, stream)
            # gmloader-next can only map game.droid when it's stored uncompressed.
            with rebuilt.open("rb") as stream:
                add(zipfile.ZipInfo("assets/game.droid"), stream)
        digest = sha256_file(pending)
        with pending.open("rb+") as written:
            os.fsync(written.fileno())
        os.replace(pending, port)
    progress(total, total, "Done")
    return digest
