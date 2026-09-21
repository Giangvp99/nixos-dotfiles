local mainMod = "SUPER" -- Sets "Windows" key as main modifier
local returnKey = "Return"

local terminal = "kitty"
local fileManager = "dolphin"
-- local menu = "fuzzel"
local browser = "brave"

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + SHIFT + " .. returnKey, hl.dsp.exec_cmd(terminal))
local closeWindowBind = hl.bind(mainMod .. " + Q", hl.dsp.window.close())
-- closeWindowBind:set_enabled(false)
hl.bind(
	mainMod .. " + SHIFT + M",
	hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
)

hl.bind(mainMod .. " + SPACE", hl.dsp.global("quickshell:launcher"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
-- hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
-- hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
-- hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle only
-- hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("fuzzel"))
-- Move focus with mainMod + arrow keys
-- hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
-- hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- ============================================================================
-- Minimize state
-- ============================================================================

-- ============================================================================
-- Minimize / Restore
-- ============================================================================

local minimized_origin = nil

local function workspace_selector(workspace)
	if workspace == nil then
		return nil
	end

	local name = workspace.name

	if name == nil then
		return nil
	end

	-- Named workspace:
	--
	-- mode-writing-primary
	-- ->
	-- name:mode-writing-primary
	if not name:match("^%d+$") then
		return "name:" .. name
	end

	-- Numeric workspace:
	--
	-- "1"
	-- ->
	-- "1"
	return name
end

hl.bind(mainMod .. " + M", function()
	local minimized = hl.get_window("tag:minimized")

	-- ========================================================================
	-- RESTORE
	-- ========================================================================

	if minimized ~= nil then
		-- Workspace gốc đã được lưu lúc minimize.
		local target = minimized_origin

		-- Fallback chỉ dùng khi state bị mất do reload config.
		if target == nil then
			target = workspace_selector(hl.get_active_workspace())
		end

		if target == nil then
			return
		end

		-- Đưa window về đúng workspace gốc.
		hl.dispatch(hl.dsp.window.move({
			window = minimized,
			workspace = target,
			follow = false,
		}))

		-- Chuyển người dùng về workspace gốc.
		hl.dispatch(hl.dsp.focus({
			workspace = target,
		}))

		-- Focus window vừa restore.
		hl.dispatch(hl.dsp.focus({
			window = minimized,
		}))

		-- Bỏ tag minimize.
		hl.dispatch(hl.dsp.window.clear_tags({
			window = minimized,
		}))

		minimized_origin = nil

		return
	end

	-- ========================================================================
	-- MINIMIZE
	-- ========================================================================

	local active_window = hl.get_active_window()

	local active_workspace = hl.get_active_workspace()

	if active_window == nil or active_workspace == nil then
		return
	end

	-- QUAN TRỌNG:
	-- lưu workspace TRƯỚC KHI move window.
	minimized_origin = workspace_selector(active_workspace)

	-- Ví dụ:
	--
	-- mode-writing-primary
	-- ->
	-- name:mode-writing-primary

	hl.dispatch(hl.dsp.window.tag({
		window = active_window,
		tag = "minimized",
	}))

	hl.dispatch(hl.dsp.window.move({
		window = active_window,
		workspace = "special:minimized",
		follow = false,
	}))
end)

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
-- for i = 1, 10 do
-- 	local key = i % 10 -- 10 maps to key 0
-- 	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
-- 	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
-- end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
-- hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
-- hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
-- hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
-- hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Screenshot selected area -> Swappy
hl.bind("Print", hl.dsp.exec_cmd("screenshot-area"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("screenshot-output"))
