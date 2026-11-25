-- App activation can change keyboard focus without raising a floating window.
-- Keep stacking in sync with focus, including notifications and browser links.
-- Fullscreen targets also need their old above-fullscreen overlays cleared.
local function foreground(window, opened)
  if not window then return end
  local address = window.address
  -- Focus is still being committed inside the event. Re-resolve on the next
  -- turn and never redirect focus if the user has already switched again.
  hl.timer(function()
    local active = hl.get_active_window()
    if not active or active.address ~= address or not active.mapped
        or not active.workspace then return end
    if (active.fullscreen or 0) ~= 0 then
      local peers = hl.get_windows()
      -- Lower in reverse stacking order to preserve the peers' relative order.
      for i = #peers, 1, -1 do
        local peer = peers[i]
        if peer.address ~= address and peer.mapped and peer.floating
            and not peer.pinned and (peer.fullscreen or 0) == 0
            and peer.allowed_over_fullscreen and peer.workspace
            and peer.workspace.id == active.workspace.id then
          hl.dispatch(hl.dsp.window.alter_zorder({
            window = "address:" .. peer.address, mode = "bottom",
          }))
        end
      end
    elseif active.floating or opened then
      if not active.floating then
        -- Scrolling can tile a new window despite the personal float rule.
        -- Tiled windows cannot rise above floats: float the focused newcomer
        -- in place after opening has settled, without redirecting focus.
        local at, size = active.at, active.size
        local target = "address:" .. address
        hl.dispatch(hl.dsp.window.float({ window = target, action = "on" }))
        hl.dispatch(hl.dsp.window.resize({
          window = target, x = size[1], y = size[2], relative = false,
        }))
        hl.dispatch(hl.dsp.window.move({
          window = target, x = at[1], y = at[2], relative = false,
        }))
      end
      -- Raising also lets a focused float appear over a fullscreen app. Do not
      -- unfullscreen that app or change the target's geometry/workspace.
      hl.dispatch(hl.dsp.window.alter_zorder({
        window = "address:" .. address, mode = "top",
      }))
    end
  end, { type = "oneshot", timeout = 1 })
end

hl.on("window.active", function(window) foreground(window, false) end)
-- Lua's window.open runs after layout/focus initialization (openLate).
hl.on("window.open", function(window) foreground(window, true) end)
