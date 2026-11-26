-- Replace Omarchy's left/right window focus (or omac's Home/End) with
-- application history navigation. Synthetic input bypasses compositor binds,
-- so this still sends Alt+arrow even if omac remaps physical Alt+arrow.
local function navigate(key)
  return function()
    -- Match Omarchy/omac's down/up workaround for stuck synthetic keys.
    hl.dispatch(hl.dsp.send_key_state({ mods = "ALT", key = key, state = "down" }))
    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = "ALT", key = key, state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end
end

o.rebind("SUPER + LEFT", "Back", navigate("LEFT"))
o.rebind("SUPER + RIGHT", "Forward", navigate("RIGHT"))
