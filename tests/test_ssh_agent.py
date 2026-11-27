"""Exercise setup with temporary HOME and mocked desktop commands, never real units."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class AgentSetupTests(unittest.TestCase):
    def test_apply_check_repair_and_remove(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            home = root / 'home'
            home.mkdir()
            repo = root / 'repo'
            shutil.copytree(ROOT, repo, ignore=shutil.ignore_patterns('.git', '__pycache__'))
            # Make the installed-Omarchy prerequisite portable too.
            toggles = root / 'toggles.lua'
            toggles.touch()
            script = repo / 'setup.sh'
            script.write_text(script.read_text().replace(
                '/usr/share/omarchy/default/hypr/toggles.lua', str(toggles)))
            config = home / '.config/hypr/hyprland.lua'
            config.parent.mkdir(parents=True)
            config.write_text('-- existing config\n')
            plugin = home / '.config/omarchy/plugins/io.github.nchudleigh.omac'
            (plugin / 'hypr').mkdir(parents=True)
            (plugin / 'hypr/omac.lua').touch()
            (plugin / 'install.sh').write_text('true\n')
            bindir = root / 'bin'
            bindir.mkdir()
            stub = '''#!/usr/bin/env bash
set -eu
case "${0##*/}" in
gsettings) ;; # No LocalSearch schema in this isolated desktop test.
systemctl)
  echo "$*" >> "$HOME/commands"
  case "$*" in
    *'enable --now gcr-ssh-agent.socket') touch "$HOME/enabled" "$HOME/active" ;;
    *'disable --now gcr-ssh-agent.socket') rm -f "$HOME/enabled" "$HOME/active" ;;
    *'is-enabled gcr-ssh-agent.socket') test -f "$HOME/enabled" ;;
    *'is-active gcr-ssh-agent.socket') test -f "$HOME/active" ;;
  esac ;;
omarchy)
  case "$*" in
    'plugin list') printf '%s\\n' 'io.github.nchudleigh.omac enabled' 'personal.switcher enabled' 'personal.workspace-label enabled' 'omarchy.dock disabled' ;;
    'hyprland workspace layout default') echo floating ;;
  esac ;;
esac
'''
            for name in ('systemctl', 'omarchy', 'hyprctl', 'hyprsunset', 'omarchy-shell', 'gsettings'):
                target = bindir / name
                target.write_text(stub)
                target.chmod(0o755)
            env = dict(os.environ, HOME=str(home), XDG_RUNTIME_DIR=str(root / 'runtime'),
                       SSH_AUTH_SOCK='', PATH=f'{bindir}:{os.environ["PATH"]}')

            def run(*args, success=True):
                result = subprocess.run(['bash', str(script), *args], env=env,
                                        capture_output=True, text=True)
                self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
                return result

            agent = home / '.config/environment.d/90-gcr-ssh-agent.conf'
            agent.parent.mkdir(parents=True)
            agent.write_text('# preexisting config\n')
            first = run()
            self.assertIn('Log out and back in', first.stdout)
            self.assertTrue(agent.is_symlink())
            self.assertEqual(agent.read_text(), 'SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/gcr/ssh\n')
            backups = list((home / '.local/state/dotfiles/backups').glob(
                '*/.config/environment.d/90-gcr-ssh-agent.conf'))
            self.assertEqual(backups[0].read_text(), '# preexisting config\n')
            run()
            run('--check')
            (home / 'active').unlink()
            self.assertIn('not active', run('--check', success=False).stderr)
            run()
            (home / 'enabled').unlink()
            self.assertIn('not enabled', run('--check', success=False).stderr)
            run()
            run('--remove')
            self.assertFalse(agent.is_symlink())
            self.assertFalse((home / 'enabled').exists())
            self.assertIn('stop gcr-ssh-agent.service', (home / 'commands').read_text())
            # Removal must not disable an independently managed agent.
            run()
            agent.unlink()
            agent.write_text('# managed elsewhere\n')
            run('--remove')
            self.assertTrue((home / 'enabled').exists())
            self.assertEqual(agent.read_text(), '# managed elsewhere\n')


if __name__ == '__main__':
    unittest.main()
