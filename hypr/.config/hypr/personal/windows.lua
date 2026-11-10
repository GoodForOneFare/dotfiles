-- Rectangle-style manual placement instead of automatic tiling.
o.window(".*", { float = true })

-- Rectangle-style snapping. Caps Lock is Hyper/Mod3 (see input.lua).
-- Run the helper outside the compositor event loop and capture the target
-- window at keypress time, so a later focus change cannot redirect the snap.
local function snap_window(position)
  return function()
    local window = hl.get_active_window()
    if window then
      hl.exec_cmd(string.format("python3 %q %q %q",
        os.getenv("HOME") .. "/.local/bin/window-snap", position, window.address))
    end
  end
end

hl.unbind("MOD3 + 1")
hl.unbind("MOD3 + 2")
hl.unbind("MOD3 + LEFT")
hl.unbind("MOD3 + RIGHT")
o.bind("MOD3 + 1", "Snap window to left two-thirds", snap_window("left-two-thirds"))
o.bind("MOD3 + 2", "Snap window to right third", snap_window("right-third"))
o.bind("MOD3 + LEFT", "Snap window to left half", snap_window("left-half"))
o.bind("MOD3 + RIGHT", "Snap window to right half", snap_window("right-half"))
o.rebind("MOD3 + SPACE", "Fill screen without fullscreen", snap_window("maximize"))
