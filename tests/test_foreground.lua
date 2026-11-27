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
  dsp = { focus = function(value) value.op = "focus"; return value end,
    window = {
    alter_zorder = function(value) value.op = "zorder"; return value end,
    float = function(value) value.op = "float"; return value end,
    resize = function(value)
      assert(type(value.x) == "number" and type(value.y) == "number")
      value.op = "resize"; return value
    end,
    move = function(value)
      assert(type(value.x) == "number" and type(value.y) == "number")
      value.op = "move"; return value
    end,
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
-- Lua geometry uses named x/y fields, unlike hyprctl's JSON arrays.
active = win("0xe", {floating = false, at = {x = 24, y = 48},
  size = {x = 1280, y = 900}})
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
-- Regression: Chrome above fullscreen Slack in workspace 1; switch to the
-- lone Ghostty in workspace 2, cycle it, then return. No workspace-2 operation
-- may reorder workspace 1, and automatic fullscreen focus must restore Chrome.
local chrome = win("0xc1", {focus_history_id = 0})
local slack = win("0xc2", {fullscreen = 2, focus_history_id = 1})
local ghostty = win("0xc3", {workspace = {id = 2}, focus_history_id = 2})
peers = {chrome, slack, ghostty}
active = chrome
dispatched = {}
handler(chrome, 3) -- explicit focus
pending()
assert(#dispatched == 1 and dispatched[1].window == "address:0xc1")
active = ghostty
dispatched = {}
handler(ghostty, 11) -- enter workspace 2
pending()
handler(ghostty, 3) -- switcher picks its only window
pending()
for _, d in ipairs(dispatched) do assert(d.window == "address:0xc3") end
active = slack
dispatched = {}
handler(slack, 11) -- Hyprland's automatic fullscreen choice on workspace return
assert(#dispatched == 0)
pending()
assert(#dispatched == 2)
assert(dispatched[1].op == "focus" and dispatched[1].window == "address:0xc1")
assert(dispatched[2].window == "address:0xc1" and dispatched[2].mode == "top")
assert(slack.fullscreen == 2 and chrome.workspace.id == 1)

-- Explicitly choosing Slack still reveals fullscreen and replaces the memory.
dispatched = {}
handler(slack, 3)
pending()
assert(#dispatched == 1 and dispatched[1].window == "address:0xc1"
  and dispatched[1].mode == "bottom")
dispatched = {}
handler(slack, 11)
pending()
assert(#dispatched == 1 and dispatched[1].mode == "bottom")

-- Reload seeds the workspace choice from compositor MRU, not stacking order.
peers = {slack, ghostty, chrome}
dofile("hypr/.config/hypr/personal/foreground.lua")
dispatched = {}
handler(slack, 11)
pending()
assert(#dispatched == 2 and dispatched[1].op == "focus"
  and dispatched[1].window == "address:0xc1")

-- A closed/moved/tiled/pinned remembered float must never redirect focus.
for _, overrides in ipairs({{mapped = false}, {workspace = {id = 3}},
    {floating = false}, {pinned = true}}) do
  peers = {win("0xc1", overrides), slack, ghostty}
  dispatched = {}
  handler(slack, 11)
  pending()
  for _, d in ipairs(dispatched) do assert(d.op ~= "focus") end
end
peers = {chrome, slack, ghostty}
dispatched = {}
handler(slack, 11)
active = ghostty -- user moved again before restoration
pending()
assert(#dispatched == 0)
print("Opening, workspace return, fullscreen cleanup and stale-focus checks passed.")
