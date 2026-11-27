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
    def settings(self, recursive, single='@as []'):
        def read(*args):
            if args[1] == 'list-schemas':
                return module.SCHEMA
            return recursive if args[-1] == 'index-recursive-directories' else single
        return read

    def test_apply_stops_then_sets_then_starts(self):
        with patch.object(module, 'command', side_effect=self.settings("['$HOME']", "['/tmp']")), patch.object(module.subprocess, 'run') as run:
            module.configure()
            calls = [call.args[0] for call in run.call_args_list]
            self.assertEqual(calls[0], ['systemctl', '--user', 'stop', 'localsearch-3.service'])
            self.assertEqual(calls[-1], ['systemctl', '--user', 'start', 'localsearch-3.service'])
            self.assertEqual(len(calls), 4)
            self.assertEqual(calls[2][-1], '[]')
            self.assertNotIn('$HOME', calls[1][-1])

    def test_idempotent_and_check_read_only(self):
        expected = repr([str(Path.home() / name) for name in module.FOLDERS])
        with patch.object(module, 'command', side_effect=self.settings(expected)), patch.object(module.subprocess, 'run') as run:
            module.configure()
            module.configure(check=True)
            run.assert_not_called()
        with patch.object(module, 'command', side_effect=self.settings("['$HOME']")), patch.object(module.subprocess, 'run') as run:
            with self.assertRaises(SystemExit):
                module.configure(check=True)
            run.assert_not_called()

    def test_missing_schema_skipped(self):
        with patch.object(module, 'command', return_value=''), patch.object(module.subprocess, 'run') as run:
            module.configure()
            module.configure(check=True)
            run.assert_not_called()

    def test_setup_integration(self):
        setup = (ROOT / 'setup.sh').read_text()
        self.assertIn('python3 "$repo/localsearch.py" --check', setup)
        self.assertIn('python3 "$repo/localsearch.py"\n', setup)
