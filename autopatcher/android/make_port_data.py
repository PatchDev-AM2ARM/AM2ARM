#!/usr/bin/env python3
"""Pack the Android build for gmloader-next ports.

Run once per release, after make_patch_data.py:

    make_port_data.py <canonical.apk> <patch bundle> <out_dir>

Produces in <out_dir>, for attaching to the release:
    AM2ARM-gmloader-<version>.zip   the runner, the game's small files and the
                                    delta from AM2R 1.1's data.win
    AM2ARM-music.zip                the soundtrack, only new when a track changes

Neither contains files from the AM2R 1.1 ZIP.
"""

import json
import shutil
import sys
import zipfile
from pathlib import Path

RUNNER = "lib/arm64-v8a/libyoyo.so"


def wanted(name):
    return name == RUNNER or (name.startswith("assets/") and name != "assets/game.droid"
                              and not name.startswith("assets/dexopt/"))


def add(output, name, source, compression):
    info = zipfile.ZipInfo(name, (2000, 1, 1, 0, 0, 0))
    info.compress_type = compression
    info.external_attr = 0o100644 << 16
    with output.open(info, "w") as out:
        shutil.copyfileobj(source, out)


def main(apk_path, bundle, out_dir):
    bundle, out_dir = Path(bundle), Path(out_dir)
    manifest = json.loads((bundle / "assembly.json").read_text())
    out_dir.mkdir(parents=True, exist_ok=True)
    game = out_dir / f"AM2ARM-gmloader-{manifest['version']}.zip"
    music = out_dir / "AM2ARM-music.zip"
    with zipfile.ZipFile(apk_path) as apk, \
            zipfile.ZipFile(game, "w") as game_zip, zipfile.ZipFile(music, "w") as music_zip:
        tracks = []
        for info in sorted((i for i in apk.infolist() if wanted(i.filename)), key=lambda i: i.filename):
            with apk.open(info) as source:
                if info.filename.endswith(".ogg"):
                    name = info.filename.rsplit("/", 1)[-1]
                    add(music_zip, name, source, zipfile.ZIP_STORED)
                    tracks.append(f"{info.CRC:08X} {name}")
                else:
                    add(game_zip, info.filename, source, zipfile.ZIP_LZMA)
        with (bundle / manifest["droid"]["xdelta"]).open("rb") as source:
            add(game_zip, "game.xdelta", source, zipfile.ZIP_LZMA)
        # Lets a port tell which tracks it already has
        game_zip.writestr("music.txt", "\n".join(tracks) + "\n")
        droid = {name: manifest["droid"][name] for name in ("size", "sha256")}
        game_zip.writestr("manifest.json", json.dumps({
            "version": manifest["version"], "datawin_sha256": manifest["datawin_sha256"], "game.droid": droid}, indent=1))
    for path in (game, music):
        print(f"{path}: {path.stat().st_size:,} bytes")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    main(*sys.argv[1:])
