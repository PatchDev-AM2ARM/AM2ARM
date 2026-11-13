"""Detect the existing display session without changing the firmware."""
import os
import json
from pathlib import Path
import stat
import subprocess
import time


def sway_output(environment):
    if not environment.get('SWAYSOCK'):
        return None
    result = subprocess.run(['swaymsg', '-r', '-t', 'get_outputs'], env=environment,
                            capture_output=True, text=True, check=True, timeout=3)
    outputs = [output for output in json.loads(result.stdout)
               if output.get('active') and output.get('power', output.get('dpms', True))]
    if not outputs:
        raise RuntimeError('No powered screen is available for the installer.')
    return next((output['name'] for output in outputs if output.get('focused')),
                outputs[0]['name'])


def place_sway_window(pid, output, environment):
    command = f'[pid={int(pid)}] move container to output {json.dumps(output)}, focus'
    deadline = time.monotonic() + 5
    while time.monotonic() < deadline:
        result = subprocess.run(['swaymsg', '-r', '-t', 'command', command], env=environment,
                                capture_output=True, text=True, timeout=1)
        if result.returncode == 0:
            replies = json.loads(result.stdout)
            if replies and all(reply.get('success') for reply in replies):
                return
        time.sleep(.05)
    raise RuntimeError('The installer window could not be placed on the active screen.')


def wayland_environment(environment):
    env = dict(environment)
    display = env.get('WAYLAND_DISPLAY', 'wayland-0')
    explicit = env.get('XDG_RUNTIME_DIR')
    folders = [Path(explicit)] if explicit else [Path('/run/user') / str(os.getuid()),
                                                Path('/var/run'), Path('/run')]
    for folder in folders:
        endpoint = Path(display) if Path(display).is_absolute() else folder / display
        try:
            if stat.S_ISSOCK(endpoint.stat().st_mode):
                env.update(XDG_RUNTIME_DIR=str(endpoint.parent), WAYLAND_DISPLAY=endpoint.name)
                return env
        except OSError:
            continue
    raise RuntimeError('No active Wayland display was found. This release cannot run on this '
                       'firmware display setup. It needs a different graphics backend; '
                       'copying more ROM files or enabling Wi-Fi will not fix this. '
                       'Send compatibility.txt with the handheld model and firmware version.')
