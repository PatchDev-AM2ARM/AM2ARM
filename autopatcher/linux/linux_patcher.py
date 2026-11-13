"""AM2ARM Autopatcher: prepare native ARM64 game folders offline."""
import argparse
import os
from pathlib import Path, PurePosixPath
import shlex
import shutil
import stat
import tempfile
import zipfile

from patch_core import PatchError, base_dir, load_manifest, patch, sha256_file

EDITIONS = {'standard': 'AM2ARM Standard', 'dual': 'AM2ARM Dual Screen'}

def ports_launcher_script(folder_name):
    """The stock Ports menu lists shell files, not the folders containing games."""
    return ('#!/bin/sh\nset -eu\n'
            'am2r_ports_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)\n'
            'exec "$am2r_ports_dir"/' + shlex.quote(folder_name) + '/launch.sh "$@"\n')

def install_archive(archive, destination):
    """Extract a verified game into a new folder without altering existing data."""
    destination = Path(destination)
    if os.path.lexists(destination):
        raise PatchError('That game folder already exists. Choose another output folder to preserve its saves.')
    launcher = destination.with_name(destination.name + '.sh')
    if os.path.lexists(launcher):
        raise PatchError('That Ports menu launcher already exists. Choose another output folder to preserve it.')
    destination.parent.mkdir(parents=True, exist_ok=True)
    try:
        with zipfile.ZipFile(archive) as z:
            members = z.infolist()
            seen = set()
            for member in members:
                name = member.filename.rstrip('/')
                path = PurePosixPath(name)
                if (not name or path.is_absolute() or '..' in path.parts
                    or str(path) != name or '\\' in name or ':' in name
                    or name.casefold() in seen):
                    raise PatchError('Unsafe or duplicate path in the game archive.')
                mode = member.external_attr >> 16
                if stat.S_ISLNK(mode) or stat.S_IFMT(mode) not in (0, stat.S_IFREG, stat.S_IFDIR):
                    raise PatchError('Unsupported file type in the game archive.')
                seen.add(name.casefold())
            size = sum(member.file_size for member in members)
            if shutil.disk_usage(destination.parent).free < size + 128 * 1024 * 1024:
                raise PatchError('Not enough free space to prepare the game folder.')
            with tempfile.TemporaryDirectory(prefix='.am2r-', dir=destination.parent) as temporary:
                pending = Path(temporary) / 'game'
                pending.mkdir()
                for member in members:
                    target = pending / member.filename
                    if member.is_dir():
                        target.mkdir(parents=True, exist_ok=True)
                        continue
                    target.parent.mkdir(parents=True, exist_ok=True)
                    with z.open(member) as source, target.open('xb') as output:
                        shutil.copyfileobj(source, output, 1024 * 1024)
                    executable = (member.external_attr >> 16) & 0o111 or target.suffix == '.sh'
                    target.chmod(0o755 if executable else 0o644)
                if os.path.lexists(destination):
                    raise PatchError('The output folder appeared while preparing the game. Nothing was replaced.')
                entry = launcher.open('x', encoding='utf-8', newline='\n')
                try:
                    with entry:
                        entry.write(ports_launcher_script(destination.name))
                    launcher.chmod(0o755)
                    pending.rename(destination)
                except OSError:
                    launcher.unlink()
                    raise
    except (OSError, zipfile.BadZipFile) as error:
        raise PatchError('Could not prepare the game folder: ' + str(error)) from error
    return destination

def prepare_game(source, output, edition, progress, patch_root=None):
    if edition not in EDITIONS:
        raise PatchError('Select Standard or Dual Screen.')
    output = Path(output).resolve()
    destination = output / EDITIONS[edition]
    if os.path.lexists(destination) or os.path.lexists(destination.with_name(destination.name + '.sh')):
        raise PatchError('That game folder or Ports menu launcher already exists. Choose another output folder to keep it intact.')
    output.mkdir(parents=True, exist_ok=True)
    manifest, _ = load_manifest(edition, patch_root)
    required = manifest['final_size'] * 3 + manifest['game_data']['size'] * 2 + 256 * 1024 * 1024
    if shutil.disk_usage(output).free < required:
        raise PatchError('More free disk space is needed to rebuild and verify this edition.')
    with tempfile.TemporaryDirectory(prefix='.am2r-build-', dir=output) as temporary:
        archive, digest = patch(source, temporary, progress, edition, patch_root)
        progress(0, 1, 'Preparing the SD card folder…')
        install_archive(archive, destination)
    progress(1, 1, 'Ready: copy the game folder and its .sh launcher into Ports on your SD card.')
    return destination, digest

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--zip', type=Path, help='Your original AM2R 1.1 ZIP')
    parser.add_argument('--out', type=Path, help='Folder for the prepared game')
    parser.add_argument('--edition', choices=tuple(EDITIONS), default='standard')
    parser.add_argument('--patch-data', type=Path)
    args = parser.parse_args()
    if args.zip:
        if not args.out:
            parser.error('--out is required with --zip')
        previous = [None]
        def progress(done, total, text):
            percent = int(done * 100 / total) if total > 0 else 0
            current = (text, percent)
            if current != previous[0]:
                print(f'{text} {percent}%', flush=True)
                previous[0] = current
        try:
            result, digest = prepare_game(args.zip, args.out, args.edition, progress, args.patch_data)
        except PatchError as error:
            parser.exit(1, str(error) + '\n')
        print('Ready:', result)
        print('Verified archive SHA-256:', digest)
    else:
        from patcher_gui import run_gui
        run_gui()

if __name__ == '__main__':
    main()
