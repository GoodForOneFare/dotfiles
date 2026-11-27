# Personal Omarchy desktop layer

A small, user-owned layer on top of Omarchy and omac. No system files, device
certificates, browser profiles, account credentials, or package upgrades.

## Apply on an existing Lua-based Omarchy desktop

```sh
git clone https://github.com/GoodForOneFare/dotfiles ~/src/github.com/GoodForOneFare/dotfiles
cd ~/src/github.com/GoodForOneFare/dotfiles
./setup.sh
```

Run as your normal user in an active Hyprland session, **not with sudo**.
Requires Python 3, Git, Omarchy, Hyprland, systemd and hyprsunset. The current tested baseline is
Omarchy **4.5.0-3**, Hyprland **0.56.2-4** (Lua), Ghostty **1.4.0-1**.
The original layer was also validated on Omarchy 4.0.4.
Recheck compatibility before applying on a newer desktop version.

The script:

1. Symlinks the personal modules, all-day hyprsunset profile, and `window-snap`
   helper into your home.
2. Adds a single final `require("hypr.personal")` line to your existing
   `~/.config/hypr/hyprland.lua`, preserving everything else.
3. Installs omac if missing, pinned to
   `fe434579e7fa9dc0fa3d0f87905cf4fd057fd4f1`, and enables it. An existing omac
   checkout is **never reset**; a different revision produces a warning.
4. Reloads Hyprland and checks configuration errors, then restarts the stock
   user-session hyprsunset service to read the 3000 K profile. It never restarts
   your desktop session or reboots.
5. Enables the desktop SSH agent socket, with its environment configuration
   linked from this repo. Log out and back in to make it available everywhere.

Existing replaced files are backed up under `~/.local/state/dotfiles/backups/`.
On validation failure, inspect that backup and restore the previous configs;
the script does not claim to automatically undo all plugin installation effects.

The directories use GNU Stow's package layout (`hypr/`, `bin/`, ...), but the
included Python linker does not require Stow to be installed. The `omarchy/`
package contains private screensaver assets and its replacement animation program.
The `systemd/` package contains the session-scoped hot-corner service.

## SSH agent

Setup enables and starts `gcr-ssh-agent.socket`, the same desktop agent used by
`omarchy setup security ssh-agent`. The `systemd/` package links
`~/.config/environment.d/90-gcr-ssh-agent.conf`, setting
`SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/gcr/ssh`. Passphrase-protected keys can use a
graphical prompt with optional keyring storage. No keys or passphrases belong
in this repository; setup does not generate or load keys.

**Log out and back in** after the first setup. To use the agent immediately in
an existing terminal (after running setup):

```sh
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gcr/ssh"
ssh-add ~/.ssh/git_signing  # Or your existing SSH key
ssh-add -l
```

`./setup.sh --check` verifies the linked configuration and that the socket is
both enabled and active; it does not require the current terminal to have the
new environment or any keys loaded. Reapplying setup is safe. `--remove`
disables/stops the socket and service only if the environment file is still our
symlink, then removes that link. It does not delete keys or keyring entries;
log out and back in after removal to clear the old session environment.

## File search indexing

Setup **disables GNOME LocalSearch background indexing** (formerly Tracker, used
by Nautilus/Files). On this development machine a whole-home index reached four
million files; narrowing its scope still left the old database consuming a CPU
core and about 17 GB of RAM. No personal files or index databases are deleted.

`localsearch.py` masks and stops the user services `localsearch-3.service`,
`localsearch-control-3.service`, and `localsearch-writeback-3.service`. Masks
prevent automatic/D-Bus activation, including when Files is opened. If an indexer
is still running, setup kills it rather than waiting for its unresponsive
90-second graceful stop. Ordinary file browsing still works; indexed/content
search and metadata-dependent features in Files may be unavailable.

`./setup.sh --check` verifies the services are masked and have no main process,
without changing anything. Reapplying is safe. Like other command-managed
preferences, masks persist after `--remove`. To deliberately re-enable indexing:

