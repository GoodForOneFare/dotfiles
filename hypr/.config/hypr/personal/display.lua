-- Built-in Dell display: native 2880x1800 at 1.5x gives 1920x1200 logical.
-- External displays keep the normal settings in hypr/monitors.lua.
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.5 })
