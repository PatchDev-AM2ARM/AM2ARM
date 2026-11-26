import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch
import zipfile

import patch_core
from patch_core import PatchError, build_port

ORIGINAL = b'original game data' * 64
REBUILT = b'rebuilt game data' * 96


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def release_at(path, version='1.6.4', rebuilt=REBUILT, delta=b'delta', manifest=True):
    path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(path, 'w') as archive:
        archive.writestr('assets/lang/english.ini', b'[Misc]\n', zipfile.ZIP_LZMA)
        archive.writestr('lib/arm64-v8a/libyoyo.so', b'runner' * 4096, zipfile.ZIP_LZMA)
        archive.writestr('game.xdelta', delta, zipfile.ZIP_LZMA)
        archive.writestr('music.txt', '00000000 musTitle.ogg\n')
        if manifest:
            archive.writestr('manifest.json', json.dumps({
                'version': version, 'datawin_sha256': sha256(ORIGINAL),
                'game.droid': {'size': len(rebuilt), 'sha256': sha256(rebuilt)}}))
    return path


def original_at(path, data=ORIGINAL):
    path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(path, 'w') as archive:
        archive.writestr('AM2R 1.1/AM2R.exe', b'executable')
        archive.writestr('AM2R 1.1/data.win', data)
    return path


class BuildPortTests(unittest.TestCase):
    def setUp(self):
        work = tempfile.TemporaryDirectory()
        self.addCleanup(work.cleanup)
        self.root = Path(work.name)
        self.release = release_at(self.root/'launcher/am2arm.zip')
        self.original = original_at(self.root/'AM2R_11.zip')
        self.port = self.root/'sd card/AM2ARM-data/am2arm.port'

    def build(self, output=REBUILT, progress=lambda *_: None):
        def decode(command, **kwargs):
            # Nothing this size belongs in a handheld's /tmp.
            for name in (command[4], command[5], command[6]):
                self.assertTrue(Path(name).is_relative_to(self.port.parent))
            self.assertEqual(Path(command[4]).read_bytes(), ORIGINAL)
            Path(command[-1]).write_bytes(output)
            return SimpleNamespace(returncode=0, stderr='')
        with patch.object(patch_core, 'find_xdelta3', return_value='xdelta3'), \
                patch.object(patch_core.subprocess, 'run', side_effect=decode):
            return build_port(self.original, self.release, self.port, progress)

    def test_port_holds_the_release_and_the_rebuilt_game_and_nothing_else_is_left(self):
        digest = self.build()
        self.assertEqual(digest, sha256(self.port.read_bytes()))
        self.assertEqual(list(self.port.parent.iterdir()), [self.port])
        with zipfile.ZipFile(self.port) as archive:
            self.assertEqual(sorted(archive.namelist()), [
                'assets/game.droid', 'assets/lang/english.ini', 'lib/arm64-v8a/libyoyo.so'])
            self.assertEqual(archive.read('assets/game.droid'), REBUILT)
            # gmloader-next maps it from the archive.
            self.assertEqual(archive.getinfo('assets/game.droid').compress_type, zipfile.ZIP_STORED)
            self.assertEqual(archive.getinfo('lib/arm64-v8a/libyoyo.so').compress_type, zipfile.ZIP_DEFLATED)

    def test_same_inputs_make_the_same_port(self):
        first = self.build()
        self.port.unlink()
        self.assertEqual(self.build(), first)

    def test_failed_update_keeps_the_game_that_was_there(self):
        self.build()
        installed = self.port.read_bytes()
        with self.assertRaisesRegex(PatchError, 'verification'):
            self.build(output=b'wrong result')
        self.assertEqual(self.port.read_bytes(), installed)
        self.assertEqual(list(self.port.parent.iterdir()), [self.port])

    def test_wrong_original_is_refused_before_decoding(self):
        original_at(self.original, b'modded game')
        with self.assertRaisesRegex(PatchError, 'not AM2R 1.1'):
            self.build()
        self.assertFalse(self.port.exists())

    def test_damaged_download_is_reported(self):
        release_at(self.release, manifest=False)
        with self.assertRaisesRegex(PatchError, 'damaged'):
            self.build()
        self.release.write_bytes(b'not a zip')
        with self.assertRaisesRegex(PatchError, 'damaged'):
            self.build()

    def test_full_card_is_reported_before_writing(self):
        usage = SimpleNamespace(total=0, used=0, free=1024)
        with patch.object(patch_core.shutil, 'disk_usage', return_value=usage), \
                self.assertRaisesRegex(PatchError, 'free space'):
            self.build()
        self.assertEqual(list(self.port.parent.iterdir()), [])

    def test_progress_reaches_the_end(self):
        steps = []
        self.build(progress=lambda done, total, text: steps.append((done, total, text)))
        self.assertEqual(steps[-1][0], steps[-1][1])
        written = [done for done, total, text in steps if total > 1]
        self.assertEqual(written, sorted(written))

    @unittest.skipUnless(shutil.which('xdelta3'), 'needs xdelta3')
    def test_real_delta(self):
        source, target, delta = (self.root/name for name in ('data.win', 'game.droid', 'game.xdelta'))
        source.write_bytes(ORIGINAL)
        target.write_bytes(REBUILT)
        subprocess.run(['xdelta3', '-e', '-9', '-S', 'none', '-f', '-s', str(source), str(target), str(delta)], check=True)
        release_at(self.release, delta=delta.read_bytes())
        build_port(self.original, self.release, self.port, lambda *_: None)
        with zipfile.ZipFile(self.port) as archive:
            self.assertEqual(archive.read('assets/game.droid'), REBUILT)


if __name__ == '__main__':
    unittest.main()