```sh
systemctl --user unmask localsearch-3.service localsearch-control-3.service localsearch-writeback-3.service
systemctl --user start localsearch-3.service
```

The previous limited-scope GSettings remain on this machine, so re-enabling
does not restore whole-home indexing. Reapplying setup disables indexing again.

## Git editor

The personal Bash config exports `GIT_EDITOR=vi`, so Git uses `vi` for commit
messages and other editing without changing `EDITOR` or `VISUAL` for other
programs. This takes precedence over Git's `core.editor`. New interactive Bash
shells load it automatically through `~/.bashrc`; in an existing shell, run:

```bash
source ~/.config/bash/personal.sh
git var GIT_EDITOR  # vi
```

## Bash clipboard aliases and shared history

`bash/.config/bash/personal.sh`, linked to `~/.config/bash/personal.sh`, defines
`pbcopy` as `wl-copy` and `pbpaste` as `wl-paste --no-newline`. These use the
Wayland clipboard; `wl-clipboard` must be installed (it ships on this box).

`link.py` adds one guarded source line at the end of `~/.bashrc`, preserving
all existing shell configuration. New interactive Bash shells load the aliases;
for an already-open shell, run `source ~/.config/bash/personal.sh`.
Removing the layer removes only its source line and linked file.

```bash
printf 'hello' | pbcopy
pbpaste > file.txt
```

The same file sets `HISTSIZE` and `HISTFILESIZE` to **10,000** and enables
`histappend`. Before each prompt it appends new commands with `history -a`, then
reloads the shared file with `history -c; history -r` to avoid stale incremental
read offsets when terminals interleave commands. History is only cleared after
a successful append to a readable history file. Existing scalar/array
`PROMPT_COMMAND` hooks and the preceding command's
exit status are preserved; re-sourcing does not duplicate the history hook.
Existing shells must source this file too; history refreshes at the next prompt,
not while sitting idle. Omarchy's default was 32,768; this explicitly sets the
requested 10,000 limit. Tests use temporary history files, never your history.

## Mac-style arrows and Back / Forward

**Super+Left/Right** goes to line start/end (Home/End), and **Super+Up/Down**
goes to document start/end (Ctrl+Home/End). Add **Shift** to select to the same
boundary. **Super+[ / Super+]** sends **Alt+Left/Right** for Back/Forward in
Chrome, Slack and other apps supporting history navigation.

These replace Omarchy's Super+arrow window focus and Super+Shift+arrow window
swapping, and match omac's navigation conventions even when omac is disabled.
Ctrl/Alt arrow chords and shifted bracket shortcuts are unchanged. In terminals,
only plain Super+Left/Right sends Home/End; document, selection and history
shortcuts do nothing, matching omac's terminal safety behavior. Without a text
field focused, GUI apps interpret Home/End themselves (often page scrolling).
On the built-in keyboard, the physical left Alt key acts as Super.

**Super+L** sends **Ctrl+L**, selecting the address bar in Chrome and clearing
the display in shells. It replaces the forward workspace-layout cycle;
**Super+Alt+L** still cycles layouts backward and **Super+Ctrl+L** still locks.

**Super+T** sends **Ctrl+T** for New Tab in GUI apps, replacing the focused
window's floating/tiling toggle. It is suppressed in terminals, where Ctrl+T
transposes characters rather than opening a tab. Other T chords are unchanged.

Implementation: `hypr/.config/hypr/personal/navigation.lua`, required by
`personal/windows.lua` after upstream configuration. Run
`lua tests/test_navigation_bindings.lua` for the passive regression test.

## Layer order

```text
Omarchy defaults -> normal user configs -> omac/toggles -> hypr.personal
```

The personal layer loads automatically at login and every config reload.
The loader belongs at the **end** of the main config so omac cannot override
our preferences. We do not store or replace Omarchy's main config template.
Do not repeat these overrides in the regular input/bindings/looknfeel files.

