-- ============================================================================
-- Mode Manager
-- ============================================================================

local Config = require("modes.config")

local M = {}

-- ============================================================================
-- Helpers
-- ============================================================================

local function named_workspace(name)
	return "name:" .. name
end

local function monitor_name(monitor)
	if monitor == nil then
		return nil
	end

	return monitor.name
end

local function monitor_exists(monitors, target)
	if target == nil then
		return false
	end

	local target_name = monitor_name(target)

	for _, monitor in ipairs(monitors) do
		if monitor_name(monitor) == target_name then
			return true
		end
	end

	return false
end

local function copy_monitors()
	local result = {}

	local monitors = hl.get_monitors()

	if monitors == nil then
		return result
	end

	for _, monitor in pairs(monitors) do
		table.insert(result, monitor)
	end

	-- Fallback ổn định:
	-- trái -> phải, sau đó trên -> dưới.
	table.sort(result, function(a, b)
		local ax = a.position and a.position.x or 0

		local bx = b.position and b.position.x or 0

		if ax ~= bx then
			return ax < bx
		end

		local ay = a.position and a.position.y or 0

		local by = b.position and b.position.y or 0

		return ay < by
	end)

	return result
end

local function find_preferred_monitor(monitors, preferred, excluded)
	if preferred == nil then
		return nil
	end

	for _, wanted_name in ipairs(preferred) do
		for _, monitor in ipairs(monitors) do
			if monitor_name(monitor) == wanted_name and monitor ~= excluded then
				return monitor
			end
		end
	end

	return nil
end

-- ============================================================================
-- Topology
-- ============================================================================

function M.get_topology()
	local monitors = copy_monitors()

	if #monitors == 0 then
		return {
			count = 0,
			primary = nil,
			secondary = nil,
		}
	end

	local primary = find_preferred_monitor(monitors, Config.monitors.preferred_primary, nil)

	if primary == nil then
		primary = monitors[1]
	end

	local secondary = find_preferred_monitor(monitors, Config.monitors.preferred_secondary, primary)

	-- Nếu chưa cấu hình secondary cụ thể,
	-- lấy monitor đầu tiên khác primary.
	if secondary == nil then
		for _, monitor in ipairs(monitors) do
			if monitor_name(monitor) ~= monitor_name(primary) then
				secondary = monitor
				break
			end
		end
	end

	return {
		count = #monitors,
		monitors = monitors,
		primary = primary,
		secondary = secondary,
	}
end

-- ============================================================================
-- Mode helpers
-- ============================================================================

function M.get_mode(id)
	return Config.modes[id]
end

function M.get_mode_from_workspace(workspace)
	if workspace == nil then
		return nil
	end

	local name = workspace.name

	if name == nil then
		return nil
	end

	for mode_id, mode in pairs(Config.modes) do
		if name == mode.lanes.primary or name == mode.lanes.secondary then
			return mode_id, mode
		end
	end

	return nil
end

function M.get_current_mode()
	local workspace = hl.get_active_workspace()

	return M.get_mode_from_workspace(workspace)
end

-- ============================================================================
-- Workspace rules
-- ============================================================================

local function configure_workspace(name)
	hl.workspace_rule({
		workspace = named_workspace(name),

		-- Mode workspaces luôn sử dụng scrolling.
		layout = "scrolling",

		-- Không biến mất khi tạm thời không có cửa sổ.
		persistent = true,

		layout_opts = {
			direction = "right",
		},
	})
end

for _, mode in pairs(Config.modes) do
	configure_workspace(mode.lanes.primary)
	configure_workspace(mode.lanes.secondary)
end

-- ============================================================================
-- Workspace window helper
-- ============================================================================

local function workspace_windows(name)
	local selector = named_workspace(name)

	-- Hyprland mới có helper này.
	if hl.get_workspace_windows ~= nil then
		return hl.get_workspace_windows(selector) or {}
	end

	-- Fallback cho build cũ hơn.
	local result = {}

	for _, window in ipairs(hl.get_windows()) do
		if window.workspace ~= nil and window.workspace.name == name then
			table.insert(result, window)
		end
	end

	return result
end

-- ============================================================================
-- Collapse / expand secondary lane
-- ============================================================================

local function return_tag(mode_id)
	return "mode-return-secondary-" .. mode_id
end

--
-- 2 monitors
--
-- primary      secondary
--    ↓             ↓
-- [ A B ]       [ C D ]
--
-- 1 monitor
--
-- [ A B C D ]
--
local function collapse_secondary(mode_id)
	local mode = Config.modes[mode_id]

	if mode == nil then
		return
	end

	local primary = mode.lanes.primary

	local secondary = mode.lanes.secondary

	local tag = return_tag(mode_id)

	local windows = workspace_windows(secondary)

	for _, window in ipairs(windows) do
		-- Ghi nhớ rằng window này vốn thuộc secondary lane.
		hl.dispatch(hl.dsp.window.tag({
			window = window,
			tag = "+" .. tag,
		}))

		-- Sau đó chuyển nó vào carousel primary.
		hl.dispatch(hl.dsp.window.move({
			window = window,
			workspace = named_workspace(primary),
			follow = false,
		}))
	end
