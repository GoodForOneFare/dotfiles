import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


class LinkTests(unittest.TestCase):
    def test_apply_check_idempotency_remove_and_preservation(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            config = home / '.config/hypr/hyprland.lua'
            config.parent.mkdir(parents=True)
            original = 'require("default.hypr.toggles")\n-- My own setting\n'
            config.write_text(original)
            monitors = home / '.config/hypr/monitors.lua'
            monitors_original = ('local omarchy_monitor_scale = 1.6\n'
                                 'hl.monitor({ output = "", mode = "preferred", position = "auto", '
                                 'scale = omarchy_monitor_scale })\n')
            monitors.write_text(monitors_original)
            helper = home / '.local/bin/window-snap'
            helper.parent.mkdir(parents=True)
            helper.write_text('old helper')
            env = dict(os.environ, HOME=directory)

            def run(*args):
                return subprocess.run(['python3', str(ROOT / 'link.py'), *args], env=env,
                                      check=True, capture_output=True, text=True)

            run()
            body = config.read_text()
            self.assertIn('-- My own setting', body)
            self.assertTrue(body.rstrip().endswith('require("hypr.personal")'))
            self.assertTrue(helper.is_symlink())
            self.assertFalse((home / '.local/bin/__pycache__').exists())
            screens = monitors.read_text()
            self.assertTrue(screens.startswith(monitors_original))  # catch-all kept for externals
            self.assertEqual(screens.count('output = "eDP-1"'), 1)
            self.assertIn('scale = 1.5', screens.splitlines()[-1])
            run('--check')
            run()
            self.assertEqual(config.read_text(), body)
            self.assertEqual(monitors.read_text(), screens)
            monitors.write_text(monitors_original)
            with self.assertRaises(subprocess.CalledProcessError):
                run('--check')  # e.g. Omarchy refreshed monitors.lua
            run()
            self.assertEqual(monitors.read_text(), screens)
            saved = list((home / '.local/state/dotfiles/backups').glob('*/.local/bin/window-snap'))
            self.assertEqual(saved[0].read_text(), 'old helper')
            run('--remove')
            self.assertEqual(config.read_text(), original)
            self.assertEqual(monitors.read_text(), monitors_original)
            self.assertFalse(helper.exists())


class SnapTests(unittest.TestCase):
    def test_scaled_offset_monitor_and_complementary_edges(self):
        # The helper has no extension, so use a source loader explicitly.
        from importlib.machinery import SourceFileLoader
        loader = SourceFileLoader('window_snap', str(ROOT / 'bin/.local/bin/window-snap'))
        spec = importlib.util.spec_from_loader(loader.name, loader)
        module = importlib.util.module_from_spec(spec)
        loader.exec_module(module)
        monitor = dict(id=0, width=2880, height=1800, scale=1.6,
                       transform=0, x=100, y=50, reserved=[0, 20, 0, 0])
        window = dict(address='0x123', monitor=0)
        data = dict(clients=[window], monitors=[monitor], activewindow=window)
        expected = {
            'left-two-thirds': (100, 70, 1200, 1105),
            'right-third': (1300, 70, 600, 1105),
            'left-half': (100, 70, 900, 1105),
            'right-half': (1000, 70, 900, 1105),
            'maximize': (100, 70, 1800, 1105),
        }
        for mode, geometry in expected.items():
            with self.subTest(mode=mode), patch.object(module, 'query', side_effect=lambda name: data[name]), \
                 patch.object(module, 'place') as place, patch('sys.argv', ['window-snap', mode]):
                module.main()
                place.assert_called_once_with(window, *geometry)


if __name__ == '__main__':
    unittest.main()