## Files to edit

```text
hypr/.config/hypr/personal.lua
hypr/.config/hypr/personal/
  nightlight.lua   # Start the stock hyprsunset user service at each login
  appearance.lua   # Zero gaps/borders, opaque windows, 50% scrolling columns
  input.lua        # Hyper, scroll speed 0.7, fingers-down scrolls down, no pointer warps
  windows.lua      # Floating defaults and Rectangle-style snapping
  editing.lua      # Native Alt+Backspace in terminals; Ctrl+Backspace elsewhere
  screensaver.lua  # Quiet animation substitution and modifier-key dismissal
  hotcorner.lua    # Start the bottom-left Stay Awake watcher at login
  switcher.lua     # Super+Tab: searchable window selection
hypr/.config/hypr/hyprsunset.conf  # One 00:00 profile: 3000 K all day
bin/.local/bin/window-snap
```

The symlinks mean edits in this repo are the live files. After editing:

```sh
hyprctl reload
hyprctl configerrors
```

Caps Lock is a held **Hyper/Mod3 modifier**, no longer Compose:

| Shortcut | Snap position |
|---|---|
| Caps+1 | Left two-thirds |
| Caps+2 | Right third |
| Caps+Left | Left half |
| Caps+Right | Right half |
| Caps+Space | Fill display's usable area (floating, not fullscreen) |

Snapping respects the target display's scale and reserved space. It does not
change other windows. New windows float; to float already-open windows:

```sh
python3 ~/.local/bin/window-snap float-existing
```

This preserves geometry where possible, moving off-screen columns back into the
work area. It is deliberately not run on every setup, so reapplying your dotfiles
does not rearrange your windows. Alt+Backspace's exact word boundary remains
application-dependent.

Nightlight is 3000 K all day, with no scheduled return to neutral. The Lua layer
starts `hyprsunset.service` at login; the service itself is not globally enabled.
The stock Nightlight toggle can temporarily override the temperature and uses
4000 K when turned back on. Reapplying setup or logging in restores the profile.

## Searchable window picker

**Super+Tab** replaces next-workspace navigation with a visual window picker,
using a personal plugin that inherits Omarchy 4.5's theme-aware menu surface.

