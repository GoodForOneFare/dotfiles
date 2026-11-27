from pathlib import Path
import os
import subprocess
import tempfile
import unittest

RC = Path(__file__).resolve().parents[1] / 'bash/.config/bash/personal.sh'


class GitEditorTests(unittest.TestCase):
    def test_vi_overrides_git_and_environment_editors(self):
        with tempfile.TemporaryDirectory() as home:
            env = dict(os.environ, HOME=home, GIT_CONFIG_NOSYSTEM='1',
                       GIT_CONFIG_GLOBAL=os.devnull, GIT_EDITOR='old-editor',
                       EDITOR='other-editor', VISUAL='visual-editor')
            result = subprocess.run(
                ['bash', '--noprofile', '--norc', '-c', '''
source "$1"
git -c core.editor=config-editor var GIT_EDITOR
printf '%s\n' "$EDITOR" "$VISUAL"
''', 'bash', str(RC)], cwd=home, env=env,
                check=True, capture_output=True, text=True)
            self.assertEqual(result.stdout, 'vi\nother-editor\nvisual-editor\n')


if __name__ == '__main__':
    unittest.main()
