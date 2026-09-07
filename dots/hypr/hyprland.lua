-- ~/.config/hypr/hyprland.lua
--
-- Hyprland Lua configuration entrypoint.
-- Keep this file small. Actual configuration lives in modules.

local config_dir = "/etc/nixos/dots/hypr"

package.path = config_dir .. "/?.lua;" .. config_dir .. "/?/init.lua;" .. package.path

require("monitors")
require("config.general")
require("config.decoration")
require("config.input")
require("config.laf")

require("rules")
require("binds")
require("permissions")

require("autostart")
