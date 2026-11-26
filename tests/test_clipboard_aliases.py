from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ClipboardAliasTests(unittest.TestCase):
    def test_aliases_forward_arguments_without_touching_clipboard(self):
        result = subprocess.run(
            ['bash', '--noprofile', '--norc', '-c', '''
shopt -s expand_aliases
source "$1"
wl-copy() { printf 'copy:%s\n' "$*"; }
wl-paste() { printf 'paste:%s\n' "$*"; }
pbcopy --type text/plain
pbpaste --type text
''', 'bash', str(ROOT / 'bash/.config/bash/personal.sh')],
            check=True, capture_output=True, text=True)
        self.assertEqual(result.stdout,
                         'copy:--type text/plain\npaste:--no-newline --type text\n')


if __name__ == '__main__':
    unittest.main()
