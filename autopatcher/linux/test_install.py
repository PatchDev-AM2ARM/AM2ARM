import hashlib
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest
import zipfile

from linux_patcher import install_archive, PatchError

class InstallTests(unittest.TestCase):
    def setUp(self):
        self.work = tempfile.TemporaryDirectory()
        self.addCleanup(self.work.cleanup)
        self.root = Path(self.work.name)

    def archive(self, members):
        archive = self.root / 'game.zip'
        with zipfile.ZipFile(archive, 'w') as z:
            for name, body in members:
                z.writestr(name, body)
        return archive

    def test_valid_folder_and_executable(self):
        archive = self.archive([('launch.sh', b'#!/bin/sh\n'), ('data/game.unx', b'game')])
        destination = self.root / 'AM2R'
        install_archive(archive, destination)
        self.assertEqual((destination / 'data/game.unx').read_bytes(), b'game')
        self.assertTrue((destination / 'launch.sh').stat().st_mode & stat.S_IXUSR)

    def test_ports_entry_launches_after_copying_to_a_different_path(self):
        archive = self.archive([('launch.sh', b'#!/bin/sh\nprintf "%s\\n" "$@"\n')])
        ports = self.root / 'Ports'
        install_archive(archive, ports / "AM2R Test's Game")
        launcher = ports / "AM2R Test's Game.sh"
        self.assertTrue(launcher.is_file(), 'Ports only lists top-level shell files')
        self.assertTrue(launcher.stat().st_mode & stat.S_IXUSR)
        moved = ports.rename(self.root / 'Another SD card')
        result = subprocess.run([str(moved / launcher.name), 'argument with spaces'],
                                cwd=self.root, capture_output=True, text=True, check=True)
        self.assertEqual(result.stdout, 'argument with spaces\n')

    def test_existing_menu_entry_is_preserved_before_installing(self):
        archive = self.archive([('launch.sh', b'#!/bin/sh\n')])
        launcher = self.root / 'AM2R.sh'
        launcher.write_bytes(b'keep this launcher')
        with self.assertRaises(PatchError):
            install_archive(archive, self.root / 'AM2R')
        self.assertEqual(launcher.read_bytes(), b'keep this launcher')
        self.assertFalse((self.root / 'AM2R').exists())

    def test_dangling_menu_symlink_is_preserved(self):
        archive = self.archive([('launch.sh', b'#!/bin/sh\n')])
        launcher = self.root / 'AM2R.sh'
        launcher.symlink_to('missing-launcher')
        with self.assertRaises(PatchError):
            install_archive(archive, self.root / 'AM2R')
        self.assertTrue(launcher.is_symlink())
        self.assertFalse((self.root / 'AM2R').exists())

    def test_existing_output_is_untouched(self):
        destination = self.root / 'AM2R'
        destination.mkdir()
        (destination / 'save1').write_bytes(b'keep')
        archive = self.archive([('launch.sh', b'new')])
        with self.assertRaises(PatchError):
            install_archive(archive, destination)
        self.assertEqual(list(destination.iterdir()), [destination / 'save1'])

    def test_unsafe_names_leave_no_folder(self):
        for name in ['../outside', '/outside', 'data/../../outside', 'C:/outside',
                     'data\\outside', 'data/./outside', 'data//outside']:
            with self.subTest(name=name):
                archive = self.archive([('launch.sh', b'ok'), (name, b'bad')])
                destination = self.root / 'AM2R'
                with self.assertRaises(PatchError):
                    install_archive(archive, destination)
                self.assertFalse(destination.exists())

    def test_duplicate_paths_rejected(self):
        archive = self.archive([('launch.sh', b'a'), ('launch.sh', b'b')])
        with self.assertRaises(PatchError):
            install_archive(archive, self.root / 'AM2R')

    def test_symlink_member_rejected(self):
        info = zipfile.ZipInfo('link')
        info.create_system = 3
        info.external_attr = (stat.S_IFLNK | 0o777) << 16
        archive = self.archive([(info, b'../../outside')])
        with self.assertRaises(PatchError):
            install_archive(archive, self.root / 'AM2R')

    def test_conflicting_paths_are_atomic(self):
        archive = self.archive([('data', b'file'), ('data/game.unx', b'child')])
        destination = self.root / 'AM2R'
        with self.assertRaises(PatchError):
            install_archive(archive, destination)
        self.assertFalse(destination.exists())
        self.assertFalse((self.root / 'AM2R.sh').exists())

if __name__ == '__main__':
    unittest.main()
