"""NextUI entry point for the shared title-menu installer."""
from pathlib import Path
import os
import tkinter as tk
import handheld_gui
import handheld_input
from nextui_controls import firmware_face_buttons
from trimui_device import display_size

handheld_input.firmware_face_buttons = firmware_face_buttons


class BrickWindow(handheld_gui.HandheldWindow):
    def render_intro(self):
        super().render_intro()
        self.dual.set_visible(False)

    def action(self, action):
        super().action(action)
        if not self.closed and self.picker is None and self.notice is None and self.focus_index == 1:
            self.focus_index = 0 if action in ('up', 'left') else 2
            self.highlight()


def main():
    root = tk.Tk()
    root.overrideredirect(True)
    card = Path(os.environ.get('SDCARD_PATH', '/mnt/SDCARD'))
    BrickWindow(root, output=card/'AM2ARM/games', size=display_size())
    root.mainloop()


if __name__ == '__main__':
    main()
