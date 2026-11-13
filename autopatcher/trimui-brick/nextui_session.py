"""App-local NextUI startup, diagnostics and cleanup."""
from pathlib import Path
import fcntl
from contextlib import ExitStack
import hashlib
import importlib.util
import json
import os
import platform
import resource
import shutil
import signal
import struct
import subprocess
import sys
import tempfile
import time
import xml.etree.ElementTree as ET

from nextui_layout import installed_game, stock_menu
from nextui_controls import brick_mappings
from brick_rumble import BrickRumble

RUNTIME = Path(__file__).resolve().parent
ROOT = RUNTIME.parent
CARD = ROOT.parent
CHILDREN = []


def library_path(*extra):
    directories = [RUNTIME/'core', RUNTIME/'lib', *extra]
    directories += [Path(value) for value in os.environ.get('LD_LIBRARY_PATH', '').split(':') if value]
    directories += [Path('/usr/trimui/lib'), Path('/usr/lib'), Path('/lib')]
    return ':'.join(str(value) for value in dict.fromkeys(directories))


def command(binary, arguments=(), extra=(), preload=None):
    result = [str(RUNTIME/'core/ld-linux-aarch64.so.1'), '--library-path', library_path(*extra)]
    if preload:
        result += ['--preload', str(preload)]
    return result+[str(binary)]+list(map(str, arguments))


def python(script, *arguments):
    return command(RUNTIME/'python/usr/bin/python3.11', [script, *arguments])


def start(arguments, env, log, cwd=None):
    with log.open('w') as output:
        process = subprocess.Popen(arguments, env=env, cwd=cwd, stdout=output,
                                   stderr=subprocess.STDOUT, start_new_session=True)
    CHILDREN.append(process)
    return process


def cleanup():
    for process in reversed(CHILDREN):
        if process.poll() is None:
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=4)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait(timeout=2)


def wait_ready(process, predicate, description, timeout=20):
    deadline = time.monotonic()+timeout
    while not predicate():
        if process.poll() is not None:
            raise RuntimeError(description+' exited. Please send the logs folder.')
        if time.monotonic() >= deadline:
            raise RuntimeError(description+' did not become ready. Please send the logs folder.')
        time.sleep(.05)


def firmware_library(names):
    folders = [CARD/'.system/tg5040/lib', Path('/usr/trimui/lib'), Path('/usr/lib'),
               Path('/lib'), Path('/usr/lib/aarch64-linux-gnu')]
    for folder in folders:
        for name in names:
            value = folder/name
            if value.is_file():
                return value.resolve()
    raise RuntimeError('Missing firmware library: '+names[0])


def report():
    details = {'package': 'AM2ARM 1.6.1 Brick', 'frontend': 'stock' if stock_menu() else 'NextUI',
               'machine': platform.machine(),
               'kernel': platform.release(), 'firmware': {}, 'input': []}
    for label, file in [('model', Path('/proc/device-tree/model')),
                        ('os', Path('/etc/os-release')),
                        ('stock-version', Path('/etc/version')),
                        ('crossmix-version', Path('/usr/trimui/crossmix-version.txt')),
                        ('nextui-version', CARD/'.system/version.txt'),
                        ('nextui-build', CARD/'.system/tg5040/version.txt')]:
        try:
            details['firmware'][label] = file.read_text()[:4096].rstrip('\0\n')
        except OSError:
            pass
    for entry in Path('/sys/class/input').glob('event*'):
        record = {'event': entry.name}
        for field in ('name', 'capabilities/key', 'capabilities/abs', 'id/bustype',
                      'id/vendor', 'id/product', 'id/version'):
            try:
                record[field] = (entry/'device'/field).read_text().strip()
            except OSError:
                pass
        details['input'].append(record)
    (ROOT/'logs/device.json').write_text(json.dumps(details, indent=2)+'\n')


