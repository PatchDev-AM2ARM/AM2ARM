"""Verified ZIP reconstruction, derived from the AM2R Android Autopatcher."""
import argparse
import hashlib
import json
import os
import platform
import shutil
import subprocess
import sys
import tempfile
import threading
import zipfile
from pathlib import Path


# ----------------------------------------------------------------------------
# Core

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


def load_manifest(edition="standard", patch_root=None):
    if edition not in ("standard", "dual"):
        raise PatchError("Choose the Standard or Dual Screen edition.")
    root = Path(patch_root) if patch_root else base_dir() / "patch-bundle"
    p = root / edition / "assembly.json"
    # Older single-edition downloads remain usable; never substitute them for Dual Screen.
    if patch_root is None and not root.exists() and edition == "standard":
        p = base_dir() / "patch-data" / "assembly.json"
    if not p.is_file():
        raise PatchError(f"patch data missing: {p}")
    return json.loads(p.read_text()), p.parent


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


def read_zip_member(source, member):
    source = Path(source)
    if source.is_dir():
        p = source / member
        if not p.is_file():
            raise PatchError(f"missing file in your 1.1 copy: {member}")
        return p.read_bytes()
    # Allow an original ZIP to wrap its member paths in a containing directory.
    with zipfile.ZipFile(source) as z:
        for n in z.namelist():
            if n == member or n.endswith("/" + member):
                return z.read(n)
    raise PatchError(f"missing file in your 1.1 zip: {member}")


def patch(source_zip, out_dir, progress, edition="standard", patch_root=None):
    """Build the game archive. Returns (archive_path, sha256)."""
    # Keep the selected edition's manifest, wrapper, and delta together for the entire operation.
    manifest, data_dir = load_manifest(edition, patch_root)
    xdelta = find_xdelta3()
    wrapper = data_dir / "wrapper.bin"
    if not wrapper.is_file():
        raise PatchError(f"patch data missing: {wrapper}")

    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    datawin = locate_datawin(source_zip, manifest["datawin_sha256"], progress, out_dir)
    game_data_tmp = None
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=".game_data", dir=out_dir) as temporary_game_data:
            game_data_tmp = Path(temporary_game_data.name)
        progress(0, 1, "Rebuilding game data from your copy…")
        # Rebuild game data in temporary storage and check its hash before assembling the game archive.
        r = subprocess.run(
            [xdelta, "-d", "-f", "-s", str(datawin), str(data_dir / manifest["game_data"]["xdelta"]), str(game_data_tmp)],
            capture_output=True, text=True)
        if r.returncode != 0:
            raise PatchError(f"xdelta3 failed:\n{r.stderr.strip()}")
        if sha256_file(game_data_tmp) != manifest["game_data"]["sha256"]:
            raise PatchError("Rebuilt game data failed verification (corrupt download?).")

        name = manifest["archive_name"]
        if Path(name).name != name or not name.endswith(".zip"):
            raise PatchError("Invalid output filename in patch data.")
        archive_path = out_dir / name
        total = manifest["final_size"]
        done = 0
        final = hashlib.sha256()

        # Assemble beside the destination under a temporary name until the full output passes verification.
        temporary = tempfile.NamedTemporaryFile(prefix=".patch-", suffix=".tmp", dir=out_dir, delete=False)
        pending = Path(temporary.name)
        try:
            with temporary as out, open(wrapper, "rb") as w, open(game_data_tmp, "rb") as d:
                assemble(manifest, source_zip, out, w, d, final, progress)
            digest = final.hexdigest()
            done = pending.stat().st_size
            if done != total or digest != manifest["final_sha256"]:
                raise PatchError("Final game archive failed verification — patching aborted, nothing was kept.")
            # Keep an existing matching game archive, but refuse to replace a different file with the same output name.
            if archive_path.exists():
                if sha256_file(archive_path) != digest:
                    raise PatchError("A different file already uses the output name. Choose another output folder.")
            else:
                os.replace(pending, archive_path)
        # Remove the temporary game archive after either a successful move or a failed verification.
        finally:
            pending.unlink(missing_ok=True)
        progress(total, total, "Done")
        return archive_path, digest
    # Release the verified source copy and rebuilt game data when this operation ends.
    finally:
        datawin.unlink(missing_ok=True)
        if game_data_tmp is not None:
            game_data_tmp.unlink(missing_ok=True)


def assemble(manifest, source_zip, out, w, d, final, progress):
    total = manifest["final_size"]
    done = 0
    # Reconstruct the original game archive byte order from wrapper ranges, rebuilt game data, and source ZIP members.
    for seg in manifest["segments"]:
        if seg["source"] == "wrapper":
            w.seek(seg["offset"])
            remaining = seg["length"]
            seg_h = hashlib.sha256()
            while remaining:
                chunk = w.read(min(1 << 20, remaining))
                if not chunk:
                    raise PatchError("wrapper.bin truncated (corrupt download?)")
                seg_h.update(chunk)
                final.update(chunk)
                out.write(chunk)
                remaining -= len(chunk)
                done += len(chunk)
                progress(done, total, "Building SD files…")
            # Check each wrapper range as well as the complete game archive hash checked by the caller.
            if seg_h.hexdigest() != seg["sha256"]:
                raise PatchError("wrapper.bin failed verification (corrupt download?)")
        elif seg["source"] == "game_data":
            d.seek(0)
            while True:
                chunk = d.read(1 << 20)
                if not chunk:
                    break
                final.update(chunk)
                out.write(chunk)
                done += len(chunk)
                progress(done, total, "Building SD files…")
        # Verify each original member before adding it to the temporary output.
        elif seg["source"] == "zip":
            chunk = read_zip_member(source_zip, seg["path"])
            if hashlib.sha256(chunk).hexdigest() != seg["sha256"]:
                raise PatchError(f"file from your 1.1 copy failed verification: {seg['path']}")
            final.update(chunk)
            out.write(chunk)
            done += len(chunk)
            progress(done, total, "Building SD files…")
        else:
            raise PatchError(f"unknown segment source {seg['source']!r}")


