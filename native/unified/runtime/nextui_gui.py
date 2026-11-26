"""Single-screen entry point for the shared installer."""
import tkinter as tk
from first_run import Library
import handheld_gui
import handheld_input
from nextui_controls import firmware_face_buttons
from trimui_device import display_size

original_faces = handheld_input.firmware_face_buttons


def device_faces(name, ids, keys, paths=None):
    return firmware_face_buttons(name, ids, keys, paths) or original_faces(name, ids, keys, paths)


handheld_input.firmware_face_buttons = device_faces


def main():
    root = tk.Tk()
    root.overrideredirect(True)
    window = handheld_gui.HandheldWindow(root, Library.from_environment(), display_size())
    root.mainloop()
    return 0 if window.play else 2


if __name__ == '__main__':
    raise SystemExit(main())
