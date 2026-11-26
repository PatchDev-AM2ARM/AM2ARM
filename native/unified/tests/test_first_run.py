import hashlib
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from first_run import Library, find_original
from patch_core import PatchError
from test_install import original_at, release_at


class FirstLaunchTests(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.card = Path(tmp.name)/'Game Card'
        self.ports = self.card/'roms/ports'
        self.app = self.card/'am2arm-launcher/AM2ARM'
        release_at(self.app/'game/am2arm.zip')
        self.library = Library(self.app, self.card, self.ports)
        self.home = self.card/'home'
        patcher = patch.object(Path, 'home', return_value=self.home)
        patcher.start()
        self.addCleanup(patcher.stop)

    def install(self, contents=b'game'):
        def build(source, bundle, port, progress):
            self.assertEqual(bundle, self.library.bundle)
            port.write_bytes(contents)
            return hashlib.sha256(contents).hexdigest()
        with patch('first_run.build_port', side_effect=build):
            self.library.install(original_at(self.card/'AM2R_11.zip'), lambda *_: None)

    def save(self, folder, name='save1', data=b'progress', when=1000):
        folder.mkdir(parents=True, exist_ok=True)
        (folder/name).write_bytes(data)
        os.utime(folder/name, (when, when))

    def test_root_or_downloads_original_is_found_without_moving_it(self):
        first = original_at(self.card/'Downloads/AM2R_11.zip')
        self.assertEqual(find_original(self.app, self.card, self.ports), first)
        (self.card/'AM2ARM.zip').write_bytes(b'installer')
        second = original_at(self.card/'AM2R_11.zip')
        self.assertIsNone(find_original(self.app, self.card, self.ports))
        first.unlink()
        self.assertEqual(find_original(self.app, self.card, self.ports), second)
        second.unlink()
        (self.card/'AM2R_11.zip').write_bytes(b'bad download')
        self.assertIsNone(find_original(self.app, self.card, self.ports))

    def test_detects_a_renamed_original_in_the_input_folder(self):
        original = original_at(self.app/'patcher/input/my backup.zip')
        self.assertEqual(self.library.original(), original)

    def test_original_in_the_launchers_folder_is_found_by_a_renamed_port(self):
        original = original_at(self.ports/'am2arm-launcher/AM2ARM/patcher/input/my backup.zip')
        self.assertEqual(find_original(self.ports/'am2arm/AM2ARM', self.card, self.ports), original)

    def test_installed_game_is_kept_until_the_release_changes(self):
        self.assertFalse(self.library.installed())
        self.install()
        self.assertTrue(self.library.installed())
        with patch('first_run.sha256_file', side_effect=AssertionError('read an unchanged game')):
            self.assertTrue(Library(self.app, self.card, self.ports).installed())
        release_at(self.app/'game/am2arm.zip', version='1.6.5')
        self.assertFalse(self.library.installed())
        self.install(b'newer game')
        self.assertTrue(self.library.installed())
        self.assertEqual(self.library.port.read_bytes(), b'newer game')

    def test_replacing_the_launcher_folder_keeps_the_game_and_saves(self):
        self.install()
        self.save(self.library.saves)
        self.assertFalse(self.library.data.is_relative_to(self.app.parent))
        moved = self.app.rename(self.card/'am2arm-launcher/older')
        release_at(self.app/'game/am2arm.zip')
        self.assertTrue(self.library.installed())
        self.assertTrue(moved.is_dir())

    def test_copied_card_is_checked_by_contents(self):
        self.install()
        os.utime(self.library.port, (5, 5))
        self.assertTrue(self.library.installed())
        with patch('first_run.sha256_file', side_effect=AssertionError('read an unchanged game')):
            self.assertTrue(self.library.installed())

    def test_damaged_game_is_installed_again(self):
        self.install()
        self.library.port.write_bytes(b'gamf')
        os.utime(self.library.port, (5, 5))
        self.assertFalse(self.library.installed())
        self.library.port.unlink()
        self.assertFalse(self.library.installed())
        self.install()
        self.assertTrue(self.library.installed())

    def test_an_installed_game_needs_no_original(self):
        self.install()
        with patch('first_run.build_port', side_effect=AssertionError('built again')):
            self.library.install(None, lambda *_: None)

    def test_missing_original_installs_nothing(self):
        with self.assertRaisesRegex(PatchError, 'original'):
            self.library.install(self.card/'missing.zip', lambda *_: None)
        self.assertFalse(self.library.installed())

    def test_unreadable_receipt_does_not_count_as_installed(self):
        self.install()
        for text in ('', '[]', '{"release": 1}', 'null'):
            self.library.receipt.write_text(text)
            self.assertFalse(self.library.installed())

    def test_latest_native_linux_saves_are_copied_once(self):
        older = self.ports/'AM2ARM Standard/state/config/AM2RStandardLinux'
        latest = self.card/'AM2ARM-data/home/.config/AM2RDualLinux'
        self.save(older, data=b'older', when=1000)
        self.save(older, 'save2', b'older slot', when=1100)
        self.save(latest, data=b'latest', when=2000)
        self.save(latest, 'data.sav', b'unlocks', when=1500)
        (latest/'config.ini').write_text('settings')
        self.install()
        self.assertEqual({p.name: p.read_bytes() for p in self.library.saves.iterdir()},
                         {'save1': b'latest', 'data.sav': b'unlocks'})
        self.assertEqual((latest/'save1').read_bytes(), b'latest')
        (self.library.saves/'save1').write_bytes(b'played on')
        self.install(b'next release')
        self.library.import_saves()
        self.assertEqual((self.library.saves/'save1').read_bytes(), b'played on')

    def test_saves_of_a_custom_installation_are_found(self):
        record = self.card/'AM2ARM/state/installation.json'
        record.parent.mkdir(parents=True)
        record.write_text('{"game": "My Games/AM2ARM Standard", "stock_saves": "Old/state/config/AM2RStandardLinux"}')
        self.save(self.card/'Old/state/config/AM2RStandardLinux')
        self.library.import_saves()
        self.assertEqual((self.library.saves/'save1').read_bytes(), b'progress')

    def test_no_saves_means_no_saves(self):
        self.library.import_saves()
        self.assertFalse(self.library.saves.exists())


if __name__ == '__main__':
    unittest.main()
