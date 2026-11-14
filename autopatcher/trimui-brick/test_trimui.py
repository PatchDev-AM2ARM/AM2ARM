import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch
from contextlib import ExitStack

import nextui_controls as controls
import nextui_session as session
from trimui_device import current_device, display_size


class StartupTests(unittest.TestCase):
    def launch(self, device, architecture='aarch64'):
        with tempfile.TemporaryDirectory(prefix='trimui card ') as directory:
            root = Path(directory)
            runtime = root/'AM2ARM/runtime'
            (runtime/'core').mkdir(parents=True)
            shutil.copy2(Path(__file__).with_name('start.sh'), runtime/'start.sh')
            loader = runtime/'core/ld-linux-aarch64.so.1'
            loader.write_text('#!/bin/sh\nprintf "session reached\\n"\n')
            loader.chmod(0o755)
            bin_path = root/'bin'
            bin_path.mkdir()
            uname = bin_path/'uname'
            uname.write_text('#!/bin/sh\nprintf "%s\\n" "'+architecture+'"\n')
            uname.chmod(0o755)
            result = subprocess.run(['sh', str(runtime/'start.sh'), 'patcher'],
                env=dict(os.environ, PATH=str(bin_path)+':'+os.environ['PATH'],
                         AM2ARM_FRONTEND='nextui', PLATFORM='tg5040', DEVICE=device),
                capture_output=True, text=True, timeout=5)
            logs = '\n'.join(p.read_text() for p in (root/'AM2ARM/logs').glob('*.log'))
            return result.returncode, logs

    def test_smartpro_reaches_session(self):
        code, logs = self.launch('smartpro')
        self.assertEqual(code, 0, logs)
        self.assertIn('session reached', logs)

    def test_brick_still_reaches_session(self):
        code, logs = self.launch('brick')
        self.assertEqual(code, 0, logs)
        self.assertIn('session reached', logs)

    def test_unverified_models_do_not_reach_session(self):
        for model in ('smartpros', 'brickpro', 'unknown'):
            with self.subTest(model=model):
                code, logs = self.launch(model)
                self.assertNotEqual(code, 0)
                self.assertNotIn('session reached', logs)

    def test_wrong_architecture_does_not_reach_session(self):
        code, logs = self.launch('smartpro', 'armv7l')
        self.assertNotEqual(code, 0)
        self.assertNotIn('session reached', logs)


