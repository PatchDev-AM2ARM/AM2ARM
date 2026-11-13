import importlib.util
from pathlib import Path
import socket
import tempfile
import unittest
from unittest.mock import patch
import json
import subprocess


class DisplaySessionTests(unittest.TestCase):
    def test_sway_keeps_installer_on_the_active_menu_screen(self):
        from handheld_platform import sway_output
        outputs = [
            {'name': 'DSI-1', 'active': True, 'power': False, 'focused': False},
            {'name': 'DSI-2', 'active': True, 'power': True, 'focused': True},
        ]
        with patch('handheld_platform.subprocess.run', return_value=
                   subprocess.CompletedProcess([], 0, json.dumps(outputs), '')):
            self.assertEqual(sway_output({'SWAYSOCK': '/run/sway-test.sock'}), 'DSI-2')

    def test_weston_does_not_invoke_sway(self):
        from handheld_platform import sway_output
        with patch('handheld_platform.subprocess.run', side_effect=AssertionError('Unexpected IPC')):
            self.assertIsNone(sway_output({'WAYLAND_DISPLAY': 'wayland-0'}))

    def test_active_session_is_preserved_instead_of_forcing_rgds_paths(self):
        self.assertIsNotNone(importlib.util.find_spec('handheld_platform'),
                             'Portable session detection is missing')
        from handheld_platform import wayland_environment
        with tempfile.TemporaryDirectory() as folder:
            endpoint = socket.socket(socket.AF_UNIX)
            self.addCleanup(endpoint.close)
            endpoint.bind(str(Path(folder) / 'wayland-3'))
            env = wayland_environment({'XDG_RUNTIME_DIR': folder, 'WAYLAND_DISPLAY': 'wayland-3'})
            self.assertEqual(env['XDG_RUNTIME_DIR'], folder)
            self.assertEqual(env['WAYLAND_DISPLAY'], 'wayland-3')

    def test_missing_session_fails_before_starting_a_display(self):
        self.assertIsNotNone(importlib.util.find_spec('handheld_platform'))
        from handheld_platform import wayland_environment
        with tempfile.TemporaryDirectory() as folder:
            with self.assertRaisesRegex(RuntimeError, 'Wayland'):
                wayland_environment({'XDG_RUNTIME_DIR': folder, 'WAYLAND_DISPLAY': 'missing'})
