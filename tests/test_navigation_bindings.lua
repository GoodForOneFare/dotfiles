local bindings, sent, timers = {}, {}, {}
o = {
  rebind = function(chord, description, callback)
    assert(not bindings[chord])
    bindings[chord] = {description = description, callback = callback}
  end,
}
hl = {
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
assert(count == 2) -- no changes to Shift/Ctrl/Alt arrow shortcuts
assert(bindings["SUPER + LEFT"].description == "Back")
assert(bindings["SUPER + RIGHT"].description == "Forward")
bindings["SUPER + LEFT"].callback()
bindings["SUPER + RIGHT"].callback()
assert(#sent == 2 and #timers == 2)
assert(sent[1].key == "LEFT" and sent[2].key == "RIGHT")
for _, value in ipairs(sent) do
  assert(value.mods == "ALT" and value.state == "down" and value.window == nil)
end
for _, callback in ipairs(timers) do callback() end
assert(#sent == 4)
assert(sent[3].key == "LEFT" and sent[4].key == "RIGHT")
for i = 3, 4 do assert(sent[i].mods == "ALT" and sent[i].state == "up") end
print("Super+arrow app navigation and synthetic key release checks passed.")
