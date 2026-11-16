-- Native shortcuts: no fork per keypress, ordered cycling and modifier release.
local function action(name)
  return hl.dsp.global("personal-switcher:" .. name)
end
o.rebind("SUPER + TAB", "Next window in switcher", action("next"))
o.rebind("SUPER + SHIFT + TAB", "Previous window in switcher", action("previous"))
o.rebind("SUPER + grave", "Cycle highlighted app's windows", action("instances"))
o.rebind("SUPER + SHIFT + grave", "Cycle highlighted app's windows", action("instances"))
for _, key in ipairs({ "Super_L", "Super_R" }) do
  o.rebind("SUPER + " .. key, "Select highlighted window on Super release",
    action("commit"), { release = true })
  o.rebind("SUPER + SHIFT + " .. key, "Select highlighted window on Super release",
    action("commit"), { release = true })
end

-- Alt+Tab drives the same switcher (replaces Omarchy's focus-next/raise).
o.rebind("ALT + TAB", "Next window in switcher", action("next"))
o.rebind("ALT + SHIFT + TAB", "Previous window in switcher", action("previous"))
o.rebind("ALT + grave", "Cycle highlighted app's windows", action("instances"))
o.rebind("ALT + SHIFT + grave", "Cycle highlighted app's windows", action("instances"))
-- Releasing either Alt selects once the modal is open (Switcher.qml handles
-- that). Only left Alt also gets a compositor release bind, for taps faster
-- than the modal opens: ALT + Alt_R press/release is push-to-talk dictation.
o.bind("ALT + Alt_L", "Select highlighted window on Alt release",
  action("commit"), { release = true })
o.bind("ALT + SHIFT + Alt_L", "Select highlighted window on Alt release",
  action("commit"), { release = true })
