import json
import os
from pathlib import Path
import tempfile
import unittest
import shutil
from unittest.mock import patch

import nextui_layout as layout
import nextui_session as session


class StockMenuTests(unittest.TestCase):
    def test_stock_save_path_preserves_existing_files_and_user_settings(self):
        filename = os.environ.get('AM2ARM_LINUX_LAUNCHER')
        if not filename:
            self.skipTest('Set AM2ARM_LINUX_LAUNCHER for the optional save integration check.')
        launcher = Path(filename)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            home, game = root/'home', root/'card/AM2ARM/games/AM2ARM Standard'
            native = home/'.config/AM2RStandardLinux'
            native.mkdir(parents=True)
            (native/'save1').write_bytes(b'saved progress')
            (native/'config.ini').write_text('[Screen]\nNano=1\n')
            (game/'runtime').mkdir(parents=True)
            (game/'data').mkdir()
            shutil.copy2(launcher, game/'runtime/launch.py')
            (game/'edition.json').write_text('{"game_name":"AM2RStandardLinux"}')
            (game/'data/gamecontrollerdb.txt').write_text('')
            with patch.dict(os.environ, AM2ARM_FRONTEND='stock'), patch.object(Path, 'home', return_value=home):
                options, _ = session.game_options(game)
                session.game_options(game)
            self.assertTrue(native.is_symlink())
            self.assertEqual(native.resolve(), options.resolve())
            self.assertTrue(options.is_relative_to(game))
            self.assertEqual((native/'save1').read_bytes(), b'saved progress')
            self.assertEqual((options/'config.ini').read_text(), '[Screen]\nNano=1\n')
            self.assertEqual(len(list(native.parent.glob('AM2RStandardLinux.before-portable-*'))), 1)

    def test_stock_install_registers_apps_entry_and_keeps_card_relative_path(self):
        with tempfile.TemporaryDirectory(prefix='stock card ') as directory:
            card = Path(directory)
            game = card/'AM2ARM/games/AM2ARM Standard'
            game.mkdir(parents=True)
            with patch.dict(os.environ, AM2ARM_FRONTEND='stock'):
                layout.write_play_entry(card, game)
                layout.write_play_entry(card, game)
            entry = card/'Apps/AM2ARMStandard'
            self.assertTrue((entry/'config.json').is_file())
            config = json.loads((entry/'config.json').read_text())
            self.assertEqual(config['launch'], 'launch.sh')
            self.assertEqual(config['label'], 'AM2ARM Standard')
            self.assertIn('AM2ARM_FRONTEND=stock', (entry/config['launch']).read_text())
            self.assertEqual(layout.installed_game(card), game)
            self.assertFalse((card/'Tools').exists())
            self.assertNotIn(directory, (card/'AM2ARM/state/installation.json').read_text())

    def test_unrelated_stock_entry_is_preserved_before_install(self):
        with tempfile.TemporaryDirectory() as directory:
            card = Path(directory)
            entry = card/'Apps/AM2ARMStandard'
            entry.mkdir(parents=True)
            config = entry/'config.json'
            config.write_text('{"label":"My other program"}')
            with patch.dict(os.environ, AM2ARM_FRONTEND='stock'):
                with self.assertRaises(RuntimeError):
                    layout.check_play_entry(card)
            self.assertEqual(config.read_text(), '{"label":"My other program"}')


if __name__ == '__main__':
    unittest.main()
