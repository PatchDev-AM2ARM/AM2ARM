"""Run the installed game with the bundled gmloader-next."""
from contextlib import ExitStack
import fcntl
import json
import os
from pathlib import Path
import resource
import signal
import subprocess
import sys
import tempfile
import time

from brick_rumble import BrickRumble
from compat_display import KMS_PANELS, library_candidates, library_dirs
from first_run import Library
from handheld_platform import sway_output
from nextui_controls import controller_mappings
from spruce_exit import SpruceMenuExit
from trimui_device import stay_awake

GMLOADER = Path(__file__).resolve().parent.parent/'gmloader'
# RG DS touch panel owner
TOUCH = Path('/sys/class/anbernic_misc/tpctrl')


def loader_config(library):
    config = json.loads((library.game/'gmloader.json').read_text())
    config.update(apk_path=str(library.port), save_dir=str(library.saves))
    return config


def link_libraries(folder, directories, chosen=()):
    """Put the chosen firmware libraries in folder, and bundled copies of what the firmware lacks."""
    for name, source in chosen:
        (folder/name).symlink_to(source)
    for library in sorted((GMLOADER/'fallback').iterdir()):
        if not (folder/library.name).is_symlink() and not library_candidates(directories, (library.name,)):
            (folder/library.name).symlink_to(library)


def game_environment(env, folder, device=None, extra=()):
    """The firmware environment with the loader's libraries first."""
    game = {key: value for key, value in env.items() if not key.startswith('PYTHON')}
    paths = [folder, GMLOADER/'lib', *(env.get('LD_LIBRARY_PATH') or '').split(':'), *extra]
    game.update(LD_LIBRARY_PATH=':'.join(dict.fromkeys(str(path) for path in paths if str(path))),
                GMLOADER_LIB_PATH=str(GMLOADER/'lib'))
    mappings = '\n'.join(filter(None, (env.get('SDL_GAMECONTROLLERCONFIG'), controller_mappings(device))))
    if mappings:
        game['SDL_GAMECONTROLLERCONFIG'] = mappings
    return game


def wayland_game(library, folder, env):
    link_libraries(folder, library_dirs(library.card, 'generic'))
    env = game_environment(env, folder)
    env.setdefault('SDL_VIDEODRIVER', 'wayland')
    return env


def direct_game(library, folder, env, device):
    from nextui_session import display_options, report
    report(device)
    candidate = next(display_options(device, env, True), None)
    if candidate is None:
        raise RuntimeError('No firmware driver could present a GLES2 frame.')
    sdl, driver, egl, gles = candidate
    print('Display:', driver, 'SDL:', sdl, 'EGL:', egl, 'GLES:', gles, flush=True)
    link_libraries(folder, library_dirs(library.card, device),
                   [('libSDL2-2.0.so.0', sdl), ('libEGL.so', egl), ('libEGL.so.1', egl),
                    ('libGLESv2.so', gles), ('libGLESv2.so.2', gles)])
    env = game_environment(env, folder, device, (sdl.parent, egl.parent, gles.parent, '/usr/trimui/lib'))
    for key in ('WAYLAND_DISPLAY', 'LD_PRELOAD'):
        env.pop(key, None)
    env.update(SDL_VIDEODRIVER=driver, SDL_VIDEO_EGL_DRIVER=str(egl), SDL_VIDEO_GL_DRIVER=str(gles))
    if (device in KMS_PANELS or device == 'flip') and driver.lower() == 'kmsdrm':
        env['EGL_PLATFORM'] = 'gbm'
    return env


def fullscreen(process, env):
    """Sway tiles new windows. The title keeps the second screen's window out."""
    output = sway_output(env)
    if output is None:
        return
    command = f'[pid={process.pid} title="^GMLoader$"] move container to output {json.dumps(output)}, fullscreen enable, focus'
    deadline = time.monotonic() + 20
    while process.poll() is None and time.monotonic() < deadline:
        result = subprocess.run(['swaymsg', '-r', '-t', 'command', command], env=env,
                                capture_output=True, text=True, timeout=3)
        if result.returncode == 0:
            replies = json.loads(result.stdout)
            if replies and all(reply.get('success') for reply in replies):
                return
        time.sleep(.1)


def firmware_vibration(folder, env, device, resources):
    """SDL can't reach the Brick and Smart Pro motor."""
    if device not in ('brick', 'smartpro'):
        return None
    try:
        rumble = resources.enter_context(BrickRumble(folder/'rumble.sock'))
    except OSError as error:
        print('TrimUI vibration unavailable:', error, flush=True)
        return None
    env.update(AM2ARM_RUMBLE_SOCKET=str(folder/'rumble.sock'), LD_PRELOAD=str(GMLOADER/'lib/librumble.so'))
    return rumble


def supervise(process, watch, rumble=None):
    while process.poll() is None:
        if watch and watch.requested():
            process.terminate()
            watch = None
        if rumble:
            rumble.poll()
        else:
            time.sleep(.25)
    return process.returncode


def run(library, backend, env):
    device = env.get('AM2ARM_DEVICE_PROFILE') if backend == 'direct' else None
    library.saves.mkdir(parents=True, exist_ok=True)
    logs = library.app/'logs'
    logs.mkdir(parents=True, exist_ok=True)
    print('AM2ARM', library.version, '| gmloader-next |', backend, device or '', flush=True)
    touch = None
    with tempfile.TemporaryDirectory(prefix='am2arm-', dir='/tmp') as temporary, ExitStack() as resources:
        folder = Path(temporary)
        config = folder/'gmloader.json'
        config.write_text(json.dumps(loader_config(library)))
        libraries = folder/'lib'
        libraries.mkdir()
        if backend == 'direct':
            env = direct_game(library, libraries, env, device)
        else:
            env = wayland_game(library, libraries, env)
        rumble = firmware_vibration(folder, env, device, resources)
        watch = None
        if device == 'smartpros' and env.get('AM2ARM_FRONTEND') == 'spruce':
            watch = SpruceMenuExit.open(library.card)
        process = None
        try:
            if TOUCH.exists():
                touch = TOUCH.read_text().strip()
                TOUCH.write_text('0\n')
            # gmloader-next reads music from assets in the working directory.
            with (logs/'game.log').open('w') as output:
                process = subprocess.Popen([str(GMLOADER/'gmloadernext.aarch64'), '-c', str(config)],
                                           cwd=library.game, env=env, stdin=subprocess.DEVNULL,
                                           stdout=output, stderr=subprocess.STDOUT)
            if backend == 'ports':
                fullscreen(process, env)
            status = supervise(process, watch, rumble)
        finally:
            if process is not None and process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=4)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
            if watch is not None:
                watch.__exit__()
            if touch in ('0', '1'):
                TOUCH.write_text(touch + '\n')
    print('Game exit status:', status, flush=True)
    if status:
        print((logs/'game.log').read_text(errors='replace')[-1100:], flush=True)
    return status


def main():
    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
    for number in (signal.SIGINT, signal.SIGTERM):
        signal.signal(number, lambda received, _: sys.exit(128 + received))
    library = Library.from_environment()
    backend = os.environ['AM2ARM_DISPLAY_PATH']
    with open('/tmp/am2arm.lock', 'a') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print('AM2ARM is already open.', flush=True)
            return 1
        try:
            with stay_awake(library.card, os.environ.get('AM2ARM_DEVICE_PROFILE') if backend == 'direct' else None):
                return run(library, backend, dict(os.environ))
        except (RuntimeError, OSError, ValueError) as error:
            print('Could not start:', error, flush=True)
            return 1


if __name__ == '__main__':
    raise SystemExit(main())
