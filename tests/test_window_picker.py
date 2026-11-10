import importlib.util
from importlib.machinery import SourceFileLoader
from pathlib import Path
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
loader = SourceFileLoader('window_picker', str(ROOT / 'bin/.local/bin/window-picker'))
spec = importlib.util.spec_from_loader(loader.name, loader)
module = importlib.util.module_from_spec(spec)
loader.exec_module(module)


class PickerTests(unittest.TestCase):
    def test_focus_valid_target_without_shell_interpolation(self):
        with patch.object(module.subprocess, 'check_output', return_value='[{"address":"0x123","mapped":true,"floating":true}]'), \
             patch.object(module.subprocess, 'run') as run:
            module.focus('0x123')
            self.assertEqual(run.call_count, 2)
            self.assertIn('address:0x123', run.call_args_list[0].args[0][2])
            self.assertNotIn('shell', run.call_args.kwargs)

    def test_tiled_target_floats_in_place_before_raise(self):
        tiled = '[{"address":"0x9","mapped":true,"floating":false,"fullscreen":0,"at":[0,0],"size":[1800,1125]}]'
        with patch.object(module.subprocess, 'check_output', return_value=tiled), \
             patch.object(module.subprocess, 'run') as run:
            module.focus('0x9')
            calls = [c.args[0][2] for c in run.call_args_list]
            self.assertEqual(len(calls), 5)
            self.assertIn('window.float', calls[0])
            self.assertIn('x=1800, y=1125', calls[1])
            self.assertIn('x=0, y=0', calls[2])
            self.assertIn('alter_zorder', calls[-1])

    def test_invalid_or_closed_target_does_not_focus(self):
        with patch.object(module.subprocess, 'check_output', return_value='[]') as query, \
             patch.object(module.subprocess, 'run') as run:
            module.focus('0x123; shutdown')
            query.assert_not_called()
            module.focus('0x123')
            run.assert_not_called()


if __name__ == '__main__':
    unittest.main()
