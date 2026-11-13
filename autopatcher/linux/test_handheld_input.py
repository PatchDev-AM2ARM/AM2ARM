import unittest
from pathlib import Path
import tempfile

import handheld_input
from handheld_input import controller_action, capability_bits, is_gamepad, Pad, RGDS


class ControllerMappingTests(unittest.TestCase):
    def test_rgds_virtual_pad_uses_printed_a_to_confirm(self):
        from handheld_input import controller_profile
        name = controller_profile('Sony Interactive Entertainment DualSense Wireless Controller',
                                  'Anbernic RG DS', '/sys/devices/virtual/misc/uhid/device/input/input14')
        self.assertEqual(controller_action(1, 305, 1, name), 'accept')
        self.assertEqual(controller_action(1, 304, 1, name), 'back')

    def test_external_and_other_device_pads_keep_existing_mapping(self):
        from handheld_input import controller_profile
        for model, path in [('Anbernic RG DS', '/sys/devices/platform/usb/input/input14'),
                            ('Another handheld', '/sys/devices/virtual/misc/uhid/device/input/input14')]:
            name = controller_profile('Sony Interactive Entertainment DualSense Wireless Controller', model, path)
            self.assertEqual(controller_action(1, 304, 1, name), 'accept')
            self.assertEqual(controller_action(1, 305, 1, name), 'back')

    def test_standard_start_confirms_without_rgds_button_table(self):
        self.assertEqual(controller_action(1, 315, 1), 'finish')

    def test_standard_shoulders_change_picker_page(self):
        self.assertEqual(controller_action(1, 310, 1), 'previous')
        self.assertEqual(controller_action(1, 311, 1), 'next')

    def test_digital_dpad_navigates_without_hat_axes(self):
        for code, action in [(544, 'up'), (545, 'down'), (546, 'left'), (547, 'right')]:
            self.assertEqual(controller_action(1, code, 1), action)

    def test_button_release_does_not_activate_a_second_item(self):
        self.assertIsNone(controller_action(1, 304, 0))
        self.assertIsNone(controller_action(1, 304, 2))

    def test_rgds_custom_mapping_remains_isolated(self):
        self.assertEqual(controller_action(1, 311, 1, RGDS), 'finish')
        self.assertEqual(controller_action(1, 308, 1, RGDS), 'previous')
        self.assertEqual(controller_action(1, 311, 1, 'USB gamepad'), 'next')

    def test_capabilities_distinguish_gamepad_from_keyboard_and_touch(self):
        keys = capability_bits('1000000000000 0 0 0 0')
        self.assertEqual(keys, {304})
        self.assertTrue(is_gamepad(keys, {16, 17}))
        self.assertTrue(is_gamepad({304, 544, 545, 546, 547}, set()))
        self.assertFalse(is_gamepad({1, 28, 103, 108}, set()))
        self.assertFalse(is_gamepad({330}, {0, 1}))

    def test_direction_hold_repeats_and_release_stops_it(self):
        pad = Pad(-1, 'USB gamepad')
        self.assertEqual(pad.feed(3, 17, 1, 0), 'down')
        self.assertIsNone(pad.feed(3, 17, 1, .1))
        self.assertEqual(pad.repeats(.3), [])
        self.assertEqual(pad.repeats(.5), ['down'])
        pad.feed(3, 17, 0, .55)
        self.assertEqual(pad.repeats(1), [])

    def test_confirmation_never_repeats_while_held(self):
        pad = Pad(-1, 'USB gamepad')
        self.assertEqual(pad.feed(1, 304, 1, 0), 'accept')
        self.assertEqual(pad.repeats(1), [])


