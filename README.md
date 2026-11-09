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
Requires Python 3, Git, Omarchy and Hyprland. The current tested baseline is
Omarchy **4.0.4-1**, Hyprland **0.56.2-2** (Lua), Ghostty **1.3.1-2**.
Recheck compatibility before applying on a newer desktop version.

The script:

1. Symlinks only the personal modules and the `window-snap` helper into your home.
2. Adds a single final `require("hypr.personal")` line to your existing
   `~/.config/hypr/hyprland.lua`, preserving everything else.
3. Installs omac if missing, pinned to
   `fe434579e7fa9dc0fa3d0f87905cf4fd057fd4f1`, and enables it. An existing omac
   checkout is **never reset**; a different revision produces a warning.
4. Reloads Hyprland and checks configuration errors. It never restarts your
   desktop session or reboots.

Existing replaced files are backed up under `~/.local/state/dotfiles/backups/`.
On validation failure, inspect that backup and restore the previous configs;
the script does not claim to automatically undo all plugin installation effects.

The directories use GNU Stow's package layout (`hypr/` and `bin/`), but the
included Python linker does not require Stow to be installed.

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
  display.lua      # Built-in eDP-1 at native resolution, 1.5x (1920x1200 logical)
  appearance.lua   # Zero gaps/borders, opaque windows, 50% scrolling columns
  input.lua        # Caps Lock as Hyper, fingers-down scrolls down
  windows.lua      # Floating defaults and Rectangle-style snapping
  editing.lua      # Native Alt+Backspace in terminals; Ctrl+Backspace elsewhere
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

Snapping respects the target display's scale and reserved space. It does not
change other windows. New windows float; to float already-open windows:

```sh
python3 ~/.local/bin/window-snap float-existing
```

This preserves geometry where possible, moving off-screen columns back into the
work area. It is deliberately not run on every setup, so reapplying your dotfiles
does not rearrange your windows. Alt+Backspace's exact word boundary remains
application-dependent.

## Check, reapply, or disable

```sh
./setup.sh --check    # Validate links, loader, plugin enabled, and config errors
./setup.sh            # Safe to repeat; repair links/loader after moving the repo
./setup.sh --remove   # Remove our symlinks and loader, then reload
```

Removing the personal layer leaves **omac installed and enabled**. To also
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
bash -n setup.sh
```

Tests run against a temporary home and mocked monitor/window data, without
moving real windows. They cover setup idempotency, backing up replaced files,
removal, preserving the existing main config, and fractional snap geometry.

Commit and push changes yourself when ready; setup never commits or pushes.
This repository retains its ancient Git history, but its HEAD was already empty
when this desktop layer was added.

`personal/display.lua` overrides the built-in `eDP-1` display to 1.5x scaling.
Change or disable that module on a different machine. Other monitor settings
remain in the normal `~/.config/hypr/monitors.lua`. This isn't a complete machine
backup. No Ghostty shortcut edits or Hyprshell install were performed.
