-- Start the user-owned corner watcher with the desktop; no global enablement.
-- It controls only Omarchy's idle policy, never manual locking or lid sleep.
o.exec_on_start("systemctl --user start dotfiles-hot-corner.service")