- Hold **Super** and press **Tab** repeatedly to advance through windows.
- Release **Super** to focus and raise the highlighted window automatically.
- **Super+Shift+Tab** goes backward (replaces previous-workspace navigation).
- **Super+backtick (`)**, or the shifted tilde key, cycles instances of the
  **highlighted app**, not the app originally focused, and hides all other
  apps' windows. Super+Tab restores the full list and resumes cycling from the
  highlighted window. Outside the switcher it
  starts with instances of the currently focused app. These replace the Quake
  console and move-to-Quake-console bindings.
- Escape cancels without changing focus.
- **Alt+Tab**, **Alt+Shift+Tab** and **Alt+`** do the same, released with
  either Alt (replaces Omarchy's Alt+Tab focus-next/raise). Right Alt alone
  stays push-to-talk dictation: only left Alt has a compositor release listener,
  while the open modal handles both.

The switcher is keyboard-only: pointer movement, clicks (including outside the
card), and scrolling do not select, activate, or dismiss anything. A pointer
shield covers only the personal switcher's surface; other menus are unchanged.
The personal input config disables Hyprland's automatic pointer warping, so
switching windows leaves the pointer where you put it (also for other
keyboard-driven focus changes).

No typing, arrows, or Enter are needed. Only windows on the workspace where the
switcher opens are listed, in recent-use order, with the previous window on that
workspace highlighted first. Same-app cycling stays within that workspace too;
restoring the full list never brings in windows from other workspaces. Windows
behind a fullscreen app remain listed, even when Hyprland temporarily marks them as
unable to receive input. Super+1..9 still
selects workspaces; Super+Ctrl+Tab returns to the former workspace.


The plugin lives in `omarchy/.config/omarchy/plugins/personal.switcher/` and is
enabled by setup. Native Hyprland global shortcuts preserve press/release
ordering without spawning processes for each keypress. A raw Hyprland
`input.keyboard.key` listener detects either Super key (and left Alt) releasing
before keybind matching or Wayland focus routing. This avoids missed releases
when rapidly switching, regardless of Shift/Ctrl state or whether the modal
has taken keyboard focus yet. The modal's focused input also forwards release
events as a fallback, including right Alt. Fast Super taps queue selection
until the window snapshot is ready. Run `lua tests/test_switcher_bindings.lua`
for passive release-order and rapid-chord regression checks. The small `window-picker` Python
helper validates, focuses, and raises the chosen address. Tiled windows always
render below floating ones, so a tiled selection (for example, a window opened
before the float-all rule applied) is first floated in place, keeping its
current position and size. Returning to a fullscreen window lowers unpinned
floating overlays on that workspace before focusing it, so previously selected
apps cannot obscure it. Its fullscreen state is preserved; pinned windows and
other workspaces are left alone. `personal/foreground.lua` also applies this
cleanup when a fullscreen app gains focus outside the switcher (for example,
clicking a Slack notification), so old floating overlays cannot hide it. It also
raises ordinary floating windows when they gain focus: opening a Chrome tab
from a Slack link must not leave the focused browser hidden behind Slack,
whether or not Slack is fullscreen. On `window.open`, a focused new tiled
window is floated in place and raised after layout initialization. This handles
Chrome Ctrl+N on a saved scrolling workspace, where the static float rule can
still leave the newcomer tiled below existing floats. Its position and size are
restored after floating. Existing tiled windows are left alone on ordinary focus
changes. It does not force focus when an app never requests activation or change
fullscreen state. This runs
after focus settles and does nothing if focus has already moved elsewhere.

The hook also remembers the last explicitly focused window per workspace,
seeded from compositor MRU on reload. Hyprland 0.56.2 automatically focuses a
workspace's fullscreen owner when returning, even when a floating browser was
last used above it. For that workspace-change focus reason only, the hook
restores the remembered mapped, unpinned, non-fullscreen float on that same
workspace instead of lowering it. Explicitly choosing the fullscreen app still
reveals it normally. Using the switcher on a different workspace never changes
that remembered choice; stale/closed/moved targets and later focus changes are
ignored. No fullscreen state is changed.
Run `lua tests/test_foreground.lua` for the mocked focus/stacking regression test.
No extra package or daemon is required, and no packaged UI source is modified.

### Floating workspace layout

Omarchy 4.5 added per-workspace layouts (dwindle, scrolling, floating). A
workspace on a tiled layout opens new windows **tiled**, beneath every floating
window, which the float-all window rule alone does not prevent. `setup.sh`
therefore sets the default layout to floating with
`omarchy hyprland workspace layout default floating`, and `--check` verifies it.
A workspace that already has windows keeps its own saved layout: switch it with
**Super+Alt+L** (cycle backward, or `omarchy hyprland workspace layout toggle`)
until it reports
floating. Saved layouts live in `~/.local/state/omarchy/workspace-layouts/`.

Omarchy's **dock** (the launcher bar at the bottom middle) appears only on
floating workspaces. `setup.sh` disables it completely with
`omarchy plugin disable omarchy.dock` (recorded in `shell.json` under
`disabledPlugins`), and `--check` verifies it. Because Super+M minimizes a
window *to the dock*, the layer unbinds Super+M so no window can be lost.
Re-enable with `omarchy plugin enable omarchy.dock`.

Focus failures from the switcher are logged to
`~/.local/state/dotfiles/window-picker.log`.

The plugin depends on Omarchy 4.5's menu component API: revalidate on upgrades.
Run `node tests/test_switcher_model.js` for MRU navigation, wraparound,
highlighted-app cycling, duplicate titles and markup-safety checks.
`python3 tests/check_switcher_release.py` is an opt-in live regression test using
wtype to release both Super keys: it briefly switches windows and restores focus.
Do not run this test while typing or with an authentication prompt focused. After
editing symlinked plugin source, `omarchy restart shell` reliably clears the
shell's component cache (this does not restart the desktop session).

## Black wallpaper

`omarchy/.config/omarchy/personal/backgrounds/black.png` is a solid black
2880×1800 PNG. `setup.sh` applies it with `omarchy theme bg set`, Omarchy's
supported background command; the choice persists across reboots. Changing the
theme or cycling backgrounds (`omarchy theme bg next`) picks a theme wallpaper
instead. Rerun `./setup.sh` or
`omarchy theme bg set ~/.config/omarchy/personal/backgrounds/black.png` to
restore black.

Each display also shows a dim gray **"Workspace N"** label in the center of the
desktop, updated live as you switch workspaces. It is a small shell plugin
(`omarchy/.config/omarchy/plugins/personal.workspace-label/`) on the layer just
above the wallpaper: windows always cover it, and clicks pass through to the
desktop. Special (scratchpad) workspaces keep the underlying workspace's label.
Change the color or size in `Label.qml`; disable with
`omarchy plugin disable personal.workspace-label`.

## Ghostty split dimming

`ghostty/.config/ghostty/personal.conf` makes the focused split obvious,
iTerm-style: inactive splits get an 18% neutral-gray wash
(`unfocused-split-fill = #808080`, `unfocused-split-opacity = 0.82`) and a
slightly brighter divider. Ghostty's default fill is the background color,
which is nearly invisible on dark themes. Lower the opacity for stronger dimming.

`link.py` appends one include line, last, to `~/.config/ghostty/config` so these
settings override the theme; nothing else in that file changes. Ghostty has no
inline comments, so that line is untagged. Apply edits with
`omarchy restart terminal`; check with `ghostty +validate-config`.

## Pi agent skill

`pi/.pi/agent/skills/dotfiles/SKILL.md` is linked to
`~/.pi/agent/skills/dotfiles/`, so every new pi session knows this layer exists.
Pi lists only the skill's name and description up front and reads the full
instructions when a task involves the desktop or these dotfiles. To force it,
use `/skill:dotfiles <request>`. The skill covers where changes go, how to
apply and validate them, the commit-and-push workflow, and lessons learned. It
points back to this README for details, so update both when behavior changes.
Run `/reload` in an open session after editing it.

The stock `omarchy` skill is a symlink into `/usr/share/omarchy`, which updates
replace, so it isn't edited. Instead, `pi/.pi/agent/AGENTS.md`, linked as the
user-wide `~/.pi/agent/AGENTS.md`, tells every session to load `dotfiles`
whenever it uses `omarchy` or edits `~/.config`. It is kept to a few lines
because it loads in every session.

## Quiet screensaver

The stock Omarchy launcher and idle/lock timings are unchanged. For terminals
launched by Hyprland, the layer prepends a private directory containing **only**
`omarchy-screensaver` to PATH. It replaces the animation executable without
modifying `/usr/share/omarchy`, the idle service, or the lock-screen plugin.

The replacement targets **Ghostty** (or Kitty): a black screen with one small,
stationary green Shopify bag, relocated every 30 seconds. It uses Kitty graphics
protocol, not a continuous text animation. Other terminal emulators may not
render the image; choose Ghostty for this setup.

Ordinary typing exits, as does pressing a standalone Super/Windows, Alt, Ctrl,
Shift, or Caps/Hyper key. Modifier handlers pass through unchanged when the
screensaver isn't focused and close only `org.omarchy.screensaver` windows.
They do not dismiss or bypass authentication. Switching focus away also exits.

Preview with `omarchy launch screensaver force`. This is a visual screensaver,
**not a lock screen**. The existing automatic lock deadline remains owned by
Omarchy. The current timings are 150 seconds for the screensaver, 300 for lock.

The bag icon is from Font Awesome Brands (Shopify), CC BY 4.0, Fonticons:
https://github.com/FortAwesome/Font-Awesome/blob/7.x/svgs/brands/shopify.svg
https://creativecommons.org/licenses/by/4.0/
It is recolored green and rasterized to PNG. Its SVG source and attribution are
included. No image conversion tools are required at runtime.

## Bottom-left keep-awake hot corner

Park the pointer in the bottom-left **6 logical pixels** of any display to
prevent Omarchy's screensaver, automatic lock, and idle display blanking. Moving
out releases the request. This does not prevent manual lock, explicit suspend,
or lid-close sleep; logind's separate idle action is currently disabled.

The small session-scoped `dotfiles-hot-corner.service` polls cursor position
outside the compositor event loop. It creates Omarchy's standard Stay Awake
marker only if absent, and removes only its own unchanged marker. Stay Awake
set manually before entering, or reasserted manually while inside, is preserved.
Manual Allow Idle while inside is respected until leaving and reentering.
Normal service stop and restart clean up its own request; an ExecStopPost helper
also handles a crashed process. No global systemd enablement is needed: the
personal Lua layer starts the service at login, and setup starts it now.

```sh
systemctl --user status dotfiles-hot-corner.service
systemctl --user stop dotfiles-hot-corner.service   # Stop for this session
systemctl --user start dotfiles-hot-corner.service
```

Code: `bin/.local/bin/hot-corner`; unit:
`systemd/.config/systemd/user/dotfiles-hot-corner.service`.

## Check, reapply, or disable

```sh
./setup.sh --check    # Validate links, loader, plugin enabled, and config errors
./setup.sh            # Safe to repeat; repair links/loader after moving the repo
./setup.sh --remove   # Stop the corner watcher, remove our links/loader, reload
```

Removing the personal layer stops the hot-corner watcher and releases its own
Stay Awake request. It also stops hyprsunset and removes our all-day profile
symlink (the preexisting file is in the setup backup). It leaves **omac installed
and enabled**. To also
remove omac, run its uninstaller first, then remove the plugin:

```sh
bash ~/.config/omarchy/plugins/io.github.nchudleigh.omac/uninstall.sh
omarchy plugin remove io.github.nchudleigh.omac
```

A config reset (`omarchy refresh hyprland`) can remove the loader; reapply with
`./setup.sh`. Ordinary edits to defaults remain upstream-owned. If a future
upgrade changes the Lua API, review this layer rather than blindly replaying it.

## Tests and version control

```sh
python3 -m unittest discover -s tests -v
lua tests/test_screensaver_bindings.lua
lua tests/test_input.lua
bash -n setup.sh
```

Tests run against a temporary home and mocked monitor/window data, without
moving real windows. They cover setup idempotency, backing up replaced files,
removal, preserving the existing main config, and fractional snap geometry.

Commit and push changes yourself when ready; setup never commits or pushes.
This repository retains its ancient Git history, but its HEAD was already empty
when this desktop layer was added.

## Built-in display scale

The built-in `eDP-1` display runs at native 2880×1800 with **1.5×** scaling
(1920×1200 logical). The rule lives in `~/.config/hypr/monitors.lua` because
Omarchy's wake/clamshell helper (`omarchy-hyprland-monitor-clamshell`, run on
every idle-wake, unlock and lid change) reads only that file and reapplies its
scale. A rule elsewhere loaded at startup but reverted to 1.6× after each wake.

`link.py` appends one tagged line to `monitors.lua`, like the loader line in
`hyprland.lua`, and leaves the rest of the file alone:

```lua
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.5 }) -- dotfiles: built-in display scale
```

External displays keep the catch-all rule and `omarchy_monitor_scale`.
`--remove` deletes only that line. If Omarchy refreshes `monitors.lua`,
`./setup.sh --check` fails until you rerun `./setup.sh`. Change `DISPLAY` in
`link.py` on a machine with a different panel. This isn't a complete machine
backup. No Ghostty shortcut edits or Hyprshell install were performed.
