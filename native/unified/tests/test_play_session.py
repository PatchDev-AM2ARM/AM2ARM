import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

from first_run import __file__ as first_run
import patch_core
from test_install import release_at

SOURCE = Path(__file__).resolve().parents[1]
INSTALL = '''echo setup >> "$TRACE"
python3 - <<'END'
import hashlib, json, os
from first_run import Library
library = Library.from_environment()
library.data.mkdir(parents=True, exist_ok=True)
library.port.write_bytes(b'game')
library.receipt.write_text(json.dumps({'release': library.release(), 'stamp': library.stamp(),
                                       'sha256': hashlib.sha256(b'game').hexdigest()}))
END'''


class Session(unittest.TestCase):
    """Run the shipped shell logic with only the firmware and display processes substituted."""

    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.card = Path(temp.name)/'Two Screen'
        self.ports = self.card/'menu'
        self.app = self.card/'am2arm-launcher/AM2ARM'
        self.rt = self.app/'runtime'
        (self.rt/'core').mkdir(parents=True)
        (self.app/'patcher').mkdir()
        shutil.copy(patch_core.__file__, self.app/'patcher')
        for filename in ('first_run.py', 'start.sh', 'session.sh'):
            shutil.copy(Path(first_run).parent/filename, self.rt)
        shutil.copy(SOURCE/'launch.sh', self.app)
        release_at(self.app/'game/am2arm.zip')
        self.bin = self.card/'bin'
        self.bin.mkdir()
        self.program(self.bin/'uname', 'echo aarch64')
        self.program(self.rt/'core/ld-linux-aarch64.so.1', 'shift 3\nunset PYTHONHOME\nexec python3 -B "$@"')
        self.simulate_backend('ports')
        (self.rt/'play.py').write_text('import os\nprint("play", os.environ["AM2ARM_DISPLAY_PATH"],'
                                       ' file=open(os.environ["TRACE"], "a"))\n'
                                       'raise SystemExit(int(os.environ.get("GAME_STATUS", "0")))\n')
        self.trace = self.card/'actions'
        self.env = dict(os.environ, PATH=str(self.bin)+':'+os.environ['PATH'], TRACE=str(self.trace),
                        AM2ARM_GAME_CARD=str(self.card), AM2ARM_FRONTEND='ports', AM2ARM_PORTS_DIR=str(self.ports))
        self.setup = self.app/'patcher/launch.sh'
        self.program(self.setup, INSTALL)

    def simulate_backend(self, backend):
        (self.rt/'route.py').write_text(
            'import os, sys\n'
            f'os.environ["AM2ARM_DISPLAY_PATH"] = {backend!r}\n'
            'os.execv(sys.argv[2], sys.argv[2:])\n')

    def program(self, path, commands):
        path.write_text('#!/bin/sh\n'+commands+'\n')
        path.chmod(0o755)

    def launch(self):
        return subprocess.run(['sh', self.app/'launch.sh', 'auto'], env=self.env, capture_output=True, text=True)

    def actions(self):
        return self.trace.read_text().splitlines()

    def test_first_launch_installs_once_and_the_next_one_plays(self):
        self.assertEqual(self.launch().returncode, 0)
        self.assertEqual(self.launch().returncode, 0)
        self.assertEqual(self.actions(), ['setup', 'play ports', 'play ports'])

    def test_updated_launcher_installs_again(self):
        self.launch()
        release_at(self.app/'game/am2arm.zip', version='1.6.5')
        self.assertEqual(self.launch().returncode, 0)
        self.assertEqual(self.actions(), ['setup', 'play ports', 'setup', 'play ports'])

    def test_closing_the_installer_does_not_start_a_game(self):
        self.program(self.setup, 'echo setup >> "$TRACE"\nexit 2')
        self.assertEqual(self.launch().returncode, 2)
        self.assertEqual(self.actions(), ['setup'])

    def test_installer_that_installs_nothing_does_not_start_a_game(self):
        self.program(self.setup, 'echo setup >> "$TRACE"')
        self.assertEqual(self.launch().returncode, 1)
        self.assertEqual(self.actions(), ['setup'])
        self.assertIn('not installed', (self.app/'logs/compatibility.txt').read_text())

    def test_direct_displays_use_their_own_installer(self):
        self.simulate_backend('direct')
        self.program(self.setup, 'exit 9')
        (self.rt/'nextui_session.py').write_text(
            'import os, subprocess\nsubprocess.run(["sh", os.environ["INSTALL"]], check=True)\n')
        self.program(self.bin/'install', INSTALL)
        self.env['INSTALL'] = str(self.bin/'install')
        self.assertEqual(self.launch().returncode, 0)
        self.assertEqual(self.actions(), ['setup', 'play direct'])

    def test_games_exit_status_reaches_the_menu(self):
        self.env['GAME_STATUS'] = '42'
        self.assertEqual(self.launch().returncode, 42)

    def test_real_router_passes_the_same_endpoint_to_setup_and_play(self):
        from test_standalone_routes import WaylandServer
        for name in ('route.py', 'compat_display.py', 'trimui_device.py'):
            shutil.copy(SOURCE/'runtime'/name, self.rt/name)
        import handheld_platform
        shutil.copy(handheld_platform.__file__, self.app/'patcher')
        display_dir = self.card/'display sockets'
        display_dir.mkdir()
        self.env.update(XDG_RUNTIME_DIR=str(display_dir))
        self.env.pop('WAYLAND_DISPLAY', None)
        self.program(self.setup, 'echo "setup $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" >> "$TRACE"\n' + INSTALL)
        (self.rt/'play.py').write_text('import os\nprint("game", os.environ["XDG_RUNTIME_DIR"] + "/" + os.environ["WAYLAND_DISPLAY"],'
                                       ' file=open(os.environ["TRACE"], "a"))\n')
        endpoint = display_dir/'wayland-3'
        with WaylandServer(endpoint):
            result = self.launch()
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.actions(), [f'setup {endpoint}', 'setup', f'game {endpoint}'])


if __name__ == '__main__':
    unittest.main()
