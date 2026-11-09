-- Edge-to-edge windows. Keep fractional scrolling columns gap-free.
hl.config({
  general = { gaps_in = 0, gaps_out = 0, border_size = 0 },
  scrolling = { column_width = 0.5 },
})
o.window(".*", { opacity = "1.0 override 1.0 override 1.0 override" })
