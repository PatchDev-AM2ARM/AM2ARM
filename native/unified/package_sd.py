"""Build the standalone SD-card ZIP."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import stat
import sys
import tempfile
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED, ZIP_STORED

SOURCE = Path(__file__).resolve().parent
REPOSITORY = SOURCE.parent.parent
sys.path.insert(0, str(SOURCE/'menus'))
from launch_layout import APP, card_shortcuts

# Supplies the installer's Python, Tk and X server.
INSTALLER_ZIP = 'https://github.com/PatchDev-AM2ARM/AM2ARM/releases/download/v1.6.3/AM2ARM-Autopatcher-1.6.3-linux-arm64.zip'
INSTALLER_SHA256 = '4c3661d8fbbfe236ef550a8816ee5199ced7034df2b1d8f5584f3bd09b4ea5c1'
INSTALLER = ('runtime/bin', 'runtime/core', 'runtime/lib', 'runtime/licenses', 'runtime/python', 'runtime/share',
             'patcher/assets', 'patcher/licenses', 'patcher/vendor')
PATCHER = {'handheld_gui.py': 'handheld_gui.py', 'handheld_input.py': 'handheld_input.py',
           'handheld_launch.py': 'handheld_launch.py', 'handheld_platform.py': 'handheld_platform.py',
           'handheld_sound.py': 'handheld_sound.py', 'handheld_visuals.py': 'handheld_visuals.py',
           'linux_patcher.py': 'linux_patcher.py', 'patch_core.py': 'patch_core.py', 'LICENSE': 'LICENSE',
           'launch.sh': 'handheld-launch.sh', 'compatibility-check.sh': 'compatibility-check.sh'}
REQUIRED = ('runtime/bin/Xwayland', 'runtime/bin/Xvfb', 'runtime/python/usr/bin/python3.11',
            'runtime/core/ld-linux-aarch64.so.1', 'patcher/vendor/xdelta3/linux-arm64/xdelta3',
            'gmloader/gmloadernext.aarch64', 'gmloader/lib/libdualscreen.so',
            'gmloader/lib/librumble.so', 'gmloader/lib/arm64-v8a/libc++_shared.so',
            'gmloader/fallback/libSDL2-2.0.so.0', 'gmloader/SOURCES.txt')


def digest(path):
    with path.open('rb') as handle:
        return hashlib.file_digest(handle, 'sha256').hexdigest()


def files(root):
    if not root.is_dir():
        raise ValueError(f'Missing input directory: {root}')
    for file in sorted(root.rglob('*')):
        rel = file.relative_to(root)
        if '__pycache__' in rel.parts or file.suffix == '.pyc':
            continue
        if file.is_symlink():
            raise ValueError(f'Unexpected linked input {file}')
        if file.is_file():
            if (any(i in {'.git', 'logs', 'state'} for i in rel.parts)
                    or file.name.lower() in {'am2r.exe', 'data.win', 'game.unx', 'game.droid', 'data.sav', 'extras.sav'}):
                raise ValueError(f'Unexpected input {file}')
            yield rel, file


def installer_files(archive, folder):
    """Unpack the installer's parts of an earlier release."""
    if digest(archive) != INSTALLER_SHA256:
        raise ValueError('The installer ZIP is not ' + INSTALLER_ZIP)
    with ZipFile(archive) as source:
        for info in source.infolist():
            name = info.filename.removeprefix(APP + '/AM2ARM/')
            if name.startswith(tuple(part + '/' for part in INSTALLER)) and not info.is_dir():
                target = folder/name
                target.parent.mkdir(parents=True, exist_ok=True)
                with source.open(info) as data, target.open('wb') as output:
                    shutil.copyfileobj(data, output)
    return folder


def game_files(game, music, folder):
    """Check the release's game and music against each other, and unpack the music."""
    with ZipFile(game) as archive:
        version = json.loads(archive.read('manifest.json'))['version']
        tracks = dict(line.split(' ', 1)[::-1] for line in archive.read('music.txt').decode().splitlines())
        names = set(archive.namelist())
    if not re.fullmatch(r'[0-9]+(?:[.][0-9]+)+', version):
        raise ValueError(f'Unexpected version: {version}')
    if not {'game.xdelta', 'lib/arm64-v8a/libyoyo.so'} <= names or 'assets/game.droid' in names:
        raise ValueError('This is not the AM2ARM-gmloader ZIP.')
    members = {'game/am2arm.zip': game, 'game/gmloader.json': REPOSITORY/'native/gmloader/gmloader.json'}
    with ZipFile(music) as archive:
        if {i.filename: f'{i.CRC:08X}' for i in archive.infolist()} != tracks:
            raise ValueError('The music ZIP is from a different release.')
        for name in archive.namelist():
            if '/' in name or not name.endswith('.ogg'):
                raise ValueError(f'Unexpected music file: {name}')
            archive.extract(name, folder)
            members['game/assets/'+name] = folder/name
    return version, members


