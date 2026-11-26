"""Start and supervise the installer on direct-display firmware."""
from pathlib import Path
import fcntl
import json
import os
import platform
import resource
import signal
import struct
import subprocess
import sys
import tempfile
import time
import xml.etree.ElementTree as ET

from compat_display import (AMBERELEC_PANELS, EGL_NAMES, GLES_NAMES, KMS_PANELS, SDL_NAMES,
                            library_candidates, library_dirs, read, video_drivers)
from trimui_device import current_device, display_size, stay_awake

RUNTIME = Path(__file__).resolve().parent
ROOT = RUNTIME.parent
CARD = Path(os.environ.get('AM2ARM_GAME_CARD') or ROOT.parent)
CHILDREN = []


def command(binary, arguments=(), extra=()):
    core = RUNTIME/'core'
    # AmberELEC's SDL requires its glibc, and its libcurl requires its OpenSSL.
    firmware_abi = os.environ.get('AM2ARM_DEVICE_PROFILE') in AMBERELEC_PANELS
    loader = (Path('/usr/lib') if firmware_abi else core)/'ld-linux-aarch64.so.1'
    providers = list(map(Path, extra))
    bundled = RUNTIME/'lib'
    directories = providers + [bundled] if firmware_abi else [core, bundled, *providers]
    directories.extend(Path(value) for value in os.environ.get('LD_LIBRARY_PATH', '').split(':')
                       if value and (not firmware_abi or Path(value) != core))
    directories.extend([Path('/usr/trimui/lib'), Path('/usr/lib'), Path('/lib')])
    path = ':'.join(map(str, dict.fromkeys(directories)))
    return [str(loader), '--library-path', path, str(binary), *map(str, arguments)]


def python(script, *arguments, extra=()):
    return command(RUNTIME/'python/usr/bin/python3.11', [script, *arguments], extra=extra)


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


def check(env, *args):
    try:
        providers = [Path(args[1]).parent]
        providers.extend(Path(env[k]).parent for k in ('SDL_VIDEO_GL_DRIVER', 'SDL_VIDEO_EGL_DRIVER') if k in env)
        result = subprocess.run(python(RUNTIME/'sdl_check.py', *args, extra=providers), env=env,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                text=True, errors='replace', timeout=8)
    except subprocess.TimeoutExpired:
        print('Video check timed out:', *args, flush=True)
        return ''
    print(result.stdout.strip(), flush=True)
    return result.stdout if result.returncode == 0 else ''


def display_options(device, env, needs_gles):
    folders = library_dirs(CARD, device)
    if device == 'flip' and 'my355' in read('/etc/os-release').lower():
        folders = list(dict.fromkeys([Path('/usr/lib'), *folders]))
    sdls = library_candidates(folders, SDL_NAMES)
    if not sdls:
        raise RuntimeError('Could not locate a 64-bit firmware SDL2 library.')
    egls = library_candidates(folders, EGL_NAMES)
    gles = library_candidates(folders, GLES_NAMES)
    for sdl in sdls:
        lines = check(env, 'drivers', sdl).splitlines()
        names = next((json.loads(l[8:]) for l in lines if l.startswith('DRIVERS ')), [])
        for driver in video_drivers(device, names):
            if not needs_gles:
                yield sdl, driver, None, None
                continue
            for egl in egls:
                for gl in sorted(gles, key=lambda p: p.parent != egl.parent):
                    trial = dict(env, SDL_VIDEO_EGL_DRIVER=str(egl), SDL_VIDEO_GL_DRIVER=str(gl))
                    if (device in KMS_PANELS or device == 'flip') and driver.lower() == 'kmsdrm':
                        trial['EGL_PLATFORM'] = 'gbm'
                    print('Testing GLES:', driver, sdl, egl, gl, flush=True)
                    if check(trial, 'gles', sdl, driver, *display_size(device)):
                        yield sdl, driver, egl, gl
                        return
    if needs_gles and (not egls or not gles):
        raise RuntimeError('Could not locate both ARM64 firmware EGL and GLESv2 libraries.')


