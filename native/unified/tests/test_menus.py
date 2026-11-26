import unittest

from route import choose_backend


class Layout(unittest.TestCase):
    def test_supported_ports_use_session_and_direct_boards_fall_back(self):
        def unknown():
            raise RuntimeError('unknown board')
        def no_session(env):
            raise RuntimeError('missing socket')
        self.assertEqual(choose_backend('ports', {}, lambda e:e, unknown), 'ports')
        self.assertEqual(choose_backend('ports', {}, no_session, lambda:'flip'), 'direct')
        self.assertEqual(choose_backend('spruce', {}, no_session, lambda:'smartpros'), 'direct')
        with self.assertRaisesRegex(RuntimeError, 'compatibility.txt'):
            choose_backend('ports', {}, no_session, unknown)
