#!/usr/bin/env python3
"""Opt-in live test: briefly switches focus, then restores the original window.
Run manually in the desktop session: python3 tests/check_switcher_release.py
Requires wtype. Not part of unittest discovery; sends actual Wayland keys.
"""
import json
import subprocess
import time


def call(*args):
    return subprocess.check_output(args, text=True, timeout=3).strip()


def state():
    return json.loads(call('omarchy-shell', 'personal.switcher', 'state'))


original = json.loads(call('hyprctl', '-j', 'activewindow'))['address']
try:
    for key in ['Super_L', 'Super_R']:
        call('hyprctl', 'dispatch', 'hl.dsp.global("personal-switcher:next")')
        time.sleep(0.15)
        before = state()
        assert before['opened'] and before['releaseHandlerInstalled'], before
        subprocess.run(['wtype', '-P', key, '-s', '70', '-p', key], check=True, timeout=3)
        time.sleep(0.2)
        after = state()
        actual = json.loads(call('hyprctl', '-j', 'activewindow'))['address']
        assert not after['opened'], after
        assert actual == before['selected'], (actual, before)
        print(f'{key}: modal closed and highlighted window focused')
        subprocess.run(['python3', '../bin/.local/bin/window-picker', 'focus', original],
                       cwd=__import__('pathlib').Path(__file__).resolve().parent,
                       check=True, timeout=3)
finally:
    call('omarchy-shell', 'shell', 'summon', 'personal.switcher', '{"action":"cancel"}')
    subprocess.run(['python3', '../bin/.local/bin/window-picker', 'focus', original],
                   cwd=__import__('pathlib').Path(__file__).resolve().parent,
                   check=True, timeout=3)
