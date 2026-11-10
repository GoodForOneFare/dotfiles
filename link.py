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
    for package in ("hypr", "bin", "omarchy", "systemd"):
        package_root = ROOT / package
        for source in package_root.rglob("*"):
            if (source.is_file() and "__pycache__" not in source.parts
                    and source.suffix != ".pyc"):
                pairs.append((source, HOME / source.relative_to(package_root)))
    body = config.read_text()
    if args.check:
        errors = []
        for source, target in pairs:
            if not target.is_symlink() or target.resolve() != source:
                errors.append(f"Not linked: {target}")
        lines = body.splitlines()
        active_lines = [line.strip() for line in lines if line.strip() and not line.lstrip().startswith("--")]
        if active_lines.count(LOADER) != 1 or active_lines[-1:] != [LOADER]:
            errors.append("Personal loader must appear once, at the end of hyprland.lua")
        if errors:
            raise SystemExit("\n".join(errors))
        print("All links and the final loader are correct.")
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
    print(f"Backup of replaced files: {backup}")
    print("Personal layer removed." if args.remove else "Personal layer linked.")


if __name__ == "__main__":
    main()
