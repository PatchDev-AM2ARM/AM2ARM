from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import unittest


class CompatibilityCheckTests(unittest.TestCase):
    def test_ports_entry_reaches_report_with_nonexecutable_inner_launcher(self):
        with tempfile.TemporaryDirectory(prefix='AM2ARM SD ') as temp:
            ports = Path(temp)
            app = ports / 'AM2ARM Autopatcher'
            app.mkdir()
            source = Path(__file__).parent
            entry = ports / 'AM2ARM Autopatcher.sh'
            shutil.copy2(source / 'handheld-ports.sh', entry)
            shutil.copy2(source / 'handheld-launch.sh', app / 'launch.sh')
            shutil.copy2(source / 'compatibility-check.sh', app)
            (app / 'launch.sh').chmod(0o644)
            commands = ports / 'commands'
            commands.mkdir()
            uname = commands / 'uname'
            uname.write_text('#!/bin/sh\ncase "$1" in -m) echo armv7l;; *) echo test-kernel;; esac\n')
            uname.chmod(0o755)
            result = subprocess.run(['sh', str(entry)], capture_output=True,
                                    env=dict(os.environ, PATH=str(commands) + os.pathsep + os.environ['PATH']))
            self.assertEqual(result.returncode, 1, result.stderr.decode())
            self.assertIn('requires ARM64', (app / 'compatibility.txt').read_text())

    def test_32bit_device_gets_report_before_arm64_program_is_executed(self):
        with tempfile.TemporaryDirectory(prefix='AM2R SD ') as temp:
            root = Path(temp)
            shutil.copy2(Path(__file__).with_name('compatibility-check.sh'), root)
            commands = root / 'commands'
            commands.mkdir()
            uname = commands / 'uname'
            uname.write_text('#!/bin/sh\ncase "$1" in -m) echo armv7l;; *) echo test-kernel;; esac\n')
            uname.chmod(0o755)
            runtime = root / 'runtime/python/usr/bin'
            runtime.mkdir(parents=True)
            interpreter = runtime / 'python3.11'
            interpreter.write_text('#!/bin/sh\ntouch "' + str(root / 'incorrectly-executed') + '"\n')
            interpreter.chmod(0o755)
            result = subprocess.run(['sh', str(root / 'compatibility-check.sh')], capture_output=True,
                                    env=dict(os.environ, PATH=str(commands) + os.pathsep + os.environ['PATH']))
            self.assertEqual(result.returncode, 1)
            self.assertFalse((root / 'incorrectly-executed').exists())
            self.assertIn('requires ARM64', (root / 'compatibility.txt').read_text())

    def test_missing_runtime_leaves_actionable_report_on_card(self):
        with tempfile.TemporaryDirectory(prefix='AM2R SD ') as temp:
            root = Path(temp)
            shutil.copy2(Path(__file__).with_name('compatibility-check.sh'), root)
            commands = root / 'commands'
            commands.mkdir()
            uname = commands / 'uname'
            uname.write_text('#!/bin/sh\ncase "$1" in -m) echo aarch64;; *) echo test-kernel;; esac\n')
            uname.chmod(0o755)
            result = subprocess.run(['sh', str(root / 'compatibility-check.sh')], capture_output=True,
                                    env=dict(os.environ, PATH=str(commands) + os.pathsep + os.environ['PATH']))
            self.assertEqual(result.returncode, 1)
            self.assertIn('runtime cannot load', (root / 'compatibility.txt').read_text())


if __name__ == '__main__':
    unittest.main()
