-- Passive regression: raw release detection is independent of layer focus,
-- shortcut modifier matching, Tab release order, and snapshot loading.
local bindings, callbacks, dispatched = {}, {}, {}
hl = {
  dsp = { global = function(name) return name end },
  on = function(event, callback) callbacks[event] = callback end,
  dispatch = function(action) table.insert(dispatched, action) end,
}
o = {
  rebind = function(keys, description, action, options)
    bindings[keys] = { action = action, options = options or {} }
  end,
}
dofile('hypr/.config/hypr/personal/switcher.lua')
assert(bindings['SUPER + TAB'].action == 'personal-switcher:next')
assert(bindings['SUPER + SHIFT + TAB'].action == 'personal-switcher:previous')
assert(bindings['ALT + TAB'].action == 'personal-switcher:next')
assert(not bindings['ALT + Alt_R'], 'Right Alt dictation must be untouched')
for _, binding in pairs(bindings) do
  assert(not binding.options.release, 'release must not depend on keybind matching')
end
local key = assert(callbacks['input.keyboard.key'])
-- Presses, Tab releases and unrelated keys must not commit.
key(133, 1, 1)
key(23, 2, 0)
key(37, 3, 0)
key(108, 4, 0) -- Right Alt is handled only by the modal.
assert(#dispatched == 0)
for _, code in ipairs({133, 134, 64}) do
  key(code, 10, 0)
  assert(dispatched[#dispatched] == 'personal-switcher:commit')
end
assert(#dispatched == 3)
-- Rapid consecutive chords each get their own release, even if Tab remains
-- down when Super is released. No timers or asynchronous per-key processes.
for _ = 1, 20 do
  key(133, 11, 1)
  key(23, 12, 1)
  key(133, 13, 0)
  key(23, 14, 0)
end
assert(#dispatched == 23)
print('switcher bindings: raw releases and rapid chords OK')
