-- App activation can change keyboard focus without raising a floating window.
-- Keep stacking in sync with focus, including notifications and browser links.
-- Fullscreen targets also need their old above-fullscreen overlays cleared.
hl.on("window.active", function(window)
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
    elseif active.floating then
      -- Raising also lets a focused float appear over a fullscreen app. Do not
      -- unfullscreen that app or change the target's geometry/workspace.
      hl.dispatch(hl.dsp.window.alter_zorder({
        window = "address:" .. address, mode = "top",
      }))
    end
  end, { type = "oneshot", timeout = 1 })
end)
