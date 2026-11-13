import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import nextui_layout as layout
import nextui_session as session
from nextui_controls import firmware_face_buttons
import nextui_controls as controls


class NextUITests(unittest.TestCase):
    def test_bundled_runtime_precedes_firmware_graphics_dependencies(self):
        paths = session.library_path(Path('/usr/lib'), Path('/usr/trimui/lib')).split(':')
        self.assertLess(paths.index(str(session.RUNTIME/'lib')), paths.index('/usr/lib'))
        self.assertEqual(paths.count('/usr/lib'), 1)

    def test_brick_printed_buttons_follow_firmware_order(self):
        keys = {304, 305, 307, 308, 310, 311, 314, 315}
        self.assertEqual(firmware_face_buttons('TRIMUI Controller', (3, 1, 1, 1), keys),
                         dict(a=305, b=304, x=308, y=307))
        self.assertIsNone(firmware_face_buttons('External gamepad', (3, 1, 1, 1), keys))

    def test_game_face_buttons_match_the_bricks_printed_letters(self):
        with tempfile.TemporaryDirectory() as directory:
            events = []
            for number, name in enumerate(('TRIMUI Player1', 'External gamepad')):
                entry = Path(directory)/('event'+str(number))
                device = entry/'device'
                (device/'id').mkdir(parents=True)
                (device/'name').write_text(name)
                for field, value in zip(('bustype', 'vendor', 'product', 'version'),
                                        ('0003', '045e', '028e', '0114')):
                    (device/'id'/field).write_text(value)
                events.append(entry)
            with patch.object(controls.Path, 'glob', return_value=events):
                mappings = controls.brick_mappings().splitlines()
        self.assertEqual(len(mappings), 1)
        guid, name, *bindings = mappings[0].split(',')
        self.assertEqual(guid, '030000005e0400008e02000014010000')
        buttons = dict(field.split(':', 1) for field in bindings if ':' in field)
        physical_keys = {304: 'b0', 305: 'b1', 307: 'b2', 308: 'b3'}
        for key, letter in ((305, 'a'), (304, 'b'), (308, 'x'), (307, 'y')):
            with self.subTest(printed=letter):
                self.assertEqual(buttons[letter], physical_keys[key])
        self.assertEqual({key: buttons[key] for key in ('back', 'start', 'leftshoulder',
                         'rightshoulder', 'lefttrigger', 'righttrigger', 'dpup', 'dpdown')},
                         {'back': 'b6', 'start': 'b7', 'leftshoulder': 'b4',
                          'rightshoulder': 'b5', 'lefttrigger': 'a2',
                          'righttrigger': 'a5', 'dpup': 'h0.1', 'dpdown': 'h0.4'})

    def test_launcher_uses_card_root_and_quoted_paths(self):
        text = layout.launcher('game')
        self.assertIn('AM2ARM/runtime/start.sh', text)
        self.assertIn('"$am2arm_card', text)
        self.assertNotIn('killall', text)
        self.assertNotIn('/storage/roms', text)

    def test_existing_unrelated_tool_is_preserved(self):
        with tempfile.TemporaryDirectory() as directory:
            card = Path(directory)
            target = card/'Tools/tg5040/AM2ARM Standard.pak/launch.sh'
            target.parent.mkdir(parents=True)
            target.write_text('unrelated existing tool\n')
            with self.assertRaises(RuntimeError):
                layout.check_play_entry(card)
            self.assertEqual(target.read_text(), 'unrelated existing tool\n')

    def test_play_entry_is_repeatable_and_survives_card_relocation(self):
        with tempfile.TemporaryDirectory(prefix='card with spaces ') as directory:
            card = Path(directory)
            game = card/'AM2ARM/games/AM2ARM Standard'
            game.mkdir(parents=True)
            layout.write_play_entry(card, game)
            layout.write_play_entry(card, game)
            self.assertEqual(layout.installed_game(card), game)
            self.assertNotIn(directory, (card/'AM2ARM/state/installation.json').read_text())

    def test_destination_outside_card_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(RuntimeError):
                layout.write_play_entry(Path(directory), Path('/tmp/other-game'))

    def test_modified_installation_cannot_escape_card(self):
        with tempfile.TemporaryDirectory() as directory:
            card = Path(directory)
            (card/'AM2ARM/state').mkdir(parents=True)
            (card/'AM2ARM/state/installation.json').write_text('{"game":"../../other"}')
            with self.assertRaises(RuntimeError):
                layout.installed_game(card)


if __name__ == '__main__':
    unittest.main()