def game_options(game):
    metadata = json.loads((game/'edition.json').read_text())
    spec = importlib.util.spec_from_file_location('game_launch', game/'runtime/launch.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    native = Path.home()/'.config'/metadata['game_name']
    options = game/'state/config'/metadata['game_name'] if stock_menu() else native
    if stock_menu():
        module.bind_save_directory(native, options)
    options.mkdir(parents=True, exist_ok=True)
    config = options/'config.ini'
    if not config.exists():
        config.write_text('[Screen]\nFullscreen=0\nScale=2\nWidescreen=0\nAspectRatio=0\nNano=0\n')
    mappings = (game/'data/gamecontrollerdb.txt').read_text()+'\n'+brick_mappings()
    module.prepare_controller_database(options, mappings)
    print('Save folder:', options, flush=True)
    return options, metadata


def prepare_rumble(game):
    folder = RUNTIME/'rumble'
    manifest = folder/'library.json'
    if not manifest.is_file():
        return False
    hashes = json.loads(manifest.read_text())
    source = folder/'libAM2ARMHaptics.so'
    target = game/'data/libAM2ARMHaptics.so'
    digest = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    if digest(source) != hashes['brick']:
        raise RuntimeError('The Brick vibration library is incomplete.')
    existing = digest(target)
    if existing != hashes['brick']:
        if existing != hashes['original']:
            print('Keeping a modified vibration library.', flush=True)
            return False
        backup = game/'state/original-haptics.so'
        backup.parent.mkdir(parents=True, exist_ok=True)
        if not backup.exists():
            shutil.copy2(target, backup)
        temporary = target.with_suffix('.new')
        shutil.copy2(source, temporary)
        temporary.replace(target)
    return True


def run(mode):
    if mode not in ('patcher', 'game'):
        raise RuntimeError('Unknown launch mode.')
    report()
    stamp = time.strftime('%Y%m%d-%H%M%S')+'-'+str(os.getpid())
    logs = ROOT/'logs'
    sdl = firmware_library(('libSDL2-2.0.so.0', 'libSDL2.so', 'libSDL2-2.0.so'))
    print('Firmware SDL:', sdl, flush=True)
    with tempfile.TemporaryDirectory(prefix='am2arm-nextui-') as temporary, ExitStack() as resources:
        work = Path(temporary)
        rumble = None
        number = next((i for i in range(40, 80) if not Path(f'/tmp/.X{i}-lock').exists()
                       and not Path(f'/tmp/.X11-unix/X{i}').exists()), None)
        if number is None:
            raise RuntimeError('No private input display is available.')
        cookie = os.urandom(16)
        authority = work/'Xauthority'
        fields = [b'', str(number).encode(), b'MIT-MAGIC-COOKIE-1', cookie]
        authority.write_bytes(struct.pack('>H', 65535)+b''.join(struct.pack('>H', len(f))+f for f in fields))
        authority.chmod(0o600)
        env = dict(os.environ, DISPLAY=f':{number}', XAUTHORITY=str(authority),
                   XLOCALEDIR=str(RUNTIME/'share/X11/locale'), XMODIFIERS='@im=none',
                   AM2ARM_FIRMWARE_SDL=str(sdl))
        fonts = ET.Element('fontconfig')
        ET.SubElement(fonts, 'dir').text = str(ROOT/'patcher/assets')
        ET.SubElement(fonts, 'cachedir').text = str(work/'font-cache')
        font_config = work/'fonts.conf'
        ET.ElementTree(fonts).write(font_config, encoding='utf-8', xml_declaration=True)
        env['FONTCONFIG_FILE'] = str(font_config)
        env['FONTCONFIG_PATH'] = str(work)
        env.pop('LD_PRELOAD', None)
        env.pop('LD_LIBRARY_PATH', None)
        xserver = start(command(RUNTIME/'bin/Xvfb', [env['DISPLAY'], '-screen', '0', '1024x768x24',
            '-nolisten', 'tcp', '-auth', authority, '-xkbdir', RUNTIME/'share/X11/xkb',
            '-fp', 'built-ins', '-noreset']), env, logs/(stamp+'-display.log'), RUNTIME/'bin')
        wait_ready(xserver, lambda: Path(f'/tmp/.X11-unix/X{number}').is_socket(), 'Input display')
        if mode == 'patcher':
            env.update(TCL_LIBRARY=str(RUNTIME/'python/usr/share/tcltk/tcl8.6'),
                       TK_LIBRARY=str(RUNTIME/'python/usr/share/tcltk/tk8.6'),
                       AM2ARM_PRESENT_READY=str(work/'visible'))
            view = start(python(RUNTIME/'nextui_present.py'), env, logs/(stamp+'-presentation.log'))
            wait_ready(view, lambda: (work/'visible').is_file(), 'Installer display')
            app = start(python(RUNTIME/'nextui_gui.py'), env, logs/(stamp+'-installer.log'), ROOT/'patcher')
        else:
            game = installed_game(CARD)
            options, metadata = game_options(game)
            if prepare_rumble(game):
                mapping = brick_mappings().partition(',')[0]
                if len(mapping) == 32:
                    try:
                        rumble = resources.enter_context(BrickRumble(work/'rumble.sock'))
                        env.update(AM2ARM_RUMBLE_SOCKET=str(work/'rumble.sock'),
                                   AM2ARM_RUMBLE_GUID=mapping)
                        print('Brick vibration enabled.', flush=True)
                    except OSError as error:
                        print('Brick vibration unavailable:', error, flush=True)
            egl = firmware_library(('libEGL.so.1', 'libEGL.so'))
            gles = firmware_library(('libGLESv2.so.2', 'libGLESv2.so'))
            print('Firmware EGL:', egl, 'GLES:', gles, flush=True)
            aliases = work/'graphics'
            aliases.mkdir()
            for name, source in [('libEGL.so', egl), ('libEGL.so.1', egl),
                                 ('libGLESv2.so', gles), ('libGLESv2.so.2', gles)]:
                (aliases/name).symlink_to(source)
            env.update(CRUSTY_LIBEGL=str(egl), CRUSTY_LIBSDL=str(sdl), CRUSTY_GL4ES='1',
                       CRUSTY_WLMODE='0', CRUSTY_RESOLUTION='1024x768', CRUSTY_SHOW_CURSOR='0',
                       SDL_AUDIODRIVER='alsa', XDG_SESSION_TYPE='x11',
                       LIBGL_ES='2', LIBGL_GL='21', LIBGL_NOPSA='1', LIBGL_GLES=str(gles),
                       LIBGL_NATIVE_WAYLAND='1',
                       ALSOFT_DRIVERS='alsa', AM2ARM_SAVE_DIR=str(options), AM2ARM_BROWSE_DIR=str(CARD))
            env.pop('EGL_PLATFORM', None)
            env.pop('WAYLAND_DISPLAY', None)
            env.pop('SDL_VIDEODRIVER', None)
            app = start(command(game/'data/runner', ['-game', game/'data/game.unx'],
                extra=(RUNTIME/'graphics', aliases, game/'runtime/lib', egl.parent, gles.parent),
                preload=RUNTIME/'graphics/libcrusty.so'), env, logs/(stamp+'-game.log'), game/'data')
            start(python(game/'runtime/focus-game.py', metadata['game_label']), env,
                  logs/(stamp+'-focus.log'))
        while app.poll() is None:
            if xserver.poll() is not None or (mode == 'patcher' and view.poll() is not None):
                raise RuntimeError('The display stopped while running. Please send the logs folder.')
            if rumble:
                rumble.poll()
            else:
                time.sleep(.25)
        print('Application exit status:', app.returncode, flush=True)
        return app.returncode


def main():
    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
    def stop(*_):
        raise KeyboardInterrupt
    signal.signal(signal.SIGINT, stop)
    signal.signal(signal.SIGTERM, stop)
    with open('/tmp/am2arm-nextui.lock', 'a') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print('AM2ARM is already open.', flush=True)
            return 1
        try:
            awake = Path('/tmp/stay_awake')
            owns_awake = False
            if stock_menu():
                try:
                    with awake.open('x') as stream:
                        stream.write('1\n')
                    owns_awake = True
                except FileExistsError:
                    pass
            try:
                return run(sys.argv[1] if len(sys.argv) > 1 else 'patcher')
            finally:
                if owns_awake:
                    awake.unlink(missing_ok=True)
        except (RuntimeError, OSError, ValueError) as error:
            print('Could not start:', error, flush=True)
            return 1
        except KeyboardInterrupt:
            return 130
        finally:
            cleanup()


if __name__ == '__main__':
    raise SystemExit(main())
