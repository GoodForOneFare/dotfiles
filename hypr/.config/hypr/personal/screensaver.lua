-- Keep Omarchy's launcher, idle timer, and lock screen. Shadow only the
-- animation executable for terminals launched by Hyprland, not all user tools.
local private_bin = os.getenv("HOME") .. "/.config/omarchy/personal/bin"
local path = os.getenv("PATH") or "/usr/bin:/bin"
local parts = { private_bin }
for entry in path:gmatch("[^:]+") do
  if entry ~= private_bin then table.insert(parts, entry) end
end
hl.env("PATH", table.concat(parts, ":"))

-- Terminals do not emit ordinary bytes for a bare modifier key. Handle it in
-- the compositor, but consume it ONLY when a screensaver window is focused.
local function dismiss_screensaver()
  local active = hl.get_active_window()
  if not active or active.class ~= "org.omarchy.screensaver" then
    return { ok = false }
  end
  for _, window in ipairs(hl.get_windows()) do
    if window.class == "org.omarchy.screensaver" then
      hl.dispatch(hl.dsp.window.close({ window = window }))
    end
  end
  return { ok = true }
end

for _, key in ipairs({ "Super_L", "Super_R", "Alt_L", "Alt_R",
                      "Control_L", "Control_R", "Shift_L", "Shift_R", "Hyper_L" }) do
  -- These were previously unbound as standalone keys. Do not replace the
  -- normal Super/Alt/Caps combinations used throughout the desktop.
  hl.unbind(key)
  o.bind(key, "Dismiss screensaver with modifier", dismiss_screensaver,
         { auto_consuming = true })
end
