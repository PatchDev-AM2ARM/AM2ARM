"""Find the player's original game, and keep the game built from it."""
import fcntl
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import shutil
from tempfile import NamedTemporaryFile
from zipfile import BadZipFile, ZipFile

from patch_core import PatchError, build_port, read_manifest, sha256_file


SAVES = ('save1', 'save2', 'save3', 'data.sav', 'extras.sav')
# Folders of the native Linux editions, up to 1.6.3.
EDITIONS = ('AM2ARM Standard', 'AM2ARM Dual Screen')
EDITION_SAVES = ('AM2RStandardLinux', 'AM2RDualLinux')


def find_original(app, card, ports):
    """Read ZIP directories only. The patcher verifies the original bytes at install."""
    old_input = app/'patcher/input'
    roots = [old_input, card, card/'Downloads', card/'Download', ports, app,
             card/'AM2ARM/patcher/input', card/'am2arm-launcher/AM2ARM/patcher/input',
             ports/'am2arm-launcher/AM2ARM/patcher/input']
    if card.name.lower() == 'roms' and card.parent != Path('/'):
        roots += [card.parent, card.parent/'Downloads']
    found = set()
    for folder in dict.fromkeys(roots):
        try:
            entries = list(folder.iterdir())
        except OSError:
            continue
        for path in entries:
            if path.suffix.lower() != '.zip' or (folder.name != 'input' and
                    not path.name.lower().startswith('am2r')):
                continue
            try:
                with ZipFile(path) as archive:
                    names = {n.lower() for n in archive.namelist()}
                if any(PurePosixPath(n).name == 'data.win' and
                       str(PurePosixPath(n).with_name('am2r.exe')) in names for n in names):
                    found.add(path.resolve())
            except (OSError, BadZipFile):
                continue
    return found.pop() if len(found) == 1 else None


def write_text(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with NamedTemporaryFile(mode='w', encoding='utf-8', dir=path.parent, delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(text)
        temporary.replace(path)
    finally:
        if temporary:
            temporary.unlink(missing_ok=True)


class Library:
    def __init__(self, app, card, ports):
        self.app, self.card, self.ports = app, card, ports
        self.game = app/'game'
        self.bundle = self.game/'am2arm.zip'
        # Outside the launcher folder, so updates keep it.
        self.data = card/'AM2ARM-data'
        self.port = self.data/'am2arm.port'
        self.saves = self.data/'saves'
        self.receipt = self.data/'installed.json'

    @classmethod
    def from_environment(cls):
        runtime = Path(os.environ['AM2ARM_RUNTIME_DIR']).resolve()
        card = Path(os.environ.get('AM2ARM_GAME_CARD') or runtime.parent.parent)
        ports = Path(os.environ.get('AM2ARM_PORTS_DIR') or card/'ports')
        return cls(runtime.parent, card, ports)

    def original(self):
        return find_original(self.app, self.card, self.ports)

    @property
    def version(self):
        return read_manifest(self.bundle)['version']

    def release(self):
        """Identify the release by its ZIP index, without reading its files."""
        try:
            with ZipFile(self.bundle) as archive:
                index = [f'{i.CRC:08x} {i.file_size} {i.filename}\n' for i in archive.infolist()]
        except (OSError, BadZipFile) as error:
            raise PatchError('The AM2ARM game data is missing or damaged. Extract the complete download again.') from error
        return hashlib.sha256(''.join(index).encode()).hexdigest()

    def stamp(self):
        info = self.port.stat()
        return [info.st_size, info.st_mtime_ns]

    def installed(self):
        """Whether the game on the card came from this release."""
        try:
            record = json.loads(self.receipt.read_text())
            if record['release'] != self.release():
                return False
            if record['stamp'] != self.stamp():
                # Copying a card changes the times.
                if record['sha256'] != sha256_file(self.port):
                    return False
                write_text(self.receipt, json.dumps(dict(record, stamp=self.stamp())))
            return True
        except (OSError, ValueError, KeyError, TypeError):
            return False

    def install(self, source, progress):
        self.data.mkdir(parents=True, exist_ok=True)
        with (self.data/'install.lock').open('a') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            progress(0, 1, 'Checking installed files…')
            if not self.installed():
                if source is None or not Path(source).is_file():
                    raise PatchError('Choose your original AM2R 1.1 ZIP to install the game.')
                digest = build_port(source, self.bundle, self.port, progress)
                write_text(self.receipt, json.dumps(
                    {'release': self.release(), 'sha256': digest, 'stamp': self.stamp()}))
            self.import_saves()

    def edition_saves(self):
        """Every place the native Linux editions could have kept saves."""
        homes = (self.data/'home', self.app/'state/home', self.card/'AM2ARM/state/home',
                 self.ports/'AM2ARM/state/home', Path.home())
        roots = (self.ports, self.card, self.card/'ports', self.app.parent, self.card/'AM2ARM/games',
                 *self.data.glob('games/*'), *self.card.glob('AM2ARM/games/*'))
        configs = [home/'.config' for home in homes] + [root/name/'state/config' for root in roots for name in EDITIONS]
        # Games installed elsewhere, or sharing an older install's saves.
        try:
            record = json.loads((self.card/'AM2ARM/state/installation.json').read_text())
            configs += [self.card/record['game']/'state/config', (self.card/record['stock_saves']).parent]
        except (OSError, ValueError, KeyError, TypeError):
            pass
        return [config/name for config in configs for name in EDITION_SAVES]

    def import_saves(self):
        """Start from the latest native Linux saves. Both games read the same files."""
        if any((self.saves/name).exists() for name in SAVES):
            return
        latest, source = 0, None
        for folder in dict.fromkeys(self.edition_saves()):
            for name in SAVES:
                try:
                    changed = (folder/name).stat().st_mtime_ns
                except OSError:
                    continue
                if changed > latest:
                    latest, source = changed, folder
        if source is None:
            return
        self.saves.mkdir(parents=True, exist_ok=True)
        for name in SAVES:
            if (source/name).is_file():
                shutil.copy2(source/name, self.saves/name)
        print('Saves copied from', source, flush=True)


if __name__ == '__main__':
    raise SystemExit(0 if Library.from_environment().installed() else 1)
