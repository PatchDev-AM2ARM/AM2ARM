"""Short original menu cues, without blocking the interface or queuing sounds."""
import os
from pathlib import Path
import shutil
import subprocess
import time


class MenuSound:
    def __init__(self, filename):
        self.filename = str(filename)
        pulse_socket = Path(os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}')) / 'pulse/native'
        pulse = shutil.which('paplay') if os.environ.get('PULSE_SERVER') or pulse_socket.exists() else None
        self.player = None if os.environ.get('AM2R_PATCHER_SILENT') == '1' else (pulse or shutil.which('aplay'))
        self.children = []
        self.last_play = 0

    def play(self):
        self.children = [child for child in self.children if child.poll() is None]
        now = time.monotonic()
        if not self.player or self.children or now-self.last_play < .045:
            return
        self.last_play = now
        try:
            # Keep the original mono cue; ALSA adapts it to fixed-format outputs.
            flags = ['-q', '-D', 'plug:default'] if self.player.endswith('/aplay') else []
            self.children.append(subprocess.Popen([self.player, *flags, self.filename],
                stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL))
        except OSError:
            self.player = None

    def close(self):
        for child in self.children:
            if child.poll() is None:
                child.terminate()
                try:
                    child.wait(timeout=.5)
                except subprocess.TimeoutExpired:
                    child.kill()
                    child.wait()
        self.children.clear()
