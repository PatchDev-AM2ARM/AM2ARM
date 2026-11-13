"""Run the handheld installer with a private, authenticated X11 display."""
import fcntl
import os
from pathlib import Path
import signal
import struct
import subprocess
import sys
import tempfile
import time

from handheld_platform import wayland_environment, sway_output, place_sway_window

ROOT = Path(__file__).resolve().parent


def main():
    if sys.argv[1:2] == ['--cli']:
        from linux_patcher import main as cli
        del sys.argv[1]
        return cli()
    with open('/tmp/am2r-linux.lock', 'a') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise RuntimeError('Close AM2ARM or the previous AM2R game before starting the installer.')
        return run()


def run():
    env = wayland_environment(os.environ)
    output = sway_output(env)
    env['AM2R_PATCHER_FULLSCREEN'] = '1'
    runtime = ROOT / 'runtime'
    bundled = ['/lib/ld-linux-aarch64.so.1', '--library-path', str(runtime / 'lib')]
    children = []
    touch = Path('/sys/class/anbernic_misc/tpctrl')
    previous_touch = None
    with tempfile.TemporaryDirectory(prefix='am2r-display-') as temporary:
        try:
            number = next(n for n in range(72, 100)
                          if not Path(f'/tmp/.X11-unix/X{n}').exists()
                          and not Path(f'/tmp/.X{n}-lock').exists())
            authority = Path(temporary) / 'authority'
            fields = [b'', str(number).encode(), b'MIT-MAGIC-COOKIE-1', os.urandom(16)]
            authority.write_bytes(struct.pack('>H', 65535) +
                                  b''.join(struct.pack('>H', len(part)) + part for part in fields))
            authority.chmod(0o600)
            env.update(XAUTHORITY=str(authority), DISPLAY=f':{number}')
            with (ROOT / 'state/display.log').open('w') as log:
                display = subprocess.Popen([*bundled, str(runtime / 'bin/Xwayland'), env['DISPLAY'],
                    '-shm', '-nolisten', 'tcp', '-auth', str(authority),
                    '-xkbdir', str(runtime / 'share/X11/xkb'), '-noreset'],
                    cwd=runtime / 'bin', env=env, stdin=subprocess.DEVNULL,
                    stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
            children.append(display)
            for _ in range(100):
                if display.poll() is not None:
                    raise RuntimeError('Display closed during startup. See state/display.log.')
                if Path(f'/tmp/.X11-unix/X{number}').exists():
                    break
                time.sleep(.1)
            else:
                raise RuntimeError('Display did not become ready. See state/display.log.')
            if touch.exists():
                previous_touch = touch.read_text().strip()
                if previous_touch not in ('0', '1'):
                    previous_touch = None
                    raise RuntimeError('Unrecognized firmware touchscreen setting.')
                touch.write_text('0\n')
            gui = subprocess.Popen([*bundled, str(runtime / 'python/usr/bin/python3.11'),
                                    str(ROOT / 'handheld_gui.py'), *sys.argv[1:]],
                                   cwd=ROOT, env=env, stdin=subprocess.DEVNULL, start_new_session=True)
            children.append(gui)
            if output is not None:
                place_sway_window(display.pid, output, env)
            print('Installer started on', env['DISPLAY'], flush=True)
            result = gui.wait()
            print('Installer exited with status', result, flush=True)
            return result
        finally:
            for child in reversed(children):
                if child.poll() is None:
                    try:
                        os.killpg(child.pid, signal.SIGTERM)
                        child.wait(timeout=3)
                    except subprocess.TimeoutExpired:
                        os.killpg(child.pid, signal.SIGKILL)
                        child.wait()
                    except ProcessLookupError:
                        pass
            if previous_touch is not None:
                touch.write_text(previous_touch + '\n')


if __name__ == '__main__':
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(143))
    signal.signal(signal.SIGINT, lambda *_: sys.exit(130))
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print('Could not open the installer: ' + str(error), file=sys.stderr)
        with (ROOT / 'compatibility.txt').open('a') as report:
            report.write('\nInstaller startup failed:\n' + str(error) + '\n')
        raise SystemExit(1)
