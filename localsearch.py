#!/usr/bin/env python3
"""Limit LocalSearch to personal folders, not the whole development home."""
import argparse
import ast
from pathlib import Path
import subprocess

SCHEMA = "org.freedesktop.Tracker3.Miner.Files"
FOLDERS = ("Documents", "Downloads", "Music", "Pictures", "Videos")


def command(*args):
    return subprocess.check_output(args, text=True).strip()


def configure(check=False):
    if SCHEMA not in command("gsettings", "list-schemas").splitlines():
        print("LocalSearch is not installed; skipping indexing preferences.")
        return
    expected = {
        "index-recursive-directories": [str(Path.home() / name) for name in FOLDERS],
        "index-single-directories": [],
    }
    changes = {}
    for key, value in expected.items():
        current = command("gsettings", "get", SCHEMA, key)
        # GVariant annotates empty arrays as '@as []'.
        if ast.literal_eval(current.removeprefix("@as ")) != value:
            changes[key] = value
    if check:
        if changes:
            raise SystemExit("LocalSearch indexing scope differs; rerun ./setup.sh")
        print("LocalSearch indexes only personal document/media folders.")
    elif changes:
        # Stop the broad scan before changing scope; restart to release its memory.
        subprocess.run(["systemctl", "--user", "stop", "localsearch-3.service"], check=True)
        for key, value in changes.items():
            subprocess.run(["gsettings", "set", SCHEMA, key, repr(value)], check=True)
        subprocess.run(["systemctl", "--user", "start", "localsearch-3.service"], check=True)
        print("LocalSearch indexing narrowed to personal document/media folders.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    configure(args.check)
