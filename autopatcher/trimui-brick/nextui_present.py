"""Present the installer's X11 canvas through the firmware's SDL video driver."""
import ctypes as C
import os
from pathlib import Path
import signal
import time
from trimui_device import display_size


class XImage(C.Structure):
    _fields_ = [('width', C.c_int), ('height', C.c_int), ('xoffset', C.c_int),
                ('format', C.c_int), ('data', C.c_void_p), ('byte_order', C.c_int),
                ('bitmap_unit', C.c_int), ('bitmap_bit_order', C.c_int),
                ('bitmap_pad', C.c_int), ('depth', C.c_int), ('bytes_per_line', C.c_int),
                ('bits_per_pixel', C.c_int), ('red_mask', C.c_ulong),
                ('green_mask', C.c_ulong), ('blue_mask', C.c_ulong)]


def function(library, name, result, arguments):
    entry = getattr(library, name)
    entry.restype, entry.argtypes = result, arguments
    return entry


def main():
    width, height = display_size()
    ptr, integer, uint = C.c_void_p, C.c_int, C.c_uint
    x = C.CDLL('libX11.so.6')
    open_display = function(x, 'XOpenDisplay', ptr, [C.c_char_p])
    close_display = function(x, 'XCloseDisplay', integer, [ptr])
    root_window = function(x, 'XDefaultRootWindow', C.c_ulong, [ptr])
    get_image = function(x, 'XGetImage', C.POINTER(XImage),
        [ptr, C.c_ulong, integer, integer, uint, uint, C.c_ulong, integer])
    destroy_image = function(x, 'XDestroyImage', integer, [C.POINTER(XImage)])
    display = open_display(None)
    if not display:
        raise RuntimeError('Installer input display is not ready.')
    sdl = None
    window = renderer = texture = None
    running = [True]
    def stop(*_):
        running[0] = False
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    try:
        # This presenter has its own process, so it cannot collide with the
        # game's SDL implementation or the installer's Tk interface.
        sdl = C.CDLL(os.environ['AM2ARM_FIRMWARE_SDL'], mode=os.RTLD_NOW | os.RTLD_LOCAL)
        signatures = {
            'GetError': (C.c_char_p, []), 'GetNumVideoDrivers': (integer, []),
            'GetVideoDriver': (C.c_char_p, [integer]), 'GetCurrentVideoDriver': (C.c_char_p, []),
            'VideoInit': (integer, [C.c_char_p]), 'VideoQuit': (None, []),
            'CreateWindow': (ptr, [C.c_char_p, integer, integer, integer, integer, uint]),
            'DestroyWindow': (None, [ptr]), 'CreateRenderer': (ptr, [ptr, integer, uint]),
            'DestroyRenderer': (None, [ptr]), 'CreateTexture': (ptr, [ptr, uint, integer, integer, integer]),
            'DestroyTexture': (None, [ptr]), 'LockTexture': (integer, [ptr, ptr, C.POINTER(ptr), C.POINTER(integer)]),
            'UnlockTexture': (None, [ptr]), 'RenderCopy': (integer, [ptr, ptr, ptr, ptr]),
            'RenderClear': (integer, [ptr]), 'RenderPresent': (None, [ptr]),
            'PollEvent': (integer, [ptr]), 'ShowCursor': (integer, [integer]),
            'SetHint': (integer, [C.c_char_p, C.c_char_p]),
        }
        api = {name: function(sdl, 'SDL_'+name, *signature) for name, signature in signatures.items()}
        drivers = [api['GetVideoDriver'](i).decode() for i in range(api['GetNumVideoDrivers']())]
        print('Firmware video drivers:', ', '.join(drivers), flush=True)
        selected = os.environ.get('AM2ARM_PRESENT_DRIVER')
        if selected is None:
            selected = next((name for name in drivers if name.lower() not in
                ('x11', 'wayland', 'dummy', 'offscreen')), None)
        if selected is None:
            raise RuntimeError('No native firmware video driver is available.')
        if os.environ.get('AM2ARM_PRESENT_DISPLAY'):
            os.environ['DISPLAY'] = os.environ['AM2ARM_PRESENT_DISPLAY']
        os.environ.pop('SDL_VIDEODRIVER', None)
        if api['VideoInit'](selected.encode()) < 0:
            raise RuntimeError('Firmware video failed: '+api['GetError']().decode())
        api['SetHint'](b'SDL_RENDER_SCALE_QUALITY', b'0')
        window = api['CreateWindow'](b'AM2ARM Autopatcher', 0, 0, width, height, 0x1005)
        if not window:
            raise RuntimeError('Installer window failed: '+api['GetError']().decode())
        renderer = api['CreateRenderer'](window, -1, 2) or api['CreateRenderer'](window, -1, 1)
        if not renderer:
            raise RuntimeError('Installer renderer failed: '+api['GetError']().decode())
        # SDL_PIXELFORMAT_RGB888, streaming access; Xvfb supplies 24-bit RGB
        # in 32-bit little-endian words. Both descriptions are checked below.
        texture = api['CreateTexture'](renderer, 0x16161804, 1, width, height)
        if not texture:
            raise RuntimeError('Installer canvas failed: '+api['GetError']().decode())
        api['ShowCursor'](0)
        event = C.create_string_buffer(128)
        root = root_window(display)
        first = True
        while running[0]:
            start = time.monotonic()
            while api['PollEvent'](event):
                if int.from_bytes(event.raw[:4], 'little') == 0x100:
                    running[0] = False
            snapshot = get_image(display, root, 0, 0, width, height, C.c_ulong(-1).value, 2)
            if not snapshot:
                raise RuntimeError('Installer canvas is unavailable.')
            try:
                source = snapshot.contents
                if (source.bits_per_pixel, source.byte_order, source.red_mask,
                    source.green_mask, source.blue_mask) != (32, 0, 0xff0000, 0xff00, 0xff):
                    raise RuntimeError('Unexpected installer pixel format.')
                pixels, pitch = ptr(), integer()
                if api['LockTexture'](texture, None, C.byref(pixels), C.byref(pitch)) < 0:
                    raise RuntimeError('Installer canvas update failed: '+api['GetError']().decode())
                if pitch.value == source.bytes_per_line:
                    C.memmove(pixels, source.data, pitch.value*height)
                else:
                    for row in range(height):
                        C.memmove(pixels.value+row*pitch.value, source.data+row*source.bytes_per_line, width*4)
                api['UnlockTexture'](texture)
            finally:
                destroy_image(snapshot)
            api['RenderClear'](renderer)
            if api['RenderCopy'](renderer, texture, None, None) < 0:
                raise RuntimeError('Installer presentation failed: '+api['GetError']().decode())
            api['RenderPresent'](renderer)
            if first:
                print('Installer canvas visible through', selected, flush=True)
                Path(os.environ['AM2ARM_PRESENT_READY']).write_text('ready\n')
                first = False
            time.sleep(max(0, 1/30-(time.monotonic()-start)))
    finally:
        if sdl is not None and 'api' in locals():
            if texture:
                api['DestroyTexture'](texture)
            if renderer:
                api['DestroyRenderer'](renderer)
            if window:
                api['DestroyWindow'](window)
            api['VideoQuit']()
        close_display(display)


if __name__ == '__main__':
    main()
