"""Nonexclusive Linux gamepad input; no firmware mappings are changed."""
import os
from pathlib import Path
import struct
import time
import xml.etree.ElementTree as ET

EVENT = struct.Struct('llHHi')
RGDS = 'ANBERNIC-rk3568-keys'
RGDS_VIRTUAL = 'RG DS virtual controller'
DIRECTIONS = {544: 'up', 545: 'down', 546: 'left', 547: 'right'}


def firmware_face_buttons(name, device_ids, keys, paths=None):
    """Resolve printed face buttons from the firmware's matching ES profile."""
    if not device_ids or not device_ids[1]:
        return None
    if paths is None:
        paths = [Path.home()/'.config/emulationstation/es_input.cfg',
                 Path.home()/'.emulationstation/es_input.cfg',
                 Path('/storage/.config/emulationstation/es_input.cfg'),
                 Path('/storage/.emulationstation/es_input.cfg'),
                 Path('/etc/emulationstation/es_input.cfg'),
                 Path('/usr/config/emulationstation/es_input.cfg')]
    # SDL's Linux evdev backend numbers joystick keys first, then lower keys.
    # An ES button id is this index, not an evdev event code.
    order = sorted(k for k in keys if 288 <= k < 767)
    order += sorted(k for k in keys if 0 <= k < 288)
    for path in dict.fromkeys(paths):
        try:
            with path.open('rb') as source:
                data = source.read(2*1024*1024+1)
            if len(data) > 2*1024*1024:
                continue
            configs = ET.fromstring(data).findall('inputConfig')
        except (OSError, ET.ParseError):
            continue
        for config in configs:
            if config.get('type') != 'joystick' or config.get('deviceName') != name:
                continue
            try:
                guid = bytes.fromhex(config.get('deviceGUID', ''))
            except ValueError:
                continue
            # Compare bus, vendor, product and revision. Ignore only SDL's name
            # checksum; the exact name is checked above. HIDAPI has a different
            # button order and must not be interpreted as an evdev profile.
            if len(guid) != 16 or guid[6:8]+guid[10:12]+guid[14:16] != bytes(6):
                continue
            ids = tuple(int.from_bytes(guid[i:i+2], 'little') for i in (0, 4, 8, 12))
            if ids != tuple(device_ids):
                continue
            faces = {}
            for letter in ('a', 'b', 'x', 'y'):
                entries = [entry for entry in config.findall('input') if entry.get('name') == letter]
                if len(entries) != 1:
                    break
                entry = entries[0]
                if entry.get('type') != 'button' or entry.get('value') != '1':
                    break
                try:
                    index = int(entry.get('id', ''))
                except ValueError:
                    break
                if not 0 <= index < len(order):
                    break
                faces[letter] = order[index]
            if len(faces) == 4 and len(set(faces.values())) == 4:
                return faces
    return None


def controller_profile(name, model, device_path):
    if (model in ('Anbernic RG DS', 'Anbernic RG DS Plus')
            and name == 'Sony Interactive Entertainment DualSense Wireless Controller'
            and '/devices/virtual/misc/uhid/' in device_path):
        return RGDS_VIRTUAL
    return name


def controller_action(kind, code, value, name='', face_buttons=None):
    if kind == 1 and value == 1:
        buttons = {304: 'accept', 305: 'back', 307: 'folder', 315: 'finish',
                   310: 'previous', 311: 'next', 314: 'back', **DIRECTIONS}
        if name == RGDS:
            buttons.update({311: 'finish', 308: 'previous', 309: 'next'})
        elif name == RGDS_VIRTUAL:
            buttons.update({304: 'back', 305: 'accept'})
        if face_buttons:
            for old_code in (304, 305, 307, 308):
                buttons.pop(old_code, None)
            for letter, action in [('a', 'accept'), ('b', 'back'), ('x', 'folder'), ('y', None)]:
                buttons[face_buttons[letter]] = action
        return buttons.get(code)
    if kind == 3:
        if code == 17 and value:
            return 'down' if value > 0 else 'up'
        if code == 16 and value:
            return 'right' if value > 0 else 'left'
    return None


def capability_bits(value):
    bits = set()
    for index, word in enumerate(reversed(value.split())):
        number = int(word, 16)
        offset = index * struct.calcsize('L') * 8
        bits.update(offset + bit for bit in range(number.bit_length()) if number & (1 << bit))
    return bits


def is_gamepad(keys, axes):
    return 304 in keys and (set(DIRECTIONS) <= keys or {16, 17} <= axes)


class Pad:
    def __init__(self, fd, name, face_buttons=None):
        self.fd, self.name = fd, name
        self.face_buttons = face_buttons
        self.held = {}
        self.repeat_at = 0

    def feed(self, kind, code, value, now):
        action = controller_action(kind, code, value, self.name, self.face_buttons)
        token = kind, code
        direction = (kind == 3 and code in (16, 17)) or (kind == 1 and code in DIRECTIONS)
        if direction:
            if not value:
                self.held.pop(token, None)
                return None
            if action == self.held.get(token):
                return None
            if action:
                self.held[token] = action
                self.repeat_at = now + .4
        return action

    def repeats(self, now):
        if self.held and now >= self.repeat_at:
            self.repeat_at = now + .12
            return list(dict.fromkeys(self.held.values()))
        return []


class Controller:
    def __init__(self):
        self.pads = {}
        self.next_scan = 0
        try:
            self.model = Path('/proc/device-tree/model').read_text().rstrip('\0\n')
        except OSError:
            self.model = ''
        self.scan()

    def scan(self):
        self.next_scan = time.monotonic() + 2
        for entry in Path('/sys/class/input').glob('event*'):
            if entry.name in self.pads:
                continue
            try:
                device = entry / 'device'
                keys = capability_bits((device / 'capabilities/key').read_text())
                axes = capability_bits((device / 'capabilities/abs').read_text())
                if not is_gamepad(keys, axes):
                    continue
                name = (device / 'name').read_text().strip()
                try:
                    ids = tuple(int((device/'id'/field).read_text().strip(), 16)
                                for field in ('bustype', 'vendor', 'product', 'version'))
                except (OSError, ValueError):
                    ids = None
                faces = firmware_face_buttons(name, ids, keys)
                name = controller_profile(name, self.model, str(device.resolve()))
                fd = os.open('/dev/input/' + entry.name, os.O_RDONLY | os.O_NONBLOCK | os.O_CLOEXEC)
                self.pads[entry.name] = Pad(fd, name, faces)
                print('Controller:', name, 'face buttons:', faces or 'built-in defaults', flush=True)
            except (OSError, ValueError):
                continue

    def poll(self):
        now = time.monotonic()
        if now >= self.next_scan:
            self.scan()
        actions = []
        for device, pad in list(self.pads.items()):
            try:
                data = os.read(pad.fd, EVENT.size * 128)
                if not data:
                    raise OSError('Controller disconnected')
            except BlockingIOError:
                data = b''
            except OSError:
                os.close(pad.fd)
                del self.pads[device]
                continue
            for _, _, kind, code, value in EVENT.iter_unpack(data):
                if kind == 0 and code == 3:
                    pad.held.clear()
                    continue
                action = pad.feed(kind, code, value, now)
                if action:
                    actions.append(action)
            actions.extend(pad.repeats(now))
        return actions

    def close(self):
        for pad in self.pads.values():
            os.close(pad.fd)
        self.pads.clear()
