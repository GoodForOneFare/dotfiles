-- Validate personal input overrides without touching the live compositor.
local config
hl = { config = function(value) config = value end }
dofile("hypr/.config/hypr/personal/input.lua")
assert(config.cursor.no_warps == true, "Keyboard focus must preserve pointer position")
assert(config.input.touchpad.scroll_factor == 0.7, "Preserve approved scroll speed")
assert(config.input.touchpad.natural_scroll == false, "Preserve scrolling direction")
assert(config.input.kb_options == "caps:hyper,shift:both_capslock_cancel")
print("Personal input and no-pointer-warp checks passed.")
