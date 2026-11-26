"""Exercise reconstruction and failed-output preservation with real deltas."""
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
import zipfile

import am2r_android_patcher as patcher


def digest(data):
    return hashlib.sha256(data).hexdigest()


class PatchTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bundle = self.root / "patch-bundle"
        self.source = self.root / "original.zip"
        self.output = self.root / "out" / "game.apk"
        base = b"original game data\n" * 512
        extra = b"original audio"
        with zipfile.ZipFile(self.source, "w") as z:
            z.writestr("original/data.win", base)
            z.writestr("original/audio.ogg", extra)
        (self.root / "base").write_bytes(base)
        self.bundle.mkdir()
        game = base + b"port"
        wrapper = b"APK header"
        (self.root / "game").write_bytes(game)
        (self.bundle / "wrapper.bin").write_bytes(wrapper)
        subprocess.run(["xdelta3", "-e", "-s", str(self.root / "base"),
                        str(self.root / "game"), str(self.bundle / "droid.xdelta")], check=True)
        self.expected = wrapper + game + extra
        manifest = {"apk_name": "game.apk", "version": "test",
                    "final_sha256": digest(self.expected), "final_size": len(self.expected),
                    "datawin_sha256": digest(base),
                    "droid": {"xdelta": "droid.xdelta", "sha256": digest(game), "size": len(game)},
                    "segments": [{"source": "wrapper", "offset": 0, "length": len(wrapper), "sha256": digest(wrapper)},
                                 {"source": "droid"},
                                 {"source": "zip", "path": "audio.ogg", "length": len(extra), "sha256": digest(extra)}]}
        (self.bundle / "assembly.json").write_text(json.dumps(manifest))

    def run_patch(self):
        return patcher.patch(self.source, self.root / "out", lambda *_: None, patch_root=self.bundle)

    def test_reconstructs_verified_output(self):
        source_hash = digest(self.source.read_bytes())
        output, checksum = self.run_patch()
        self.assertEqual(output.read_bytes(), self.expected)
        self.assertEqual(checksum, digest(self.expected))
        self.assertEqual(source_hash, digest(self.source.read_bytes()))

    # Exercise failures with an existing destination to ensure rejected inputs leave prior output intact.
    def test_bad_wrapper_preserves_existing_output(self):
        self.output.parent.mkdir(); self.output.write_bytes(b"previous valid output")
        (self.bundle / "wrapper.bin").write_bytes(b"corrupt")
        with self.assertRaises(patcher.PatchError): self.run_patch()
        self.assertEqual(self.output.read_bytes(), b"previous valid output")
        self.assertEqual(list(self.output.parent.iterdir()), [self.output])

    def test_wrong_input_produces_no_output(self):
        with zipfile.ZipFile(self.source, "w") as z: z.writestr("data.win", b"wrong release")
        with self.assertRaises(patcher.PatchError): self.run_patch()
        self.assertFalse((self.root / "out").exists())

    # Reject a complete but mismatched stream and check that its pending output is removed.
    def test_failed_final_hash_keeps_no_partial_apk(self):
        path = self.bundle / "assembly.json"
        manifest = json.loads(path.read_text())
        manifest["final_sha256"] = "0" * 64
        path.write_text(json.dumps(manifest))
        with self.assertRaises(patcher.PatchError): self.run_patch()
        self.assertEqual(list((self.root / "out").iterdir()), [])

    def test_valid_patch_does_not_replace_a_different_existing_file(self):
        self.output.parent.mkdir(); self.output.write_bytes(b"keep this file")
        with self.assertRaises(patcher.PatchError): self.run_patch()
        self.assertEqual(self.output.read_bytes(), b"keep this file")
        self.assertEqual(list(self.output.parent.iterdir()), [self.output])

    def test_missing_patch_data_is_reported(self):
        (self.bundle / "assembly.json").unlink()
        with self.assertRaises(patcher.PatchError): self.run_patch()


if __name__ == "__main__":
    unittest.main()
