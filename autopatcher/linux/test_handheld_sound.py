from pathlib import Path
import unittest
from unittest.mock import patch

from handheld_sound import MenuSound


class MenuSoundTests(unittest.TestCase):
    def test_alsa_is_used_when_pulse_program_exists_without_its_server(self):
        with patch.dict('os.environ', {}, clear=True), \
             patch('handheld_sound.shutil.which', side_effect=lambda name: '/usr/bin/' + name), \
             patch.object(Path, 'exists', return_value=False):
            sound = MenuSound(Path('menu_move.wav'))
            self.assertEqual(sound.player, '/usr/bin/aplay')


if __name__ == '__main__':
    unittest.main()
