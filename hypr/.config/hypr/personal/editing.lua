-- omac maps Alt+Backspace to Ctrl+W in terminals, which can delete a larger
-- whitespace-delimited chunk. Preserve the terminal application's native
-- Alt+Backspace word deletion instead. GUI apps still receive Ctrl+Backspace.
hl.unbind("ALT + BACKSPACE")
o.bind("ALT + BACKSPACE", "Delete one word backward", function()
  local window = hl.get_active_window()
  local terminal = window and window.class == "herdr-app"
  if window then
    for _, tag in ipairs(window.tags or {}) do
      if tag:gsub("%*$", "") == "terminal" then
        terminal = true
        break
      end
    end
  end

  -- The launcher search field is not the terminal beneath its overlay.
  for _, layer in ipairs(hl.get_layers() or {}) do
    if layer.namespace == "omacast" then
      terminal = false
      break
    end
  end

  if terminal then
    -- auto_consuming passes the original keypress through to the app.
    return { ok = false }
  end
  if not window then
    return { ok = false }
  end

  hl.dispatch(hl.dsp.send_key_state({ mods = "CTRL", key = "BACKSPACE", state = "down" }))
  hl.timer(function()
    hl.dispatch(hl.dsp.send_key_state({ mods = "CTRL", key = "BACKSPACE", state = "up" }))
  end, { timeout = 50, type = "oneshot" })
  return { ok = true }
end, { auto_consuming = true })
