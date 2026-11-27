"""Mock every external command; never change the real desktop's settings."""
import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('localsearch', ROOT / 'localsearch.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class LocalSearchTests(unittest.TestCase):
    def test_apply_masks_and_kills_running_indexer(self):
        def value(unit, name):
            return '123' if unit == module.UNITS[0] else '0'
        with patch.object(module, 'property_value', side_effect=value), patch.object(module.subprocess, 'run') as run:
            module.configure()
            calls = [call.args[0] for call in run.call_args_list]
            self.assertEqual(calls[0], ['systemctl', '--user', 'mask', '--now', '--no-block', *module.UNITS])
            self.assertEqual(calls[1], ['systemctl', '--user', 'kill', '--kill-whom=all', '--signal=SIGKILL', module.UNITS[0]])
            self.assertEqual(len(calls), 2)

    def test_reapply_does_not_kill_stopped_services(self):
        with patch.object(module, 'property_value', return_value='0'), patch.object(module.subprocess, 'run') as run:
            module.configure()
            self.assertEqual(run.call_count, 1)

    def test_check_read_only_and_detects_drift(self):
        def value(unit, name):
            return 'masked' if name == 'LoadState' else '0'
        with patch.object(module, 'property_value', side_effect=value), patch.object(module.subprocess, 'run') as run:
            module.configure(check=True)
            run.assert_not_called()
        for state, pid in [('loaded', '0'), ('masked', '123')]:
            with patch.object(module, 'property_value', side_effect=lambda unit, name: state if name == 'LoadState' else pid), patch.object(module.subprocess, 'run') as run:
                with self.assertRaises(SystemExit):
                    module.configure(check=True)
                run.assert_not_called()

    def test_setup_integration(self):
        setup = (ROOT / 'setup.sh').read_text()
        self.assertIn('python3 "$repo/localsearch.py" --check', setup)
        self.assertIn('python3 "$repo/localsearch.py"\n', setup)
