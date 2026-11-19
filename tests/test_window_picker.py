import importlib.util
import json
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

    def test_return_to_fullscreen_lowers_only_its_floating_overlays(self):
        for floating in (True, False):
            with self.subTest(floating=floating):
                target = dict(address='0xf', mapped=True, fullscreen=2, floating=floating,
                              workspace={'id': 1})
                overlay = dict(mapped=True, floating=True, fullscreen=0, pinned=False,
                               allowedOverFullscreen=True, workspace={'id': 1})
                clients = [target, dict(overlay, address='0x1'), dict(overlay, address='0x2'),
                           dict(overlay, address='0x3', pinned=True),
                           dict(overlay, address='0x4', workspace={'id': 2}),
                           dict(overlay, address='0x5', mapped=False),
                           dict(overlay, address='0x6', allowedOverFullscreen=False),
                           dict(overlay, address='0x7', floating=False)]
                with (patch.object(module.subprocess, 'check_output', return_value=json.dumps(clients)),
                      patch.object(module.subprocess, 'run') as run):
                    module.focus('0xf')
                    calls = [c.args[0][2] for c in run.call_args_list]
                    self.assertEqual(len(calls), 4)
                    self.assertEqual(calls[0], 'hl.dsp.window.alter_zorder({window="address:0x2", mode="bottom"})')
                    self.assertEqual(calls[1], 'hl.dsp.window.alter_zorder({window="address:0x1", mode="bottom"})')
                    self.assertEqual(calls[2], 'hl.dsp.focus({window="address:0xf"})')
                    self.assertEqual(calls[3], 'hl.dsp.window.alter_zorder({window="address:0xf", mode="top"})')

    def test_client_only_fullscreen_does_not_lower_other_windows(self):
        clients = [dict(address='0xf', mapped=True, fullscreen=0, fullscreenClient=2, floating=True),
                   dict(address='0x1', mapped=True, floating=True, allowedOverFullscreen=True)]
        with (patch.object(module.subprocess, 'check_output', return_value=json.dumps(clients)),
              patch.object(module.subprocess, 'run') as run):
            module.focus('0xf')
            self.assertEqual(run.call_count, 2)

    def test_invalid_or_closed_target_does_not_focus(self):
        with patch.object(module.subprocess, 'check_output', return_value='[]') as query, \
             patch.object(module.subprocess, 'run') as run:
            module.focus('0x123; shutdown')
            query.assert_not_called()
            module.focus('0x123')
            run.assert_not_called()


if __name__ == '__main__':
    unittest.main()
