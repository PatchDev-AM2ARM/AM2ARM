import ctypes
import os
from pathlib import Path
import socket
import subprocess
import tempfile
import unittest
from unittest.mock import patch


class BridgeTests(unittest.TestCase):
    def test_game_calls_route_only_selected_builtin_pad_and_stop(self):
        folder = Path(__file__).resolve().parent
        source = folder/'native/rumble'
        if not source.is_dir():
            source = folder.parent/'native/rumble'
        with tempfile.TemporaryDirectory() as directory:
            work = Path(directory)
            subprocess.run(['cc', '-O2', '-fPIC', '-c', str(source/'evdev_rumble.c'),
                '-DAM2ARM_Rumble=AM2ARM_EvdevRumble',
                '-DAM2ARM_RumbleStop=AM2ARM_EvdevRumbleStop', '-o', str(work/'base.o')], check=True)
            subprocess.run(['cc', '-O2', '-fPIC', '-shared', str(source/'brick_rumble.c'),
                str(work/'base.o'), '-lm', '-o', str(work/'bridge.so')], check=True)
            library = ctypes.CDLL(str(work/'bridge.so'))
            play = library.AM2ARM_Rumble
            play.argtypes = [ctypes.c_char_p, ctypes.c_double, ctypes.c_double]
            play.restype = ctypes.c_double
            stop = library.AM2ARM_RumbleStop
            stop.restype = ctypes.c_double
            address = work/'rumble.sock'
            server = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
            self.addCleanup(server.close)
            server.bind(str(address)); server.settimeout(.2)
            guid = '030000005e0400008e02000014010000'
            with patch.dict(os.environ, AM2ARM_RUMBLE_SOCKET=str(address), AM2ARM_RUMBLE_GUID=guid):
                self.assertEqual(play(guid.encode(), .5, .25), 1)
                self.assertEqual(server.recv(16), bytes([128]))
                play(guid.encode(), .5, .25)
                with self.assertRaises(socket.timeout):
                    server.recv(16)
                stop()
                self.assertEqual(server.recv(16), bytes([0]))
                self.assertEqual(play(b'not-a-controller', 1, 1), 0)
                with self.assertRaises(socket.timeout):
                    server.recv(16)
                play(guid.encode(), float('nan'), float('inf'))
                with self.assertRaises(socket.timeout):
                    server.recv(16)


if __name__ == '__main__':
    unittest.main()