def report(device):
    details = {'menu': os.environ.get('AM2ARM_MENU_NAME'),
               'spruce': (CARD/'spruce').is_dir(),
               'device': device, 'display': display_size(device),
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


def run(device):
    width, height = display_size(device)
    report(device)
    print('Hardware profile:', device, 'Screen:', f'{width}x{height}', flush=True)
    stamp = time.strftime('%Y%m%d-%H%M%S')+'-'+str(os.getpid())
    logs = ROOT/'logs'
    with tempfile.TemporaryDirectory(prefix='am2arm-nextui-', dir='/tmp') as temporary:
        work = Path(temporary)
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
                   AM2ARM_TRIMUI_DEVICE=device)
        fonts = ET.Element('fontconfig')
        ET.SubElement(fonts, 'dir').text = str(ROOT/'patcher/assets')
        ET.SubElement(fonts, 'cachedir').text = str(work/'font-cache')
        font_config = work/'fonts.conf'
        ET.ElementTree(fonts).write(font_config, encoding='utf-8', xml_declaration=True)
        env['FONTCONFIG_FILE'] = str(font_config)
        env['FONTCONFIG_PATH'] = str(work)
        env.pop('LD_PRELOAD', None)
        env.pop('LD_LIBRARY_PATH', None)
        for key in ('WAYLAND_DISPLAY', 'SDL_VIDEODRIVER', 'SDL_RENDER_DRIVER', 'AM2ARM_PRESENT_DRIVER',
                    'AM2ARM_PRESENT_DISPLAY', 'SDL_VIDEO_EGL_DRIVER', 'SDL_VIDEO_GL_DRIVER', 'EGL_PLATFORM'):
            env.pop(key, None)
        candidates = display_options(device, env, False)
        xserver = start(command(RUNTIME/'bin/Xvfb', [env['DISPLAY'], '-screen', '0', f'{width}x{height}x24',
            '-nolisten', 'tcp', '-auth', authority, '-xkbdir', RUNTIME/'share/X11/xkb',
            '-fp', 'built-ins', '-noreset']), env, logs/(stamp+'-display.log'), RUNTIME/'bin')
        wait_ready(xserver, lambda: Path(f'/tmp/.X11-unix/X{number}').is_socket(), 'Input display')
        env.update(TCL_LIBRARY=str(RUNTIME/'python/usr/share/tcltk/tcl8.6'),
                   TK_LIBRARY=str(RUNTIME/'python/usr/share/tcltk/tk8.6'),
                   AM2ARM_PRESENT_READY=str(work/'visible'))
        for index, (sdl, driver, _, _) in enumerate(candidates):
            env.update(AM2ARM_FIRMWARE_SDL=str(sdl), AM2ARM_PRESENT_DRIVER=driver)
            if device in KMS_PANELS:
                env['EGL_PLATFORM'] = 'gbm'
            logfile = logs/(stamp+f'-presentation-{index}.log')
            view = start(python(RUNTIME/'nextui_present.py', extra=library_dirs(CARD, device)), env, logfile)
            try:
                wait_ready(view, lambda: (work/'visible').is_file(), 'Installer display', timeout=8)
                print('Installer frame submitted:', driver, sdl, flush=True)
                break
            except RuntimeError:
                if view.poll() is None:
                    view.kill()
                    view.wait(timeout=3)
                print('Presentation failed:', driver, logfile.read_text(errors='replace')[-450:], flush=True)
                (work/'visible').unlink(missing_ok=True)
        else:
            raise RuntimeError('No firmware SDL driver could present the installer.')
        app = start(python(RUNTIME/'nextui_gui.py'), env, logs/(stamp+'-installer.log'), ROOT/'patcher')
        while app.poll() is None:
            if xserver.poll() is not None or view.poll() is not None:
                raise RuntimeError('The display stopped while running. Please send the logs folder.')
            time.sleep(.25)
        print('Application exit status:', app.returncode, flush=True)
        if app.returncode:
            print((logs/(stamp+'-installer.log')).read_text(errors='replace')[-1100:], flush=True)
        return app.returncode


def main():
    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
    def stop(*_):
        raise KeyboardInterrupt
    signal.signal(signal.SIGINT, stop)
    signal.signal(signal.SIGTERM, stop)
    with open('/tmp/am2arm.lock', 'a') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print('AM2ARM is already open.', flush=True)
            return 1
        try:
            device = os.environ.get('AM2ARM_DEVICE_PROFILE') or current_device()
            with stay_awake(CARD, device):
                return run(device)
        except (RuntimeError, OSError, ValueError) as error:
            print('Could not start:', error, flush=True)
            return 1
        except KeyboardInterrupt:
            return 130
        finally:
            cleanup()


if __name__ == '__main__':
    raise SystemExit(main())
