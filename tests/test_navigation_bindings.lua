local bindings, sent, timers = {}, {}, {}
local active = {class = "google-chrome", tags = {}}
o = {
  rebind = function(chord, description, callback)
    assert(not bindings[chord])
    bindings[chord] = {description = description, callback = callback}
  end,
}
hl = {
  get_active_window = function() return active end,
  dispatch = function(value) table.insert(sent, value) end,
  timer = function(callback, options)
    assert(options.timeout == 50 and options.type == "oneshot")
    table.insert(timers, callback)
  end,
  dsp = {send_key_state = function(value) return value end},
}
dofile("hypr/.config/hypr/personal/navigation.lua")
local count = 0
for _ in pairs(bindings) do count = count + 1 end
assert(count == 12) -- arrows/selections, history shortcuts, Ctrl+L and Ctrl+T
local expected = {
  {"SUPER + LEFT", "", "Home", "Line start"},
  {"SUPER + RIGHT", "", "End", "Line end"},
  {"SUPER + UP", "CTRL", "Home", "Document start"},
  {"SUPER + DOWN", "CTRL", "End", "Document end"},
  {"SUPER + SHIFT + LEFT", "SHIFT", "Home", "Select to line start"},
  {"SUPER + SHIFT + RIGHT", "SHIFT", "End", "Select to line end"},
  {"SUPER + SHIFT + UP", "CTRL SHIFT", "Home", "Select to document start"},
  {"SUPER + SHIFT + DOWN", "CTRL SHIFT", "End", "Select to document end"},
  {"SUPER + BRACKETLEFT", "ALT", "LEFT", "Back"},
  {"SUPER + BRACKETRIGHT", "ALT", "RIGHT", "Forward"},
  {"SUPER + L", "CTRL", "L", "Address bar / Ctrl+L"},
  {"SUPER + T", "CTRL", "T", "New tab"},
}
local function check_binding(item)
  sent, timers = {}, {}
  local binding = bindings[item[1]]
  assert(binding.description == item[4])
  binding.callback()
  assert(#sent == 1 and #timers == 1)
  assert(sent[1].mods == item[2] and sent[1].key == item[3]
    and sent[1].state == "down" and sent[1].window == nil)
  timers[1]()
  assert(#sent == 2 and sent[2].mods == item[2]
    and sent[2].key == item[3] and sent[2].state == "up")
end
for _, class in ipairs({"google-chrome", "slack", "com.microsoft.VSCode"}) do
  active = {class = class, tags = {}}
  for _, item in ipairs(expected) do check_binding(item) end
end
-- Terminals receive line-start/end and Ctrl+L, not document/history keys.
for _, terminal in ipairs({
  {class = "com.mitchellh.ghostty", tags = {}},
  {class = "herdr-app", tags = {}},
  {class = "kitty", tags = {"terminal*"}},
  {class = "foot", tags = {"terminal"}},
}) do
  active = terminal
  check_binding(expected[1])
  check_binding(expected[2])
  check_binding(expected[11])
  for i = 3, #expected do
    if i ~= 11 then
      sent, timers = {}, {}
      bindings[expected[i][1]].callback()
      assert(#sent == 0 and #timers == 0)
    end
  end
end
active = nil
for _, binding in pairs(bindings) do
  sent, timers = {}, {}
  binding.callback()
  assert(#sent == 0 and #timers == 0)
end
print("Mac-style arrows, selection, bracket history and terminal safety checks passed.")
