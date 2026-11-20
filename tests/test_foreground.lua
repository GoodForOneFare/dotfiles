local handler, pending, active, peers
local dispatched = {}
hl = {
  on = function(event, callback)
    assert(event == "window.active")
    handler = callback
  end,
  timer = function(callback, opts)
    assert(opts.type == "oneshot" and opts.timeout == 1)
    pending = callback
  end,
  get_active_window = function() return active end,
  get_windows = function() return peers end,
  dispatch = function(value) table.insert(dispatched, value) end,
  dsp = { window = { alter_zorder = function(value) return value end } },
}
dofile("hypr/.config/hypr/personal/foreground.lua")
local function win(address, overrides)
  local w = {address = address, mapped = true, floating = true, fullscreen = 0,
    workspace = {id = 1}, allowed_over_fullscreen = true}
  for k, v in pairs(overrides or {}) do w[k] = v end
  return w
end
active = win("0x1", {fullscreen = 2})
peers = {
  active, win("0x2"), win("0x3"),
  win("0x4", {pinned = true}),
  win("0x5", {workspace = {id = 2}}),
  win("0x6", {fullscreen = 2}),
  win("0x7", {floating = false}),
  win("0x8", {mapped = false}),
  win("0x9", {allowed_over_fullscreen = false}),
  win("0xa", {workspace = false}),
}
handler(active)
assert(#dispatched == 0) -- never mutate the focus operation in progress
pending()
assert(#dispatched == 2)
assert(dispatched[1].window == "address:0x3" and dispatched[1].mode == "bottom")
assert(dispatched[2].window == "address:0x2" and dispatched[2].mode == "bottom")
assert(active.fullscreen == 2)

local function no_change(event_window, current)
  dispatched, pending = {}, nil
  handler(event_window)
  active = current
  if pending then pending() end
  assert(#dispatched == 0)
end
no_change(active, win("0xb", {fullscreen = 2})) -- focus moved before timer
active = win("0x1", {fullscreen = 2})
no_change(active, nil) -- closed before timer
active = win("0x1")
no_change(active, active) -- ordinary app: no overlay cleanup
active = win("0x1", {fullscreen = 2, mapped = false})
no_change(active, active)
active = win("0x1", {fullscreen = 2, workspace = false})
no_change(active, active)
no_change(nil, nil)
print("Fullscreen foreground cleanup checks passed.")
