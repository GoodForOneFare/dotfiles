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
