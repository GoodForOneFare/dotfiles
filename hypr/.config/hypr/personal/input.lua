-- Caps is Hyper/Mod3, not Compose. No privileged keyboard service required.
-- Disable omac's natural scrolling: fingers down scrolls down.
hl.config({
  input = {
    kb_options = "caps:hyper,shift:both_capslock_cancel",
    touchpad = { natural_scroll = false },
  },
})