def collect(installer, gmloader, game, music, folder):
    members = {}
    for part in INSTALLER:
        for rel, file in files(installer/part):
            members[f'{part}/{rel.as_posix()}'] = file
    for rel, file in files(gmloader):
        members[f'gmloader/{rel.as_posix()}'] = file
    # These replace the scripts in INSTALLER_ZIP.
    for rel, file in files(SOURCE/'runtime'):
        members[f'runtime/{rel.as_posix()}'] = file
    for name, source in PATCHER.items():
        members['patcher/'+name] = REPOSITORY/'autopatcher/linux'/source
    members['launch.sh'] = SOURCE/'launch.sh'
    version, game_members = game_files(game, music, folder)
    members.update(game_members)
    for name in REQUIRED:
        if name not in members:
            raise ValueError(f'Missing component: {name}')
    return version, {'AM2ARM/'+name: file for name, file in members.items()}


def executable(name, file):
    # Windows checkouts and some archives lose the mode.
    with file.open('rb') as handle:
        start = handle.read(4)
    return os.access(file, os.X_OK) and os.name != 'nt' or name.endswith('.sh') or start[:2] == b'#!' \
        or start == b'\x7fELF' and ('/bin/' in name or '/core/ld-' in name or name.endswith(('.aarch64', 'xdelta3.bin')))


def write_archive(path, members):
    if path.exists():
        raise ValueError('Choose a new output path.')
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='.am2arm-zip-', dir=path.parent) as folder:
        partial = Path(folder)/'archive'
        with ZipFile(partial, 'x') as target:
            for name, file in sorted(members.items()):
                info = ZipInfo(name, (2000, 1, 1, 0, 0, 0))
                info.create_system = 3
                info.external_attr = (stat.S_IFREG | (0o755 if executable(name, file) else 0o644)) << 16
                info.compress_type = ZIP_STORED if name.endswith(('.ogg', '.zip')) else ZIP_DEFLATED
                with file.open('rb') as source, target.open(info, 'w') as output:
                    shutil.copyfileobj(source, output, 1024*1024)
        with ZipFile(partial) as archive:
            if set(archive.namelist()) != set(members) or archive.testzip():
                raise RuntimeError('The completed package does not match the staged files.')
        partial.rename(path)
    print(json.dumps(dict(file=path.name, bytes=path.stat().st_size, files=len(members), sha256=digest(path))), flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--installer', type=Path, required=True, help=INSTALLER_ZIP)
    parser.add_argument('--gmloader', type=Path, required=True, help="native/gmloader's output")
    parser.add_argument('--game', type=Path, required=True, help="The release's AM2ARM-gmloader ZIP")
    parser.add_argument('--music', type=Path, required=True, help="The release's AM2ARM-music ZIP")
    parser.add_argument('--output', type=Path, required=True, help='Folder for the SD-card ZIP')
    args = parser.parse_args()
    with tempfile.TemporaryDirectory() as folder:
        stage = Path(folder)
        installer = installer_files(args.installer, stage/'installer') if args.installer.is_file() else args.installer
        version, payload = collect(installer, args.gmloader, args.game, args.music, stage/'music')
        modes = stage/'executables.txt'
        modes.write_text(''.join(name+'\n' for name, file in sorted(payload.items()) if executable(name, file)), newline='\n')
        payload['executables.txt'] = modes
        payload['launch.sh'] = SOURCE/'menus/payload.sh'
        for rel, file in files(SOURCE/'menus/dependencies'):
            payload[f'dependencies/{rel.as_posix()}'] = file
        payload['licenses/README.txt'] = SOURCE/'menus/README-licenses.txt'
        card = {APP+'/'+name: file for name, file in payload.items()}
        write_archive(args.output/f'AM2ARM-{version}-linux-arm64.zip',
                      {**card, **card_shortcuts(stage/'card'), 'AM2ARM-READ-ME.txt': SOURCE/'README-card.txt'})


if __name__ == '__main__':
    main()
