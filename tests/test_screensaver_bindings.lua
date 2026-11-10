-- Run with: lua tests/test_screensaver_bindings.lua
-- Verify modifier handlers never close normal windows or lock surfaces.
local callbacks, closed, active = {}, {}, nil
hl = {
  env = function() end,
  unbind = function() end,
  get_active_window = function() return active end,
  get_windows = function() return {
    { class = "org.omarchy.screensaver", address = "saver" },
    { class = "com.mitchellh.ghostty", address = "terminal" },
    { class = "lockscreen", address = "lock" },
  } end,
  dispatch = function(d) table.insert(closed, d.window.address) end,
  dsp = { window = { close = function(d) return d end } },
}
o = { bind = function(key, _, callback, options)
  assert(options.auto_consuming == true)
  callbacks[key] = callback
end }
dofile("hypr/.config/hypr/personal/screensaver.lua")
for _, callback in pairs(callbacks) do
  closed = {}
  active = nil
  assert(callback().ok == false)
  active = { class = "com.mitchellh.ghostty" }
  assert(callback().ok == false)
  active = { class = "lockscreen" }
  assert(callback().ok == false)
  assert(#closed == 0)
  active = { class = "org.omarchy.screensaver" }
  assert(callback().ok == true)
  assert(#closed == 1 and closed[1] == "saver")
end
print("Screensaver-only modifier dismissal checks passed.")
