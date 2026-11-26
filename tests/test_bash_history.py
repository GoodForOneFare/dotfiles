import os
from pathlib import Path
import subprocess
import tempfile
import unittest

RC = Path(__file__).resolve().parents[1] / 'bash/.config/bash/personal.sh'


class BashHistoryTests(unittest.TestCase):
    def test_limits_prompt_preservation_and_idempotency(self):
        for initial in ('unset PROMPT_COMMAND',
                        "PROMPT_COMMAND='printf scalar'",
                        "PROMPT_COMMAND=('printf first' 'printf second')"):
            with self.subTest(initial=initial), tempfile.TemporaryDirectory() as home:
                script = initial + '''
original_hooks=("${PROMPT_COMMAND[@]}")
source "$1"
declare -p PROMPT_COMMAND > "$HOME/before"
source "$1"
declare -p PROMPT_COMMAND > "$HOME/after"
cmp "$HOME/before" "$HOME/after"
[[ $HISTSIZE == 10000 && $HISTFILESIZE == 10000 ]]
shopt -q histappend
[[ ${PROMPT_COMMAND[0]} == _dotfiles_sync_history ]]
[[ ${#PROMPT_COMMAND[@]} == "$2" ]]
for i in "${!original_hooks[@]}"; do
  [[ ${PROMPT_COMMAND[i+1]} == "${original_hooks[i]}" ]]
done
'''
                count = {'unset PROMPT_COMMAND': 1,
                         "PROMPT_COMMAND='printf scalar'": 2}.get(initial, 3)
                result = subprocess.run(
                    ['bash', '--noprofile', '--norc', '-e', '-c', script,
                     'bash', str(RC), str(count)],
                    env=dict(os.environ, HOME=home, HISTFILE=home + '/history'),
                    capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)

    def test_sync_preserves_command_exit_status(self):
        with tempfile.TemporaryDirectory() as home:
            result = subprocess.run(
                ['bash', '--noprofile', '--norc', '-c', '''
source "$1"
(exit 7)
_dotfiles_sync_history
[[ $? == 7 ]]
''', 'bash', str(RC)],
                env=dict(os.environ, HOME=home, HISTFILE=home + '/history'),
                capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)

    def test_two_running_shells_share_history(self):
        with tempfile.TemporaryDirectory() as home:
            env = dict(os.environ, HOME=home, HISTFILE=home + '/history')
            args = ['bash', '--noprofile', '--norc', '-c']
            first = subprocess.Popen(args + ['''
source "$1"
set -o history
history -c
history -s from_shell_A
_dotfiles_sync_history
printf 'ready\n'
read -r resume
_dotfiles_sync_history
history
''', 'bash', str(RC)], env=env, stdin=subprocess.PIPE,
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            try:
                self.assertEqual(first.stdout.readline().strip(), 'ready')
                second = subprocess.run(args + ['''
source "$1"
set -o history
history -c
history -s from_shell_B
_dotfiles_sync_history
''', 'bash', str(RC)], env=env, check=True,
                    capture_output=True, text=True)
                output, error = first.communicate('\n', timeout=5)
                self.assertEqual(first.returncode, 0, error)
                self.assertIn('from_shell_A', output)
                self.assertIn('from_shell_B', output)
                saved = Path(env['HISTFILE']).read_text()
                self.assertIn('from_shell_A', saved)
                self.assertIn('from_shell_B', saved)
            finally:
                if first.poll() is None:
                    first.kill()
                    first.communicate()


if __name__ == '__main__':
    unittest.main()
