import importlib.util
from importlib.machinery import SourceFileLoader
import os
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
loader = SourceFileLoader('hot_corner', str(ROOT / 'bin/.local/bin/hot-corner'))
spec = importlib.util.spec_from_loader(loader.name, loader)
module = importlib.util.module_from_spec(spec)
loader.exec_module(module)


class CornerTests(unittest.TestCase):
    def test_scaled_corner_and_monitor_offsets(self):
        monitor = dict(width=2880, height=1800, scale=1.5, x=100, y=50)
        self.assertTrue(module.in_corner(dict(x=100, y=1249), [monitor]))
        self.assertFalse(module.in_corner(dict(x=106, y=1249), [monitor]))
        self.assertFalse(module.in_corner(dict(x=100, y=1240), [monitor]))
        self.assertFalse(module.in_corner(dict(x=99, y=1249), [monitor]))
        self.assertFalse(module.in_corner(dict(x=100, y=1250), [monitor]))
        self.assertFalse(module.in_corner(dict(x=100, y=1249), [dict(monitor, disabled=True)]))

    def test_rotated_display(self):
        monitor = dict(width=2880, height=1800, scale=1.5, x=0, y=0, transform=1)
        self.assertTrue(module.in_corner(dict(x=0, y=1919), [monitor]))
        self.assertFalse(module.in_corner(dict(x=0, y=1199), [monitor]))

    def test_preserve_manual_claims_and_cleanup_own_marker(self):
        with tempfile.TemporaryDirectory() as directory:
            marker = Path(directory) / 'state/stay-awake'
            lease = Path(directory) / 'runtime/lease.json'
            owner = module.StayAwakeLease(marker, lease)
            self.assertTrue(owner.acquire())
            owner.release()
            self.assertFalse(marker.exists())
            marker.touch()
            self.assertFalse(owner.acquire())
            owner.release()
            self.assertTrue(marker.exists())
            marker.unlink()
            self.assertTrue(owner.acquire())
            stat = marker.stat()
            # A manual Stay Awake command touches the marker; our exit must
            # not cancel the newer user's claim.
            os.utime(marker, ns=(stat.st_atime_ns, stat.st_mtime_ns + 1_000_000))
            owner.release()
            self.assertTrue(marker.exists())
            self.assertFalse(lease.exists())

    def test_recover_after_crash(self):
        with tempfile.TemporaryDirectory() as directory:
            marker = Path(directory) / 'stay-awake'
            lease = Path(directory) / 'lease.json'
            self.assertTrue(module.StayAwakeLease(marker, lease).acquire())
            module.StayAwakeLease(marker, lease).release()
            self.assertFalse(marker.exists())


if __name__ == '__main__':
    unittest.main()
