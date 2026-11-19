---
name: dotfiles
description: >
  The user's personal Omarchy/Hyprland desktop layer, kept in the dotfiles repo
  ~/src/github.com/GoodForOneFare/dotfiles and symlinked into $HOME. Use for ANY
  change to this machine's desktop, window management, keybindings, window
  switcher, snapping, display scale, wallpaper, workspace label, dock, night
  light, screensaver, hot corner, or Ghostty settings, and for committing or
  pushing dotfiles. Use alongside the omarchy skill; this one decides where
  changes are saved and how they are validated and pushed.
---

# Personal dotfiles layer

Repo: `~/src/github.com/GoodForOneFare/dotfiles` (GitHub `GoodForOneFare/dotfiles`,
branch `main`). **Read its `README.md` before changing anything**: it documents
every component, why each is built the way it is, and its limits.

## Where changes go

Every customization lives in the repo, never only in `~/.config`. Repo files are
symlinked into `$HOME` by `link.py` (Stow-shaped packages: `hypr/`, `bin/`,
`omarchy/`, `systemd/`, `ghostty/`, `pi/`), so editing the repo edits the live file.

- Hyprland: `hypr/.config/hypr/personal/*.lua`, loaded by `personal.lua`, which
  `link.py` requires from the **end** of `~/.config/hypr/hyprland.lua`, after
  Omarchy defaults and the omac plugin. Add a module there, and a `require` in
  `personal.lua`. Don't put overrides in Omarchy's stock user files
  (`bindings.lua`, `input.lua`, `looknfeel.lua`).
- Files we don't own get exactly **one managed line** from `link.py`, and nothing
  else changes: the loader in `hyprland.lua`, the `eDP-1` 1.5x rule in
  `monitors.lua`, the `personal.conf` include in `~/.config/ghostty/config`
  (see `TAILS` in `link.py`). Follow that pattern for new cases.
- Shell plugins: `omarchy/.config/omarchy/plugins/<id>/` (`personal.switcher`,
  `personal.workspace-label`). Helpers: `bin/.local/bin/`. Services:
  `systemd/.config/systemd/user/`.
- Omarchy state set by command (wallpaper, floating workspace default, dock
  disabled) is applied by `setup.sh` and verified by `setup.sh --check`.
  Anything new of that kind needs both.
- New file in a new package directory: add the package to `link.py`.
- Never edit `/usr/share/omarchy`. Reading it is the way to learn how Omarchy works.

## Workflow

1. Read the README section and the files involved. Check existing bindings
   before rebinding (`hyprctl -j binds`), and tell the user what a key did before.
2. Edit in the repo. New linked files: run `python3 link.py`.
3. Apply and validate:
   - Hyprland: `hyprctl reload && hyprctl configerrors` (must print nothing).
   - Shell plugin QML/JS: `omarchy restart shell` (reliable; hot-reload can keep
     cached components), then check the newest
     `/run/user/$UID/quickshell/by-id/*/log.log` for errors.
   - Ghostty: `ghostty +validate-config`, then `omarchy restart terminal`.
   - User services: `systemctl --user daemon-reload && systemctl --user restart <unit>`.
4. Run the checks:
   ```sh
   python3 -m unittest discover -s tests -v
   node tests/test_switcher_model.js
   lua tests/test_screensaver_bindings.lua
   bash -n setup.sh && ./setup.sh --check
   git diff --check
   ```
   Add or extend a test for new logic.
5. Update `README.md` for behavior changes.
6. **Commit and push** to `origin main` when the change is done and validated.
   This is the user's standing workflow. For changes the user has to judge by eye
   (colors, sizes, feel), apply them, ask, then commit once they approve.
   Before committing, check `git status` for stray files (`__pycache__` is
   ignored) and make sure nothing secret is staged.

## Hard-won rules

- **Never send simulated input (`wtype`, focus changes, test windows) while
  the user may be using the desktop.** Keystrokes go to whatever has focus, which
  may be the user's terminal. Prefer state checks (`hyprctl -j ...`,
  `omarchy-shell personal.switcher state`). If live input is essential, ask
  first. Screenshots (`grim`) are passive and fine.
- Ghostty config has **no inline comments**: a trailing `# ...` becomes part of
  the value.
- Display scale must be in `~/.config/hypr/monitors.lua`: Omarchy's wake and
  clamshell helper reads only that file and reapplies it on every wake.
- Tiled windows always render **below** floating ones. Workspaces use Omarchy's
  floating layout (`omarchy hyprland workspace layout ...`); the switcher floats a
  tiled pick in place before raising it.
- The switcher modal holds keyboard focus, so Super/Alt release is caught
  in-modal (`Switcher.qml`), not just by Hyprland release binds. Right Alt is
  push-to-talk dictation (voxtype): don't bind it.
- Omarchy's dock is disabled; Super+M (minimize to dock) is unbound for that reason.
- Caps Lock is Hyper (`MOD3`): Caps+1/2/Left/Right/Space snap windows.
- No `sudo` from the agent. Never reboot, log out, or restart the desktop
  session without asking; `omarchy restart shell` or `terminal` is fine.
- Omarchy updates can change the APIs this relies on: the switcher inherits the
  stock menu component. After `omarchy update`, rerun the checks and
  `./setup.sh --check`.
