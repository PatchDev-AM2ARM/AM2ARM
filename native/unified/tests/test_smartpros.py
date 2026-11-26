import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import compat_display
import nextui_controls
from trimui_device import current_device, display_size


class SmartProS(unittest.TestCase):
    def test_spruce_hardware_tag_and_wide_panel(self):
        firmware = {'/proc/cpuinfo': 'Hardware\t: sun55iw3\nRevision\t: TG5050',
                    '/proc/device-tree/model': 'sun55iw3', '/etc/os-release': ''}
        with patch('trimui_device.read', side_effect=lambda p: firmware.get(p, '')), patch.dict(os.environ, PLATFORM='SmartProS'):
            self.assertEqual(current_device(), 'smartpros')
        self.assertEqual(display_size('smartpros'), (1280, 720))
        self.assertEqual(compat_display.identify('sun55iw3p1', '', 'SmartProS', ''), 'smartpros')
        for model, cpu, frontend in [('sun55iw3', '', ''), ('sun55iw3', 'TG4040', 'SmartProS'),
                                     ('sun50iw10', 'TG5050', 'SmartPro'), ('other', '', 'SmartProS')]:
            with self.subTest(model=model, cpu=cpu), self.assertRaises(RuntimeError):
                compat_display.identify(model, cpu, frontend, '')

    def test_s_firmware_graphics_providers(self):
        folders = compat_display.library_dirs(Path('/card'), 'smartpros')
        self.assertEqual(folders[0], Path('/usr/lib'))
        self.assertIn(Path('/card/Persistent/portmaster/lib'), folders)
        self.assertIn(Path('/card/spruce/flip/lib'), folders)
        self.assertNotIn(Path('/card/.system/tg5040/lib'), folders)
        self.assertEqual(compat_display.video_drivers('smartpros', ['evdev', 'offscreen', 'KMSDRM', 'dummy']), ['KMSDRM'])

    def test_firmware_face_labels_and_matching_gamepad_only(self):
        keys = [288,304,305,307,308,310,311,314,315,316,317,318]
        with tempfile.TemporaryDirectory() as directory, patch.dict(os.environ, AM2ARM_TRIMUI_DEVICE='smartpros'):
            root = Path(directory)
            for event, name in [('event0','External Controller'), ('event4','TRIMUI Player1')]:
                pad = root/event/'device'
                (pad/'id').mkdir(parents=True)
                (pad/'name').write_text(name)
                for field in ('bustype','vendor','product','version'):
                    (pad/'id'/field).write_text('0003')
                (pad/'capabilities').mkdir()
                for field, codes in [('key',keys), ('abs',[0,1,2,3,4,5,16,17])]:
                    (pad/'capabilities'/field).write_text(format(sum(1<<code for code in codes), 'x'))
            self.assertEqual(nextui_controls.firmware_face_buttons('TRIMUI Player1', (), keys),
                             dict(a=305, b=304, x=308, y=307))
            mapping = nextui_controls.evdev_mapping('smartpros', root)
            fields = mapping.split(',')
            self.assertIn('TRIMUI Player1', fields)
            for value in ('a:b2','b:b1','x:b4','y:b3','leftstick:b10','rightstick:b11','lefttrigger:a2','righttrigger:a5'):
                self.assertIn(value, fields)
            self.assertNotIn('External Controller', mapping)
