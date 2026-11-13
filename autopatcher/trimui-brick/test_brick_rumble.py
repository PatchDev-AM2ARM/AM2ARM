from pathlib import Path
import socket
import tempfile
import unittest

from brick_rumble import BrickRumble


class RumbleTests(unittest.TestCase):
    def test_motor_strength_timeout_and_restore(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            motor, voltage = root/'motor', root/'voltage'
            motor.write_text('0\n')
            voltage.write_text('2200000\n')
            with BrickRumble(root/'rumble.sock', motor, voltage) as rumble:
                client = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
                self.addCleanup(client.close)
                client.connect(str(root/'rumble.sock'))
                client.send(bytes([255]))
                rumble.poll(0, now=10)
                self.assertEqual(motor.read_text().strip(), '1')
                self.assertEqual(voltage.read_text().strip(), '3300000')
                rumble.poll(0, now=10.7)
                self.assertEqual(motor.read_text().strip(), '0')
                client.send(bytes([120]))
                rumble.poll(0, now=11)
                self.assertEqual(motor.read_text().strip(), '1')
                client.send(bytes([0]))
                rumble.poll(0, now=11.1)
                self.assertEqual(motor.read_text().strip(), '0')
                client.send(bytes([255]))
                rumble.poll(0, now=12)
            self.assertEqual(motor.read_text().strip(), '0')
            self.assertEqual(voltage.read_text().strip(), '2200000')
            self.assertFalse((root/'rumble.sock').exists())

    def test_invalid_packet_does_not_start_motor(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            motor, voltage = root/'motor', root/'voltage'
            motor.write_text('0\n'); voltage.write_text('3300000\n')
            with BrickRumble(root/'rumble.sock', motor, voltage) as rumble:
                client = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
                self.addCleanup(client.close)
                client.sendto(b'invalid', str(root/'rumble.sock'))
                rumble.poll(0, now=10)
                self.assertEqual(motor.read_text().strip(), '0')


if __name__ == '__main__':
    unittest.main()
