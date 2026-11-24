-- Native shortcuts: no fork per keypress, ordered cycling and modifier release.
local function action(name)
  return hl.dsp.global("personal-switcher:" .. name)
end
o.rebind("SUPER + TAB", "Next window in switcher", action("next"))
o.rebind("SUPER + SHIFT + TAB", "Previous window in switcher", action("previous"))
o.rebind("SUPER + grave", "Cycle highlighted app's windows", action("instances"))
o.rebind("SUPER + SHIFT + grave", "Cycle highlighted app's windows", action("instances"))
-- Observe releases before keybind matching and Wayland focus routing. A fast
-- release can land between the compositor shortcut and the modal taking focus;
-- ordinary release binds depend on the held modifier mask and layer focus.
-- Hyprland's Lua event supplies XKB keycodes (evdev + 8), time, then state
-- (0 = released). Do not consume events or change Right Alt's dictation bind.
local commitKeys = { [133] = true, [134] = true, [64] = true }
hl.on("input.keyboard.key", function(keycode, _, state)
  if state == 0 and commitKeys[keycode] then
    hl.dispatch(action("commit"))
  end
end)

-- Alt+Tab drives the same switcher (replaces Omarchy's focus-next/raise).
o.rebind("ALT + TAB", "Next window in switcher", action("next"))
o.rebind("ALT + SHIFT + TAB", "Previous window in switcher", action("previous"))
o.rebind("ALT + grave", "Cycle highlighted app's windows", action("instances"))
o.rebind("ALT + SHIFT + grave", "Cycle highlighted app's windows", action("instances"))
-- Right Alt release stays in-modal (Switcher.qml): outside the switcher,
-- ALT + Alt_R press/release belongs exclusively to push-to-talk dictation.
