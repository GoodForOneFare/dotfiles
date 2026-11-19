-- Caps is Hyper/Mod3, not Compose. No privileged keyboard service required.
-- Disable omac's natural scrolling: fingers down scrolls down.
hl.config({
  -- Keyboard focus changes should never move the physical pointer.
  cursor = { no_warps = true },
  input = {
    kb_options = "caps:hyper,shift:both_capslock_cancel",
    -- Less restrained than Omarchy's 0.4; leave scrolling direction unchanged.
    touchpad = { natural_scroll = false, scroll_factor = 0.7 },
  },
})
