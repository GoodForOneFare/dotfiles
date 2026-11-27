#!/usr/bin/env python3
"""Disable GNOME background file indexing on this development machine."""
import argparse
import subprocess

UNITS = (
    "localsearch-3.service",
    "localsearch-control-3.service",
    "localsearch-writeback-3.service",
)


def property_value(unit, name):
    return subprocess.check_output(
        ["systemctl", "--user", "show", unit, f"--property={name}", "--value"],
        text=True,
    ).strip()


def configure(check=False):
    if check:
        for unit in UNITS:
            if property_value(unit, "LoadState") != "masked":
                raise SystemExit(f"{unit} is not masked; rerun ./setup.sh")
            if property_value(unit, "MainPID") != "0":
                raise SystemExit(f"{unit} is still running")
        print("LocalSearch background indexing is disabled.")
        return
    # Masking also prevents Nautilus/D-Bus from starting the indexer again.
    # Don't wait 90 seconds for the huge indexer's unresponsive graceful stop.
    subprocess.run(
        ["systemctl", "--user", "mask", "--now", "--no-block", *UNITS], check=True,
    )
    for unit in UNITS:
        if property_value(unit, "MainPID") != "0":
            subprocess.run(
                ["systemctl", "--user", "kill", "--kill-whom=all", "--signal=SIGKILL", unit],
                check=True,
            )
    print("LocalSearch masked and stopped; personal files are untouched.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    configure(args.check)