end

local function expand_secondary(mode_id)
	local mode = Config.modes[mode_id]

	if mode == nil then
		return
	end

	local secondary = mode.lanes.secondary

	local tag = return_tag(mode_id)

	while true do
		local window = hl.get_window("tag:" .. tag)

		if window == nil then
			break
		end

		-- Trả window về secondary lane.
		hl.dispatch(hl.dsp.window.move({
			window = window,
			workspace = named_workspace(secondary),
			follow = false,
		}))

		-- Xóa marker vì topology đã được restore.
		hl.dispatch(hl.dsp.window.tag({
			window = window,
			tag = "-" .. tag,
		}))
	end
end

-- ============================================================================
-- Display workspace on monitor
-- ============================================================================

local function show_workspace_on_monitor(workspace_name, monitor)
	if monitor == nil then
		return
	end

	-- Focus physical monitor trước.
	hl.dispatch(hl.dsp.focus({
		monitor = monitor,
	}))

	-- Sau đó activate workspace của Mode trên chính monitor đó.
	--
	-- on_current_monitor rất quan trọng khi workspace trước đó
	-- đang nằm trên monitor khác.
	hl.dispatch(hl.dsp.focus({
		workspace = named_workspace(workspace_name),
		on_current_monitor = true,
	}))
end

-- ============================================================================
-- Switch Mode
-- ============================================================================

function M.switch(mode_id)
	local mode = Config.modes[mode_id]

	if mode == nil then
		return
	end

	local topology = M.get_topology()

	if topology.primary == nil then
		return
	end

	-- Nhớ monitor người dùng đang thao tác.
	local previous_monitor = hl.get_active_monitor()

	-- ------------------------------------------------------------------------
	-- 2 monitors
	-- ------------------------------------------------------------------------

	if topology.secondary ~= nil then
		-- Nếu trước đó chạy ở nhà với một monitor,
		-- restore các window secondary trước.
		expand_secondary(mode_id)

		show_workspace_on_monitor(mode.lanes.primary, topology.primary)

		show_workspace_on_monitor(mode.lanes.secondary, topology.secondary)

	-- ------------------------------------------------------------------------
	-- 1 monitor
	-- ------------------------------------------------------------------------
	else
		-- Merge secondary carousel vào primary.
		collapse_secondary(mode_id)

		show_workspace_on_monitor(mode.lanes.primary, topology.primary)
	end

	-- ------------------------------------------------------------------------
	-- Restore focused physical monitor
	-- ------------------------------------------------------------------------

	local monitors = topology.monitors or {}

	if previous_monitor ~= nil and monitor_exists(monitors, previous_monitor) then
		hl.dispatch(hl.dsp.focus({
			monitor = previous_monitor,
		}))
	end
end

-- ============================================================================
-- App navigation
-- ============================================================================

function M.focus_app(direction)
	local workspace = hl.get_active_workspace()

	if workspace == nil then
		return
	end

	--
	-- Trong Mode workspace:
	-- dùng navigation native của scrolling layout.
	--
	if workspace.tiled_layout == "scrolling" then
		hl.dispatch(hl.dsp.layout("focus " .. direction))

		return
	end

	--
	-- Ngoài Mode:
	-- fallback về directional focus thông thường.
	--
	hl.dispatch(hl.dsp.focus({
		direction = direction,
	}))
end

function M.swap_app(direction)
	local workspace = hl.get_active_workspace()

	if workspace == nil or workspace.tiled_layout ~= "scrolling" then
		return
	end

	-- Đổi column thực tế trong scrolling layout.
	hl.dispatch(hl.dsp.layout("swapcol " .. direction))

	-- QuickShell cần refresh IPC metadata để nhận tọa độ mới.
	--
	-- Không polling.
	-- Chỉ refresh đúng khi người dùng vừa reorder window.
	hl.exec_cmd("qs ipc call hyprlandService refreshOrder")
end

-- ============================================================================
-- Monitor navigation
-- ============================================================================

function M.focus_monitor(direction)
	hl.dispatch(hl.dsp.focus({
		monitor = direction,
	}))
end

-- ============================================================================
-- Reflow
-- ============================================================================

function M.refresh()
	local mode_id = M.get_current_mode()

	if mode_id == nil then
		return
	end

	M.switch(mode_id)
end

return M