class ModelTests(unittest.TestCase):
    def test_nextui_models_choose_their_native_display(self):
        for name, expected in [('brick', (1024, 768)), ('smartpro', (1280, 720))]:
            with self.subTest(model=name):
                device = current_device({'PLATFORM': 'tg5040', 'DEVICE': name})
                self.assertEqual(display_size(device), expected)

    def test_stock_models_use_firmware_identity_not_an_inherited_device_variable(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            mainui, cmdline = root/'MainUI', root/'cmdline'
            cmdline.write_text('console=tty0 lcd=jd9168')
            for label, expected in [(b'Trimui Brick', (1024, 768)),
                                    (b'Trimui Smart Pro', (1280, 720))]:
                with self.subTest(model=label):
                    mainui.write_bytes(b'\x7fELF\0'+label+b'\0version\0')
                    device = current_device({'AM2ARM_FRONTEND': 'stock', 'DEVICE': 'brick'},
                                            mainui, cmdline)
                    self.assertEqual(display_size(device), expected)

    def test_original_brick_panel_fallback_is_preserved(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            mainui, cmdline = root/'MainUI', root/'cmdline'
            mainui.write_bytes(b'\x7fELF\0')
            cmdline.write_text('console=tty0 lcd=jd9168\n')
            self.assertEqual(current_device({'AM2ARM_FRONTEND': 'stock'}, mainui, cmdline), 'brick')

    def test_other_models_and_ambiguous_identity_are_rejected(self):
        for env in ({'PLATFORM': 'tg5050', 'DEVICE': 'smartpro'},
                    {'PLATFORM': 'tg5040', 'DEVICE': 'brickpro'},
                    {'PLATFORM': 'tg5040'}):
            with self.subTest(environment=env), self.assertRaises(RuntimeError):
                current_device(env)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            mainui, cmdline = root/'MainUI', root/'cmdline'
            cmdline.write_text('lcd=jd9168')
            for label in (b'Trimui Smart Pro S\0', b'Trimui Brick Pro\0',
                          b'Trimui Brick\0Trimui Smart Pro\0'):
                mainui.write_bytes(label)
                with self.subTest(model=label), self.assertRaises(RuntimeError):
                    current_device({'AM2ARM_FRONTEND': 'stock'}, mainui, cmdline)

    def test_smartpro_controller_keeps_sticks_triggers_and_printed_letters(self):
        with tempfile.TemporaryDirectory() as directory:
            entry = Path(directory)/'event0'
            device = entry/'device'
            (device/'id').mkdir(parents=True)
            (device/'name').write_text('TRIMUI Player1')
            for field, value in zip(('bustype', 'vendor', 'product', 'version'),
                                    ('0003', '045e', '028e', '0114')):
                (device/'id'/field).write_text(value)
            with patch.object(controls.Path, 'glob', return_value=[entry]):
                mapping = controls.brick_mappings('smartpro')
            parts = mapping.split(',')
            bindings = dict(p.split(':', 1) for p in parts if ':' in p)
            self.assertEqual({key: bindings[key] for key in ('a','b','x','y','leftx',
                              'lefty','rightx','righty','lefttrigger','righttrigger')},
                             {'a':'b1','b':'b0','x':'b3','y':'b2','leftx':'a0',
                              'lefty':'a1','rightx':'a3','righty':'a4',
                              'lefttrigger':'a2','righttrigger':'a5'})
            self.assertNotIn('leftstick', bindings)
            self.assertNotIn('rightstick', bindings)

    def test_fresh_display_defaults_and_existing_settings(self):
        launcher = os.environ.get('AM2ARM_LINUX_LAUNCHER')
        if not launcher:
            self.skipTest('Set AM2ARM_LINUX_LAUNCHER for save integration.')
        for model, ratio in [('brick', '0'), ('smartpro', '1')]:
            with self.subTest(model=model), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                game, home = root/'game', root/'home'
                (game/'runtime').mkdir(parents=True)
                (game/'data').mkdir()
                shutil.copy2(launcher, game/'runtime/launch.py')
                (game/'edition.json').write_text('{"game_name":"AM2RStandardLinux"}')
                (game/'data/gamecontrollerdb.txt').write_text('')
                with patch.dict(os.environ, AM2ARM_FRONTEND='stock'), \
                     patch.object(Path, 'home', return_value=home):
                    options, _ = session.game_options(game, model)
                    self.assertIn('AspectRatio='+ratio+'\n', (options/'config.ini').read_text())
                    (options/'config.ini').write_text('[Screen]\nAspectRatio=2\nNano=1\n')
                    (options/'save1').write_bytes(b'existing progress')
                    session.game_options(game, model)
                    self.assertEqual((options/'config.ini').read_text(), '[Screen]\nAspectRatio=2\nNano=1\n')
                    self.assertEqual((options/'save1').read_bytes(), b'existing progress')


class SessionTests(unittest.TestCase):
    def test_game_launch_passes_the_same_native_size_to_both_display_components(self):
        launcher = os.environ.get('AM2ARM_LINUX_LAUNCHER')
        if not launcher:
            self.skipTest('Set AM2ARM_LINUX_LAUNCHER for session integration.')
        class Finished:
            returncode = 0
            def poll(self):
                return 0
        for model, size in [('brick', '1024x768'), ('smartpro', '1280x720')]:
            with self.subTest(model=model), tempfile.TemporaryDirectory() as directory, ExitStack() as stack:
                root = Path(directory)
                (root/'logs').mkdir()
                game = root/'game'
                (game/'data').mkdir(parents=True)
                (game/'runtime').mkdir()
                (game/'data/gamecontrollerdb.txt').write_text('')
                (game/'edition.json').write_text('{"game_name":"AM2RStandardLinux","game_label":"AM2ARM"}')
                shutil.copy2(launcher, game/'runtime/launch.py')
                launches = []
                def start(arguments, env, log, cwd=None):
                    launches.append((arguments, env.copy()))
                    return Finished()
                for target, value in [('ROOT', root), ('RUNTIME', root/'runtime'),
                                      ('CARD', root), ('start', start)]:
                    stack.enter_context(patch.object(session, target, value))
                stack.enter_context(patch.object(session, 'installed_game', return_value=game))
                stack.enter_context(patch.object(session, 'prepare_rumble', return_value=False))
                stack.enter_context(patch.object(session, 'wait_ready'))
                stack.enter_context(patch.object(session, 'firmware_library', side_effect=lambda names: root/names[0]))
                stack.enter_context(patch.object(Path, 'home', return_value=root/'home'))
                stack.enter_context(patch.dict(os.environ, AM2ARM_FRONTEND='nextui', PLATFORM='tg5040', DEVICE=model))
                self.assertEqual(session.run('game'), 0)
                xserver = next(args for args, env in launches if str(root/'runtime/bin/Xvfb') in args)
                self.assertIn(size+'x24', xserver)
                _, env = next((args, env) for args, env in launches if str(game/'data/runner') in args)
                self.assertEqual(env['CRUSTY_RESOLUTION'], size)
                self.assertEqual(env['AM2ARM_TRIMUI_DEVICE'], model)


if __name__ == '__main__':
    unittest.main()
