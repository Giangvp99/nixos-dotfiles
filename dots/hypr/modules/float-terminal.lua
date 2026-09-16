-- ============================================================================
-- Float Terminal
-- ============================================================================
--
-- Persistent Kitty scratchpad.
--
-- Super + T:
--   - chưa tồn tại -> tạo terminal
--   - đang ẩn      -> hiện + focus
--   - đang hiện    -> ẩn
--
-- Float terminal luôn dùng input trực tiếp (EN),
-- không kết nối Wayland IME / Fcitx.
-- ============================================================================

local M = {}

local config = {
	class = "float-terminal",
	workspace = "float-terminal",

	-- Chỉ instance này không dùng Fcitx/Wayland IME.
	command = "kitty --class float-terminal -o wayland_enable_ime=no",

	width = "monitor_w * 0.72",
	height = "monitor_h * 0.48",

	x = "(monitor_w - window_w) / 2",
	y = "45",
}

-- ============================================================================
-- Helpers
-- ============================================================================

local function is_float_terminal(window)
	return window ~= nil and window.class == config.class
end

local function is_float_workspace(workspace)
	if workspace == nil then
		return false
	end

	return workspace.name == config.workspace or workspace.name == ("special:" .. config.workspace)
end

local function get_terminal()
	for _, window in ipairs(hl.get_windows()) do
		if is_float_terminal(window) then
			return window
		end
	end

	return nil
end

local function is_visible()
	return is_float_workspace(hl.get_active_special_workspace())
end

local function toggle_workspace()
	hl.dispatch(hl.dsp.workspace.toggle_special(config.workspace))
end

local function spawn_terminal()
	hl.exec_cmd(config.command)
end

local function focus_terminal(window)
	if window == nil then
		return
	end

	hl.dispatch(hl.dsp.focus({
		window = window,
	}))
end

-- ============================================================================
-- Show
-- ============================================================================

local function show_terminal(window)
	if window == nil then
		return
	end

	-- Nếu scratchpad chưa hiện thì mở nó.
	if not is_visible() then
		toggle_workspace()
	end

	-- Dispatcher của Hyprland chạy trực tiếp trong compositor.
	-- Sau khi special workspace được mở, focus đúng window.
	focus_terminal(window)
end

-- ============================================================================
-- Window rules
-- ============================================================================

hl.window_rule({
	name = "float-terminal",

	match = {
		class = "^" .. config.class .. "$",
	},

	float = true,

	workspace = "special:" .. config.workspace .. " silent",

	size = {
		config.width,
		config.height,
	},

	move = {
		config.x,
		config.y,
	},
})

-- ============================================================================
-- Toggle
-- ============================================================================

local function toggle()
	local terminal = get_terminal()

	-- Chưa tồn tại -> spawn.
	--
	-- Khi Kitty map xong, window.open phía dưới sẽ show + focus.
	if terminal == nil then
		spawn_terminal()
		return
	end

	-- Đang hiện -> chỉ ẩn.
	-- Process Kitty vẫn sống.
	if is_visible() then
		toggle_workspace()
		return
	end

	-- Đang ẩn -> hiện + focus.
	show_terminal(terminal)
end

-- ============================================================================
-- First spawn
-- ============================================================================

hl.on("window.open", function(window)
	if not is_float_terminal(window) then
		return
	end

	-- window.open xảy ra sau khi window đã được khởi tạo
	-- và window rules đã được áp dụng.
	--
	-- Lúc này window đã nằm ở special:float-terminal,
	-- nên có thể show và focus trực tiếp.
	show_terminal(window)
end)

-- ============================================================================
-- Keybind
-- ============================================================================

hl.bind("SUPER + RETURN", toggle, {
	description = "Toggle float terminal",
})

return M
