#!/usr/bin/env python3
"""Link only our user-owned layer; preserve Omarchy's main configuration."""
import argparse
import os
from pathlib import Path
import shutil
import tempfile

ROOT = Path(__file__).resolve().parent
HOME = Path.home()
LOADER = 'require("hypr.personal")'
# Built-in display: native 2880x1800 at 1.5x (1920x1200 logical). It must live
# in monitors.lua: Omarchy's wake/clamshell helper reads only that file and
# reapplies its scale, so an override elsewhere reverts after lock or sleep.
# A specific eDP-1 rule wins over the catch-all; external displays keep it.
DISPLAY_TAG = "-- dotfiles: built-in display scale"
DISPLAY = ('hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", '
           'scale = 1.5 }) ' + DISPLAY_TAG)


# Ghostty has no inline comments (one would become part of the path), so the
# include line is its own marker.
GHOSTTY = GHOSTTY_TAG = 'config-file = ?"~/.config/ghostty/personal.conf"'
# (file relative to HOME, tag, line): one tagged line kept at the end of a
# user-owned file. Nothing else in those files is touched.
TAILS = [
    (".config/hypr/monitors.lua", DISPLAY_TAG, DISPLAY),
    (".config/ghostty/config", GHOSTTY_TAG, GHOSTTY),
]


def with_tail(body, tag, line, remove=False):
    lines = [existing for existing in body.splitlines() if tag not in existing]
    updated = "\n".join(lines).rstrip() + "\n"
    return updated if remove else updated + "\n" + line + "\n"



def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--remove", action="store_true")
    args = parser.parse_args()
    if args.check and args.remove:
        parser.error("choose --check or --remove")
    config = HOME / ".config/hypr/hyprland.lua"
    if not config.is_file():
        raise SystemExit("Install/configure Lua-based Omarchy first; hyprland.lua is missing.")
    pairs = []
    for package in ("hypr", "bin", "omarchy", "systemd", "ghostty"):
        package_root = ROOT / package
        for source in package_root.rglob("*"):
            if (source.is_file() and "__pycache__" not in source.parts
                    and source.suffix != ".pyc"):
                pairs.append((source, HOME / source.relative_to(package_root)))
    body = config.read_text()
    tails = [(HOME / rel, tag, line) for rel, tag, line in TAILS]
    tail_bodies = {path: path.read_text() if path.is_file() else "" for path, _, _ in tails}
    if args.check:
        errors = []
        for source, target in pairs:
            if not target.is_symlink() or target.resolve() != source:
                errors.append(f"Not linked: {target}")
        lines = body.splitlines()
        active_lines = [line.strip() for line in lines if line.strip() and not line.lstrip().startswith("--")]
        if active_lines.count(LOADER) != 1 or active_lines[-1:] != [LOADER]:
            errors.append("Personal loader must appear once, at the end of hyprland.lua")
        for path, tag, line in tails:
            text = tail_bodies[path]
            if text.splitlines().count(line) != 1 or with_tail(text, tag, line) != text:
                errors.append(f"Managed line must appear once, at the end of {path}")
        if errors:
            raise SystemExit("\n".join(errors))
        print("All links, the final loader and managed lines are correct.")
        return
    backup_root = HOME / ".local/state/dotfiles/backups"
    backup_root.mkdir(parents=True, exist_ok=True)
    backup = Path(tempfile.mkdtemp(prefix="setup-", dir=backup_root))

    def preserve(target):
        saved = backup / target.relative_to(HOME)
        saved.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(target, saved, follow_symlinks=False)

    for source, target in pairs:
        owned = target.is_symlink() and target.resolve() == source
        if args.remove:
            if owned:
                preserve(target)
                target.unlink()
        elif not owned:
            target.parent.mkdir(parents=True, exist_ok=True)
            if os.path.lexists(target):
                if target.is_dir():
                    raise SystemExit(f"Refusing to replace directory: {target}")
                preserve(target)
                target.unlink()
            target.symlink_to(source)
    # Only manage our one loader line, never replace the main config template.
    lines = [line for line in body.splitlines() if line.strip() != LOADER]
    updated = "\n".join(lines).rstrip() + "\n"
    if not args.remove:
        updated += "\n" + LOADER + "\n"
    if updated != body:
        preserve(config)
        config.write_text(updated)
    # Likewise manage only our one tagged line in each of those files.
    for path, tag, line in tails:
        if path.is_file() or not args.remove:
            text = tail_bodies[path]
            updated = with_tail(text, tag, line, remove=args.remove)
            if updated != text:
                if path.is_file():
                    preserve(path)
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(updated)
    print(f"Backup of replaced files: {backup}")
    print("Personal layer removed." if args.remove else "Personal layer linked.")


if __name__ == "__main__":
    main()
