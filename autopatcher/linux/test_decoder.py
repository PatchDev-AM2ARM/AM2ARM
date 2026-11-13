from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import patch_core


class DecoderTests(unittest.TestCase):
    def test_arm_linux_prefers_matching_bundle_without_system_decoder(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            decoder = root / 'vendor/xdelta3/linux-arm64/xdelta3'
            decoder.parent.mkdir(parents=True)
            decoder.write_bytes(b'ARM64 executable')
            for architecture in ('aarch64', 'arm64'):
                with self.subTest(architecture=architecture), \
                     patch.object(patch_core, 'base_dir', return_value=root), \
                     patch.object(patch_core.platform, 'system', return_value='Linux'), \
                     patch.object(patch_core.platform, 'machine', return_value=architecture), \
                     patch.object(patch_core.shutil, 'which', return_value=None):
                    self.assertEqual(patch_core.find_xdelta3(), str(decoder))

    def test_arm_linux_uses_native_decoder_instead_of_x64_bundle(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            x64 = root / 'vendor/xdelta3/linux-x64/xdelta3'
            x64.parent.mkdir(parents=True)
            x64.write_bytes(b'x86-64 executable')
            with patch.object(patch_core, 'base_dir', return_value=root), \
                 patch.object(patch_core.platform, 'system', return_value='Linux'), \
                 patch.object(patch_core.platform, 'machine', return_value='aarch64'), \
                 patch.object(patch_core.shutil, 'which', return_value='/usr/bin/xdelta3'):
                self.assertEqual(patch_core.find_xdelta3(), '/usr/bin/xdelta3')

    def test_x64_linux_uses_matching_bundled_decoder(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            decoder = root / 'vendor/xdelta3/linux-x64/xdelta3'
            decoder.parent.mkdir(parents=True)
            decoder.write_bytes(b'x86-64 executable')
            with patch.object(patch_core, 'base_dir', return_value=root), \
                 patch.object(patch_core.platform, 'system', return_value='Linux'), \
                 patch.object(patch_core.platform, 'machine', return_value='x86_64'):
                self.assertEqual(patch_core.find_xdelta3(), str(decoder))


if __name__ == '__main__':
    unittest.main()
