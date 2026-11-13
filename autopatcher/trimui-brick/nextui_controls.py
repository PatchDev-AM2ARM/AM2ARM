"""Use NextUI's printed Brick buttons without changing system mappings."""
from pathlib import Path
import struct


def button_order(keys):
    return sorted(k for k in keys if 288 <= k < 767) + sorted(k for k in keys if 0 <= k < 288)


def firmware_face_buttons(name, device_ids, keys, paths=None):
    if 'trimui' not in name.lower():
        return None
    order = button_order(keys)
    if len(order) < 4:
        return None
    return dict(a=order[1], b=order[0], x=order[3], y=order[2])


def brick_mappings():
    rows = []
    for entry in Path('/sys/class/input').glob('event*'):
        device = entry/'device'
        try:
            name = (device/'name').read_text().strip()
            if 'trimui' not in name.lower():
                continue
            ids = [int((device/'id'/part).read_text(), 16)
                   for part in ('bustype', 'vendor', 'product', 'version')]
            guid = struct.pack('<IIII', *ids).hex()
            # Match the Brick's printed letters to the game's named buttons,
            # just as the installer does, without changing saved bindings.
            rows.append(guid+',TrimUI Brick,'
                'a:b1,b:b0,x:b3,y:b2,back:b6,start:b7,guide:b8,'
                'leftshoulder:b4,rightshoulder:b5,leftstick:b9,rightstick:b10,'
                'leftx:a0,lefty:a1,rightx:a3,righty:a4,lefttrigger:a2,righttrigger:a5,'
                'dpup:h0.1,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,platform:Linux,')
        except (OSError, ValueError):
            continue
    return '\n'.join(dict.fromkeys(rows))
