"""Translate game vibration into the Brick firmware's motor controls."""
from pathlib import Path
import select
import socket
import time


class BrickRumble:
    def __init__(self, address, motor=Path('/sys/class/gpio/gpio227/value'),
                 voltage=Path('/sys/class/motor/voltage')):
        self.address = Path(address)
        self.motor, self.voltage = Path(motor), Path(voltage)
        self.original_voltage = self.voltage.read_text().strip()
        self.socket = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
        self.socket.bind(str(self.address))
        self.socket.setblocking(False)
        self.strength, self.deadline = 0, 0

    def apply(self, strength):
        if strength == self.strength:
            return
        if strength:
            self.voltage.write_text(str(500000 + strength * 2800000 // 255)+'\n')
        self.motor.write_text('1\n' if strength else '0\n')
        self.strength = strength

    def poll(self, timeout=.05, now=None):
        ready, _, _ = select.select([self.socket], [], [], timeout)
        now = time.monotonic() if now is None else now
        if ready:
            for _ in range(64):
                try:
                    packet = self.socket.recv(16)
                except BlockingIOError:
                    break
                if len(packet) == 1:
                    self.apply(packet[0])
                    self.deadline = now + .6
        if self.strength and now >= self.deadline:
            self.apply(0)

    def __enter__(self):
        return self

    def __exit__(self, *_):
        try:
            self.motor.write_text('0\n')
            self.voltage.write_text(self.original_voltage+'\n')
        finally:
            self.socket.close()
            self.address.unlink(missing_ok=True)
