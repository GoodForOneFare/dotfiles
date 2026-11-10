-- Start the stock session-scoped service at login, without globally enabling it.
-- The all-day temperature is configured in hypr/hyprsunset.conf.
o.exec_on_start("systemctl --user start hyprsunset.service")
