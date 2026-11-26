from contextlib import ExitStack
import json
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from first_run import Library
import nextui_controls
import play

ELF = bytes.fromhex('7f454c460201'+'00'*10+'0300b700')
SOURCE = Path(__file__).resolve().parents[2]


class PlayTests(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)
        self.gmloader = self.root/'gmloader'
        for name in ('fallback/libSDL2-2.0.so.0', 'fallback/libwayland-client.so.0'):
            self.library_at(self.gmloader/name)
        (self.gmloader/'lib').mkdir()
        self.folder = self.root/'links'
        self.folder.mkdir()
        self.library = Library(self.root/'app', self.root/'card', self.root/'card/ports')
        self.library.game.mkdir(parents=True)
        (self.library.game/'gmloader.json').write_bytes((SOURCE/'gmloader/gmloader.json').read_bytes())
        for patcher in (patch.object(play, 'GMLOADER', self.gmloader),
                        patch.object(play, 'controller_mappings', return_value='device mapping')):
            patcher.start()
            self.addCleanup(patcher.stop)

    def library_at(self, path):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(ELF)
        return path

    def links(self):
        return {path.name: path.resolve() for path in self.folder.iterdir()}

    def test_settings_point_at_the_card(self):
        config = play.loader_config(self.library)
        self.assertEqual(config['apk_path'], str(self.library.port))
        self.assertEqual(config['save_dir'], str(self.library.saves))
        self.assertFalse(config['disable_extensions'])
        self.assertEqual(config['plugins'][0]['path'], 'libdualscreen.so')

    def test_bundled_libraries_only_fill_in_for_the_firmware(self):
        firmware = self.root/'firmware'
        self.library_at(firmware/'libwayland-client.so.0')
        play.link_libraries(self.folder, [firmware])
        self.assertEqual(self.links(), {'libSDL2-2.0.so.0': self.gmloader/'fallback/libSDL2-2.0.so.0'})

    def test_chosen_firmware_sdl_is_kept(self):
        sdl = self.library_at(self.root/'vendor/libSDL2.so')
        play.link_libraries(self.folder, [], [('libSDL2-2.0.so.0', sdl)])
        self.assertEqual(self.links()['libSDL2-2.0.so.0'], sdl)

    def test_game_gets_the_firmwares_environment_without_the_installers(self):
        env = play.game_environment({'HOME': '/firmware', 'PYTHONHOME': '/bundled', 'PYTHONPATH': '/bundled',
                                     'LD_LIBRARY_PATH': '/firmware/lib::/firmware/lib',
                                     'SDL_GAMECONTROLLERCONFIG': 'firmware mapping'}, self.folder, None, ('/vendor',))
        self.assertEqual(env['HOME'], '/firmware')
        self.assertFalse([key for key in env if key.startswith('PYTHON')])
        self.assertEqual(env['LD_LIBRARY_PATH'].split(':'),
                         [str(self.folder), str(self.gmloader/'lib'), '/firmware/lib', '/vendor'])
        self.assertEqual(env['GMLOADER_LIB_PATH'], str(self.gmloader/'lib'))
        self.assertEqual(env['SDL_GAMECONTROLLERCONFIG'], 'firmware mapping\ndevice mapping')

    def test_wayland_game_uses_the_wayland_driver_unless_the_firmware_chose(self):
        with patch.object(play, 'library_dirs', return_value=[]):
            env = play.wayland_game(self.library, self.folder, {'WAYLAND_DISPLAY': 'wayland-1'})
            self.assertEqual(env['SDL_VIDEODRIVER'], 'wayland')
            for path in self.folder.iterdir():
                path.unlink()
            env = play.wayland_game(self.library, self.folder, {'SDL_VIDEODRIVER': 'firmware'})
            self.assertEqual(env['SDL_VIDEODRIVER'], 'firmware')

    def test_direct_game_uses_the_sdl_egl_and_gles_that_showed_a_frame(self):
        vendor = self.root/'vendor'
        sdl, egl, gles = (self.library_at(vendor/name) for name in ('libSDL2.so', 'libmali.so.1', 'libGLESv2.so'))
        for device, driver, gbm in (('g350', 'KMSDRM', True), ('flip', 'KMSDRM', True), ('brick', 'mali', False)):
            with self.subTest(device=device), patch.object(play, 'library_dirs', return_value=[]), \
                    patch('nextui_session.report'), \
                    patch('nextui_session.display_options', return_value=iter([(sdl, driver, egl, gles)])):
                env = play.direct_game(self.library, self.folder, {'WAYLAND_DISPLAY': 'stale'}, device)
            self.assertNotIn('WAYLAND_DISPLAY', env)
            self.assertEqual((env['SDL_VIDEODRIVER'], env['SDL_VIDEO_EGL_DRIVER'], env['SDL_VIDEO_GL_DRIVER']),
                             (driver, str(egl), str(gles)))
            self.assertEqual(env.get('EGL_PLATFORM') == 'gbm', gbm)
            links = self.links()
            self.assertEqual((links['libSDL2-2.0.so.0'], links['libEGL.so.1'], links['libGLESv2.so.2']), (sdl, egl, gles))
            for path in self.folder.iterdir():
                path.unlink()

    def test_direct_game_without_a_working_driver_is_reported(self):
        with patch('nextui_session.report'), patch('nextui_session.display_options', return_value=iter(())), \
                self.assertRaisesRegex(RuntimeError, 'GLES2'):
            play.direct_game(self.library, self.folder, {}, 'brick')

    def test_sway_is_asked_for_the_games_window_and_not_the_second_screen(self):
        process = SimpleNamespace(pid=42, poll=lambda: None)
        commands = []

        def swaymsg(arguments, **kwargs):
            commands.append(arguments[-1])
            # The window takes a moment to appear.
            return subprocess.CompletedProcess(arguments, 0 if len(commands) > 1 else 2, '[{"success": true}]', '')
        with patch.object(play, 'sway_output', return_value='DSI-2'), patch.object(play.subprocess, 'run', side_effect=swaymsg):
            play.fullscreen(process, {})
        self.assertEqual(len(commands), 2)
        self.assertEqual(commands[-1], '[pid=42 title="^GMLoader$"] move container to output "DSI-2", fullscreen enable, focus')

    def test_other_compositors_are_left_alone(self):
        with patch.object(play, 'sway_output', return_value=None), \
                patch.object(play.subprocess, 'run', side_effect=AssertionError('called swaymsg')):
            play.fullscreen(SimpleNamespace(pid=1, poll=lambda: None), {})

    def test_only_the_firmwares_own_motor_needs_the_launcher(self):
        with ExitStack() as resources, patch.object(play, 'BrickRumble') as motor:
            for device in (None, 'smartpros', 'flip', 'g350'):
                env = {}
                self.assertIsNone(play.firmware_vibration(self.root, env, device, resources))
                self.assertEqual(env, {})
            motor.assert_not_called()
            for device in ('brick', 'smartpro'):
                env = {}
                self.assertIsNotNone(play.firmware_vibration(self.root, env, device, resources))
                self.assertEqual(env['LD_PRELOAD'], str(self.gmloader/'lib/librumble.so'))
                motor.assert_called_with(Path(env['AM2ARM_RUMBLE_SOCKET']))
            motor.side_effect = FileNotFoundError('no motor')
            env = {}
            self.assertIsNone(play.firmware_vibration(self.root, env, 'brick', resources))
            self.assertEqual(env, {})

    def test_menu_button_ends_the_game_normally(self):
        process = subprocess.Popen([sys.executable, '-c', 'import signal, sys, time\n'
            'signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))\nprint(flush=True)\ntime.sleep(30)'], stdout=subprocess.PIPE)
        self.addCleanup(process.stdout.close)
        process.stdout.readline()
        self.assertEqual(play.supervise(process, SimpleNamespace(requested=lambda: True)), 0)

    def test_whole_run_starts_the_loader_beside_its_music(self):
        loader = self.gmloader/'gmloadernext.aarch64'
        loader.write_text('#!/bin/sh\npwd > "$TRACE"\ncat "$2" >> "$TRACE"\nexit 3\n')
        loader.chmod(0o755)
        with patch.object(Library, 'version', '1.6.4'), patch.object(play, 'fullscreen'), \
                patch.object(play, 'library_dirs', return_value=[]):
            status = play.run(self.library, 'ports', {'TRACE': str(self.root/'trace'), 'PATH': '/usr/bin:/bin'})
        self.assertEqual(status, 3)
        folder, _, config = (self.root/'trace').read_text().partition('\n')
        self.assertEqual(Path(folder), self.library.game.resolve())
        self.assertEqual(json.loads(config)['save_dir'], str(self.library.saves))
        self.assertTrue(self.library.saves.is_dir())


class ControllerTests(unittest.TestCase):
    def test_rg_ds_virtual_controller_gets_its_mapping(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            model = root/'model'
            model.write_text('Anbernic RG DS\0')
            pad = root/'devices/virtual/misc/uhid/pad'
            (pad/'id').mkdir(parents=True)
            (pad/'name').write_text('Sony Interactive Entertainment DualSense Wireless Controller')
            for field, value in (('bustype', '0003'), ('vendor', '054c'), ('product', '0ce6'), ('version', '8111')):
                (pad/'id'/field).write_text(value)
            (root/'input/event3').mkdir(parents=True)
            (root/'input/event3/device').symlink_to(pad)
            rows = nextui_controls.rgds_mappings(root/'input', model).split('\n')
            self.assertEqual(rows[0], nextui_controls.RGDS)
            self.assertTrue(rows[1].startswith('030000004c050000e60c000011810000,Anbernic RG DS virtual controller,'))
            model.write_text('AYN Thor')
            self.assertEqual(nextui_controls.rgds_mappings(root/'input', model), nextui_controls.RGDS)


if __name__ == '__main__':
    unittest.main()
