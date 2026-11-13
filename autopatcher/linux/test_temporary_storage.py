import hashlib
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch
import zipfile

import patch_core


class TemporaryStorageTests(unittest.TestCase):
    def test_all_large_temporaries_use_output_filesystem_and_are_removed(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / 'source.zip'
            with zipfile.ZipFile(source, 'w') as archive:
                archive.writestr('data.win', b'original')
            data = root / 'bundle/standard'
            data.mkdir(parents=True)
            (data / 'wrapper.bin').write_bytes(b'')
            expected = b'prepared'
            digest = hashlib.sha256(expected).hexdigest()
            manifest = {'datawin_sha256': hashlib.sha256(b'original').hexdigest(),
                        'game_data': {'xdelta': 'game_data.xdelta', 'sha256': digest},
                        'archive_name': 'result.zip', 'final_size': len(expected),
                        'final_sha256': digest, 'segments': [{'source': 'game_data'}]}
            (data / 'assembly.json').write_text(json.dumps(manifest))
            output = root / 'sd card/output'

            def decode(command, **kwargs):
                self.assertEqual(Path(command[4]).parent, output)
                self.assertEqual(Path(command[-1]).parent, output)
                Path(command[-1]).write_bytes(expected)
                return SimpleNamespace(returncode=0, stderr='')

            with patch.object(patch_core, 'find_xdelta3', return_value='xdelta3'), \
                 patch.object(patch_core.subprocess, 'run', side_effect=decode):
                archive, result = patch_core.patch(source, output, lambda *_: None,
                                                   patch_root=root / 'bundle')
            self.assertEqual(archive.read_bytes(), expected)
            self.assertEqual(result, digest)
            self.assertEqual(list(output.iterdir()), [archive])


if __name__ == '__main__':
    unittest.main()
