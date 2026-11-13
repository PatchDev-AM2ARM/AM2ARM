"""Desktop entry point and local font registration for the shared installer UI."""
import ctypes
import ctypes.util
import os
import tkinter as tk

def load_fonts(assets):
    try:
        if os.name == 'nt':
            for file in assets.glob('*.ttf'):
                ctypes.windll.gdi32.AddFontResourceExW(str(file), 0x10, 0)
        else:
            library = ctypes.CDLL(ctypes.util.find_library('fontconfig') or 'libfontconfig.so.1')
            library.FcConfigGetCurrent.restype = ctypes.c_void_p
            library.FcConfigAppFontAddFile.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
            config = library.FcConfigGetCurrent()
            for file in assets.glob('*.ttf'):
                library.FcConfigAppFontAddFile(config, os.fsencode(file))
    except (OSError, AttributeError, TypeError):
        pass


def run_gui():
    from handheld_gui import HandheldWindow
    root = tk.Tk()
    HandheldWindow(root, size=(960, 600))
    root.mainloop()
