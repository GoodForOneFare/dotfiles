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

Existing replaced files are backed up under `~/.local/state/dotfiles/backups/`.
On validation failure, inspect that backup and restore the previous configs;
the script does not claim to automatically undo all plugin installation effects.

The directories use GNU Stow's package layout (`hypr/` and `bin/`), but the
included Python linker does not require Stow to be installed. The `omarchy/`
package contains private screensaver assets and its replacement animation program.
The `systemd/` package contains the session-scoped hot-corner service.

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
  input.lua        # Caps Lock as Hyper, fingers-down scrolls down
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

No typing, arrows, or Enter are needed. Windows across workspaces are listed in
recent-use order, with the previous window highlighted first. Super+1..9 still
selects workspaces; Super+Ctrl+Tab returns to the former workspace. Alt+Tab is
unchanged.

The plugin lives in `omarchy/.config/omarchy/plugins/personal.switcher/` and is
enabled by setup. Native Hyprland global shortcuts preserve press/release
ordering without spawning processes for each keypress. Once the modal owns
keyboard focus, its focused input forwards actual Super release events to the
plugin's selection handler; compositor release shortcuts alone are insufficient.
Fast Super taps queue
selection until the window snapshot is ready. The small `window-picker` Python
helper validates, focuses, and raises the chosen address. Tiled windows always
render below floating ones, so a tiled selection (for example, a window opened
before the float-all rule applied) is first floated in place, keeping its
current position and size. No extra package or
daemon is required, and no packaged UI source is modified.

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
