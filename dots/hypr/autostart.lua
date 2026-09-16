-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function()
	-- 	hl.exec_cmd("pidof nm-applet >/dev/null || np-applet")
	-- 	hl.exec_cmd("pidof waybar >/dev/null || waybar")
	-- 	hl.exec_cmd("pidof hyprpaper >/dev/null || hyprpaper")
	hl.exec_cmd("pidof quickshell >/dev/null || qs")
	hl.exec_cmd("fcitx5 --disable classicui -r > /dev/null 2>&1 &")
end)