class FirmwareMappingTests(unittest.TestCase):
    # G350 ROCKNIX 20261101: recorded evdev capabilities and ES mapping.
    keys = {304, 305, 307, 308, 310, 311, 312, 313, 314, 315, 316,
            317, 318, 544, 545, 546, 547}
    ids = (0x19, 0x484b, 0x1101, 0x0100)
    config = '''<inputList><inputConfig type="joystick"
        deviceName="retrogame_joypad" deviceGUID="19009b4d4b4800000111000000010000">
        <input name="a" type="button" id="1" value="1" />
        <input name="b" type="button" id="0" value="1" />
        <input name="x" type="button" id="2" value="1" />
        <input name="y" type="button" id="3" value="1" />
        </inputConfig></inputList>'''

    def resolve(self, texts=None, name='retrogame_joypad', ids=None, keys=None):
        with tempfile.TemporaryDirectory() as folder:
            paths = []
            for i, text in enumerate(texts if texts is not None else [self.config]):
                path = Path(folder) / f'input-{i}.cfg'
                path.write_text(text)
                paths.append(path)
            return handheld_input.firmware_face_buttons(
                name, self.ids if ids is None else ids,
                self.keys if keys is None else keys, paths)

    def test_g350_firmware_buttons_drive_correct_installer_actions(self):
        self.assertTrue(callable(getattr(handheld_input, 'firmware_face_buttons', None)),
                        'Installer must resolve the firmware controller mapping')
        pad = Pad(-1, 'retrogame_joypad', self.resolve())
        self.assertEqual(pad.feed(1, 305, 1, 0), 'accept')
        self.assertEqual(pad.feed(1, 304, 1, .1), 'back')
        self.assertEqual(pad.feed(1, 307, 1, .2), 'folder')
        self.assertIsNone(pad.feed(1, 308, 1, .3))
        self.assertEqual(pad.feed(1, 315, 1, .4), 'finish')
        self.assertEqual(pad.feed(1, 544, 1, .5), 'up')
        self.assertIsNone(pad.feed(1, 305, 0, .6))

    def test_same_name_on_different_hardware_does_not_inherit_mapping(self):
        for ids in [(3, 0x484b, 0x1101, 0x100), (0x19, 0x484b, 0x1102, 0x100),
                    (0x19, 0x484b, 0x1101, 0x101), (0x19, 0, 0, 0)]:
            with self.subTest(ids=ids):
                self.assertIsNone(self.resolve(ids=ids))
        self.assertIsNone(self.resolve(name='External gamepad'))

    def test_sdl_name_checksum_does_not_change_the_hardware_identity(self):
        for crc in ['0000', '9b4d']:
            mapping = self.resolve([self.config.replace('19009b4d', '1900'+crc)])
            self.assertEqual(mapping, {'a': 305, 'b': 304, 'x': 307, 'y': 308})

    def test_hidapi_indices_are_not_treated_as_evdev_indices(self):
        self.assertIsNone(self.resolve([self.config.replace(
            '19009b4d4b4800000111000000010000', '19009b4d4b4800000111000000016800')]))

    def test_button_indices_follow_sdl_order_instead_of_being_event_codes(self):
        # An extra low keyboard key sorts after gamepad buttons, not before them.
        mapping = self.resolve(keys=self.keys | {28})
        self.assertEqual(mapping['a'], 305)
        # A joystick button at 0x120 sorts before the face buttons.
        shifted = self.config.replace('id="3"', 'id="4"').replace('id="2"', 'id="3"')
        shifted = shifted.replace('id="1"', 'id="2"').replace('id="0"', 'id="1"')
        self.assertEqual(self.resolve([shifted], keys=self.keys | {288}),
                         {'a': 305, 'b': 304, 'x': 307, 'y': 308})

    def test_user_firmware_configuration_takes_precedence(self):
        custom = self.config.replace('id="1"', 'id="8"').replace('id="0"', 'id="9"')
        self.assertEqual(self.resolve([custom, self.config]),
                         {'a': 314, 'b': 315, 'x': 307, 'y': 308})

    def test_invalid_incomplete_or_duplicate_buttons_are_not_applied(self):
        for bad in [self.config.replace('id="1"', 'id="-1"'),
                    self.config.replace('id="1"', 'id="1000"'),
                    self.config.replace('id="1"', 'id="oops"'),
                    self.config.replace('id="1"', 'id="0"'),
                    self.config.replace('name="y"', 'name="ignored"'),
                    self.config.replace('type="button"', 'type="axis"', 1),
                    self.config.replace('value="1"', 'value="0"', 1),
                    '<inputList><broken']:
            with self.subTest(config=bad):
                self.assertIsNone(self.resolve([bad]))

    def test_unreadable_config_uses_existing_fallback(self):
        with tempfile.TemporaryDirectory() as folder:
            mapping = handheld_input.firmware_face_buttons('retrogame_joypad', self.ids,
                                                          self.keys, [Path(folder)/'missing'])
        pad = Pad(-1, RGDS, mapping)
        self.assertEqual(pad.feed(1, 304, 1, 0), 'accept')
        self.assertEqual(pad.feed(1, 311, 1, .1), 'finish')

    def test_unused_face_button_cannot_keep_old_folder_shortcut(self):
        pad = Pad(-1, 'retrogame_joypad', {'a': 305, 'b': 304, 'x': 308, 'y': 307})
        self.assertEqual(pad.feed(1, 308, 1, 0), 'folder')
        self.assertIsNone(pad.feed(1, 307, 1, .1))


if __name__ == '__main__':
    unittest.main()
