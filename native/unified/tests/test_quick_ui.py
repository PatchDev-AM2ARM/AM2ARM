import os
from pathlib import Path
import tempfile
import tkinter as tk
import unittest
from unittest.mock import patch

from first_run import Library
from handheld_gui import HandheldWindow
from patch_core import PatchError
from test_install import original_at, release_at


@unittest.skipUnless(os.environ.get('DISPLAY'), 'needs a desktop display')
class QuickUiTests(unittest.TestCase):
    def window(self, original=True):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        card = Path(tmp.name)
        release_at(card/'am2arm-launcher/AM2ARM/game/am2arm.zip')
        self.library = Library(card/'am2arm-launcher/AM2ARM', card, card/'ports')
        self.original = original_at(card/'AM2R_11.zip') if original else None
        self.root = tk.Tk()
        window = HandheldWindow(self.root, self.library, (640, 480))
        self.addCleanup(lambda: window.close() if not window.closed else None)
        return window

    def finish(self, win):
        message = win.messages.get(timeout=3)
        while message[0] == 'progress':
            message = win.messages.get(timeout=3)
        win.messages.put(message)
        win.poll()

    def test_installation_starts_without_any_confirmation(self):
        win = self.window()
        with patch.object(self.library, 'install') as install:
            win.finish_intro()
            win.finish_intro()
            self.finish(win)
        install.assert_called_once()
        self.assertEqual(install.call_args.args[0], self.original)
        self.assertTrue(win.play)
        self.assertTrue(win.closed)

    def test_missing_original_opens_card_picker_and_cancel_does_not_install(self):
        win = self.window(False)
        win.finish_intro()
        self.assertEqual(win.picker.path, self.library.card)
        win.action('back')
        self.assertIsNone(win.picker)
        self.assertFalse(win.busy)
        win.action('accept')
        self.assertIsNotNone(win.picker)
        with patch.object(win, 'begin') as begin:
            source = original_at(self.library.card/'backup.zip')
            win.picker.finish(source)
            self.assertEqual(win.source, source)
            begin.assert_called_once_with()

    def test_error_is_shown_and_allows_another_original(self):
        win = self.window()
        with patch.object(self.library, 'install', side_effect=PatchError('Wrong original file')):
            win.finish_intro()
            self.finish(win)
        self.assertFalse(win.closed)
        self.assertFalse(win.play)
        self.assertIsNotNone(win.notice)
        win.action('accept')
        self.assertIsNone(win.source)
        win.action('accept')
        self.assertIsNotNone(win.picker)

    def test_window_names_the_release(self):
        win = self.window()
        self.assertIn('1.6.4', win.canvas.itemcget(win.subtitle, 'text'))
