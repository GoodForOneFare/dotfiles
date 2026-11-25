local handler, opened_handler, pending, active, peers
local dispatched = {}
hl = {
  on = function(event, callback)
    if event == "window.active" then handler = callback
    elseif event == "window.open" then opened_handler = callback
    else error("Unexpected event: " .. event) end
  end,
  timer = function(callback, opts)
    assert(opts.type == "oneshot" and opts.timeout == 1)
    pending = callback
  end,
  get_active_window = function() return active end,
  get_windows = function() return peers end,
  dispatch = function(value) table.insert(dispatched, value) end,
  dsp = { window = {
    alter_zorder = function(value) value.op = "zorder"; return value end,
    float = function(value) value.op = "float"; return value end,
    resize = function(value) value.op = "resize"; return value end,
    move = function(value) value.op = "move"; return value end,
  } },
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
-- A browser activated by a Slack link must rise, even without fullscreen.
dispatched = {}
active = win("0xc")
peers = {win("0xd", {fullscreen = 2}), active}
handler(active)
assert(#dispatched == 0)
pending()
assert(#dispatched == 1)
assert(dispatched[1].window == "address:0xc" and dispatched[1].mode == "top")
assert(peers[1].fullscreen == 2) -- leave the other app fullscreen
assert(active.floating and active.workspace.id == 1)

-- An ordinary tiled window should not have its layout/stacking changed.
active = win("0x1", {floating = false})
no_change(active, active)
active = win("0x1", {fullscreen = 2, mapped = false})
no_change(active, active)
active = win("0x1", {fullscreen = 2, workspace = false})
no_change(active, active)
no_change(nil, nil)
-- New Chrome windows can be focused but tiled below the existing floats.
-- Opening must float in place, then raise; never explicitly dispatch focus.
dispatched = {}
active = win("0xe", {floating = false, at = {24, 48}, size = {1280, 900}})
opened_handler(active)
assert(#dispatched == 0)
pending()
assert(#dispatched == 4)
assert(dispatched[1].op == "float" and dispatched[1].action == "on")
assert(dispatched[2].op == "resize" and dispatched[2].x == 1280
  and dispatched[2].y == 900 and dispatched[2].relative == false)
assert(dispatched[3].op == "move" and dispatched[3].x == 24
  and dispatched[3].y == 48 and dispatched[3].relative == false)
assert(dispatched[4].op == "zorder" and dispatched[4].mode == "top")
for _, d in ipairs(dispatched) do assert(d.window == "address:0xe") end

-- No floating/raising a background, closed, or fullscreen newcomer.
dispatched = {}
opened_handler(active)
active = win("0xf")
pending()
assert(#dispatched == 0)
opened_handler(active)
active = nil
pending()
assert(#dispatched == 0)
active = win("0xe", {floating = false, fullscreen = 2})
peers = {active}
opened_handler(active)
pending()
assert(#dispatched == 0 and active.fullscreen == 2)
print("Opening, floating activation, fullscreen cleanup and stale-focus checks passed.")
