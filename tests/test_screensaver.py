import importlib.util
from importlib.machinery import SourceFileLoader
from pathlib import Path
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
loader = SourceFileLoader('quiet_screensaver', str(ROOT / 'omarchy/.config/omarchy/personal/bin/omarchy-screensaver'))
spec = importlib.util.spec_from_loader(loader.name, loader)
module = importlib.util.module_from_spec(spec)
loader.exec_module(module)


class ScreensaverTests(unittest.TestCase):
    def test_single_image_chunking_and_timing(self):
        self.assertEqual(module.INTERVAL, 30)
        result = module.image_sequence('A' * 9000)
        self.assertEqual(result.count('a=T'), 1)
        self.assertIn('m=1', result)
        self.assertIn('m=0', result)
        self.assertEqual(result.count('i=31'), 1)

    def test_locations_are_inside_screen(self):
        for _ in range(100):
            x, y = module.location(100, 40)
            self.assertGreaterEqual(x, 1)
            self.assertLessEqual(x + module.COLUMNS, 98)
            self.assertGreaterEqual(y, 1)
            self.assertLessEqual(y + module.ROWS, 38)

    def test_avoids_previous_location(self):
        with patch.object(module.random, 'randint', side_effect=[1, 1, 2, 2]):
            self.assertEqual(module.location(100, 40, (1, 1)), (2, 2))


if __name__ == '__main__':
    unittest.main()
