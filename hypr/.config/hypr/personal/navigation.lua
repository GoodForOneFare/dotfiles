-- Mac-style Command navigation, loaded after Omarchy and omac.
local function is_terminal(window)
  if window.class == "herdr-app" or window.class == "com.mitchellh.ghostty" then
    return true
  end
  for _, tag in ipairs(window.tags or {}) do
    if tag:gsub("%*$", "") == "terminal" then return true end
  end
  return false
end

local function send(mods, key, in_terminal)
  return function()
    local window = hl.get_active_window()
    if not window or (is_terminal(window) and not in_terminal) then return end
    -- Match Omarchy/omac's down/up workaround for stuck synthetic keys.
    -- These events bypass compositor bindings, including omac's Alt+arrows.
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end
end

local arrows = {
  { key = "LEFT", to = "Home", mods = "", label = "Line start" },
  { key = "RIGHT", to = "End", mods = "", label = "Line end" },
  { key = "UP", to = "Home", mods = "CTRL", label = "Document start" },
  { key = "DOWN", to = "End", mods = "CTRL", label = "Document end" },
}
for _, arrow in ipairs(arrows) do
  o.rebind("SUPER + " .. arrow.key, arrow.label,
    send(arrow.mods, arrow.to, arrow.mods == ""))
  o.rebind("SUPER + SHIFT + " .. arrow.key, "Select to " .. arrow.label:lower(),
    send(arrow.mods == "" and "SHIFT" or "CTRL SHIFT", arrow.to, false))
end

o.rebind("SUPER + BRACKETLEFT", "Back", send("ALT", "LEFT", false))
o.rebind("SUPER + BRACKETRIGHT", "Forward", send("ALT", "RIGHT", false))

-- Ctrl+L selects the browser address bar; in shells it clears the display.
o.rebind("SUPER + L", "Address bar / Ctrl+L", send("CTRL", "L", true))

-- Ctrl+T opens a GUI tab, but transposes characters in shells.
o.rebind("SUPER + T", "New tab", send("CTRL", "T", false))
