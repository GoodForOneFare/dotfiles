-- App activation can change keyboard focus without raising a floating window.
-- Keep stacking in sync with focus, including notifications and browser links.
-- Fullscreen targets also need their old above-fullscreen overlays cleared.
-- Hyprland 0.56.2's window.active reason enum (FocusState.hpp): workspace
-- return picks the fullscreen owner instead of the workspace's previous float.
local WORKSPACE_CHANGE = 11
local remembered, ranks = {}, {}
-- Seed from MRU on reload, without changing focus or stacking anywhere.
for _, window in ipairs(hl.get_windows() or {}) do
  local id = window.workspace and window.workspace.id
  local rank = window.focus_history_id
  if id and window.mapped and not window.pinned and rank and rank >= 0
      and (not ranks[id] or rank < ranks[id]) then
    remembered[id], ranks[id] = window.address, rank
  end
end

local function foreground(window, opened, reason)
  if not window then return end
  local address = window.address
  local id = window.workspace and window.workspace.id
  local restore = reason == WORKSPACE_CHANGE and id and remembered[id]
  -- Automatic workspace focus must not overwrite what the user last chose.
  if id and reason ~= WORKSPACE_CHANGE and window.mapped and not window.pinned then
    remembered[id] = address
  end
  -- Focus is still being committed inside the event. Re-resolve on the next
  -- turn and never redirect focus if the user has already switched again.
  hl.timer(function()
    local active = hl.get_active_window()
    if not active or active.address ~= address or not active.mapped
        or not active.workspace then return end
    if (active.fullscreen or 0) ~= 0 then
      local peers = hl.get_windows()
      if restore and restore ~= address then
        for _, peer in ipairs(peers) do
          if peer.address == restore and peer.mapped and peer.floating
              and not peer.pinned and (peer.fullscreen or 0) == 0
              and peer.workspace and peer.workspace.id == active.workspace.id then
            -- Only the workspace just entered is touched. Focus/raise a prior
            -- float, leaving the fullscreen owner and all other workspaces alone.
            hl.dispatch(hl.dsp.focus({ window = "address:" .. restore }))
            hl.dispatch(hl.dsp.window.alter_zorder({
              window = "address:" .. restore, mode = "top",
            }))
            return
          end
        end
      end
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
          window = target, x = size.x, y = size.y, relative = false,
        }))
        hl.dispatch(hl.dsp.window.move({
          window = target, x = at.x, y = at.y, relative = false,
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

hl.on("window.active", function(window, reason) foreground(window, false, reason) end)
-- Lua's window.open runs after layout/focus initialization (openLate).
hl.on("window.open", function(window) foreground(window, true) end)
