import ctypes
import os
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

from brick_rumble import BrickRumble

SOURCE = Path(__file__).resolve().parents[2]/'gmloader/rumble.c'
# A stand-in SDL whose controller 1 has vibration and whose others do not
SDL = '''int played;
int SDL_GameControllerRumble(void *controller, unsigned short low, unsigned short high, unsigned duration) {
    (void)low; (void)high; (void)duration;
    if (controller != (void *)1) return -1;
    played++;
    return 0;
}
'''


@unittest.skipUnless(shutil.which('cc'), 'needs a C compiler')
class PreloadTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        temporary = tempfile.TemporaryDirectory()
        cls.addClassCleanup(temporary.cleanup)
        work = Path(temporary.name)
        (work/'sdl.c').write_text(SDL)
        subprocess.run(['cc', '-fPIC', '-shared', work/'sdl.c', '-o', work/'libsdl.so'], check=True)
        # Linking it after the preload is the order RTLD_NEXT sees on the handheld.
        subprocess.run(['cc', '-Wall', '-Wextra', '-Werror', '-O2', '-fPIC', '-shared', '-fvisibility=hidden', SOURCE,
                        '-o', work/'librumble.so', '-Wl,--no-as-needed', f'-L{work}', '-lsdl', f'-Wl,-rpath,{work}', '-ldl'], check=True)
        cls.address = work/'rumble.sock'
        cls.server = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
        cls.addClassCleanup(cls.server.close)
        cls.server.bind(str(cls.address))
        cls.server.settimeout(.1)
        cls.sdl = ctypes.CDLL(str(work/'libsdl.so'))
        library = ctypes.CDLL(str(work/'librumble.so'))
        cls.rumble = library.SDL_GameControllerRumble
        cls.rumble.argtypes = [ctypes.c_void_p, ctypes.c_uint16, ctypes.c_uint16, ctypes.c_uint32]

    def setUp(self):
        environment = patch.dict(os.environ, AM2ARM_RUMBLE_SOCKET=str(self.address))
        environment.start()
        self.addCleanup(environment.stop)

    def tearDown(self):
        self.rumble(2, 0, 0, 0)
        self.rumble(3, 0, 0, 0)
        while self.received() is not None:
            pass

    def received(self):
        try:
            return self.server.recv(16)[0]
        except socket.timeout:
            return None

    def test_controller_with_its_own_vibration_keeps_it(self):
        self.assertEqual(self.rumble(1, 65535, 0, 100), 0)
        self.assertEqual(ctypes.c_int.in_dll(self.sdl, 'played').value, 1)
        self.assertIsNone(self.received())

    def test_other_controllers_are_passed_on_and_stopped(self):
        self.assertEqual(self.rumble(2, 0x8000, 0x4000, 10000), 0)
        self.assertEqual(self.received(), 128)
        # Every frame repeats the call.
        self.rumble(2, 0x8000, 0x4000, 10000)
        self.assertIsNone(self.received())
        self.rumble(2, 0, 0, 0)
        self.assertEqual(self.received(), 0)
        self.rumble(2, 0, 0, 0)
        self.assertIsNone(self.received())

    def test_an_idle_second_controller_does_not_stop_the_first(self):
        self.rumble(2, 65535, 0, 10000)
        self.assertEqual(self.received(), 255)
        self.assertEqual(self.rumble(3, 0, 0, 0), -1)
        self.assertIsNone(self.received())

    def test_missing_launcher_is_not_an_error(self):
        # A new process, since the connection is kept.
        program = ('import ctypes, sys; rumble = ctypes.CDLL(sys.argv[1]).SDL_GameControllerRumble; '
                   'print(rumble(ctypes.c_void_p(2), 65535, 0, 100))')
        library = subprocess.run([sys.executable, '-c', program, str(self.address.with_name('librumble.so'))],
                                 env={'PATH': os.environ['PATH']}, capture_output=True, text=True)
        self.assertEqual(library.stdout.strip(), '-1', library.stderr)


class MotorTests(unittest.TestCase):
    def test_motor_follows_the_game_and_the_firmware_gets_its_voltage_back(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            motor, voltage = root/'value', root/'voltage'
            motor.write_text('0\n')
            voltage.write_text('3300000\n')
            with BrickRumble(root/'rumble.sock', motor, voltage) as rumble, \
                    socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM) as game:
                game.connect(str(root/'rumble.sock'))
                game.send(bytes([128]))
                rumble.poll(now=10)
                self.assertEqual((motor.read_text(), voltage.read_text()), ('1\n', '1905490\n'))
                # A game that stopped talking doesn't leave it running.
                rumble.poll(timeout=0, now=10.7)
                self.assertEqual(motor.read_text(), '0\n')
            self.assertEqual((motor.read_text(), voltage.read_text()), ('0\n', '3300000\n'))
            self.assertFalse((root/'rumble.sock').exists())


if __name__ == '__main__':
    unittest.main()
