import os
from pathlib import Path
import tkinter as tk
import time
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from handheld_gui import HandheldWindow


@unittest.skipUnless(os.environ.get('DISPLAY'), 'requires an isolated X display')
class HandheldGuiTests(unittest.TestCase):
    def setUp(self):
        card = tempfile.TemporaryDirectory()
        self.addCleanup(card.cleanup)
        self.library = SimpleNamespace(card=Path(card.name), version='1.6.4', original=lambda: None)
        self.root = tk.Tk()
        self.window = HandheldWindow(self.root, self.library)
        self.root.update()

    def skip_intro(self):
        self.window.finish_intro()
        self.window.picker.back()

    def tearDown(self):
        self.window.busy = False
        if not self.window.closed:
            self.window.close()

    def test_confirm_skips_intro_without_opening_picker(self):
        with patch.object(self.window, 'begin') as begin:
            self.window.action('accept')
        begin.assert_called_once_with()
        self.assertIsNone(self.window.picker, 'Skipping the intro must consume confirm')
        self.window.action('accept')
        self.assertIsNotNone(self.window.picker)

    def test_wide_window_uses_full_canvas(self):
        self.root.geometry('1280x720')
        self.root.update()
        self.assertEqual(self.window.canvas.winfo_width(), 1280)
        self.assertEqual(self.window.canvas.winfo_height(), 720)

    def test_planet_framing_matches_the_games_240_pixel_view(self):
        backdrop = self.window.background
        for width, height in ((640, 480), (1024, 768), (1280, 720), (2340, 1080)):
            backdrop.resize(width, height)
            self.assertEqual(backdrop.stars.height(), round(640 * height / 240))
            self.assertEqual(backdrop.stars.width(), round(426 * height / 240))
            self.assertEqual(backdrop.star_y + backdrop.stars.height(), height)
            self.assertAlmostEqual(backdrop.star_x + backdrop.stars.width()/2,
                                   width/2, delta=1)

    def test_vertical_menu_keeps_every_action_visible_without_overlap(self):
        self.skip_intro()
        for width, height in ((640, 480), (1280, 720), (720, 720)):
            self.root.geometry(f'{width}x{height}')
            self.root.update()
            bottom = 0
            for button in self.window.buttons:
                left, top, w, h = button.bounds
                self.assertAlmostEqual(left + w / 2, width / 2, delta=2)
                self.assertGreaterEqual(top, bottom)
                self.assertLessEqual(top + h, height - 40)
                self.assertTrue(button.visible)
                bottom = top + h

    def test_wide_picker_fills_window_and_keeps_controls_inside(self):
        self.root.geometry('1280x720')
        self.root.update()
        self.window.browse()
        self.root.update()
        picker = self.window.picker
        self.assertEqual(picker.frame.winfo_width(), 1280)
        self.assertEqual(picker.frame.winfo_height(), 720)
        self.assertLessEqual(picker.items.winfo_y() + picker.items.winfo_height(), 720)

    def test_picker_can_go_up_without_a_shoulder_button(self):
        with tempfile.TemporaryDirectory() as folder:
            child = Path(folder) / 'original game'
            child.mkdir()
            (child / 'AM2R_11.zip').write_bytes(b'not installed by this test')
            self.skip_intro()
            self.window.source = child / 'AM2R_11.zip'
            self.window.browse()
            self.window.action('accept')
            self.assertIsNotNone(self.window.picker)
            self.assertEqual(self.window.picker.path, Path(folder))

    def test_error_back_returns_to_installer_without_exiting(self):
        self.skip_intro()
        self.window.messages.put(('error', 'Wrong original game.\nPlease choose AM2R 1.1.'))
        self.root.after_cancel(self.window.poll_id)
        self.window.poll()
        self.window.action('back')
        self.assertFalse(self.window.closed)
        self.assertFalse(self.window.busy)

    def test_square_screen_keeps_button_text_inside_each_button(self):
        self.root.geometry('720x720')
        self.root.update()
        self.skip_intro()
        self.root.update()
        for button in self.window.buttons:
            left, top, width, height = button.bounds
            x1, y1, x2, y2 = self.window.canvas.bbox(button.text_item)
            self.assertGreaterEqual(x1, left)
            self.assertLessEqual(x2, left + width)
            self.assertGreaterEqual(y1, top)
            self.assertLessEqual(y2, top + height)

    def test_back_from_main_menu_does_not_accidentally_exit(self):
        self.skip_intro()
        self.window.action('back')
        self.assertFalse(self.window.closed)
        self.window.action('back')
        self.assertFalse(self.window.closed)
        self.window.action('back')
        self.window.action('accept')
        self.assertTrue(self.window.closed)


if __name__ == '__main__':
    unittest.main()
