-- Run from the repository root: lua dots/hypr/tests/modes.lua
package.path = "dots/hypr/?.lua;" .. package.path
local config = require("modes.config")
local monitors, windows, active, workspace, calls, frozen
local rules, callbacks = {}, {}
local function command(kind, args)
	return { kind = kind, args = args }
end
hl = {
	get_monitors = function() return monitors end,
	get_windows = function() return windows end,
	get_active_monitor = function() return active end,
	get_active_workspace = function() return workspace end,
	workspace_rule = function(rule) table.insert(rules, rule) end,
	on = function(event, callback) callbacks[event] = callback end,
	bind = function() end,
	dsp = {
		window = {
			tag = function(args) return command("tag", args) end,
			move = function(args) return command("move", args) end,
		},
		focus = function(args) return command("focus", args) end,
		layout = function(args) return command("layout", args) end,
	},
	dispatch = function(cmd)
		table.insert(calls, cmd)
		assert(#calls < 100, "dispatch loop did not terminate")
		local args = cmd.args
		if cmd.kind == "move" then
			assert(args.follow == false)
			args.window.workspace = { name = args.workspace:gsub("^name:", "") }
		elseif cmd.kind == "tag" and not frozen then
			local tags = args.window.tags
			if args.tag:sub(1, 1) == "+" then
				table.insert(tags, args.tag:sub(2))
			elseif type(tags) == "table" then
				for i = #tags, 1, -1 do
					if tags[i] == args.tag:sub(2) then table.remove(tags, i) end
				end
			end
		elseif cmd.kind == "focus" and args.monitor then
			active = args.monitor
		end
	end,
}
local mode = require("modes.core")
assert(#rules == 6)
local left = { name = "VM-1", position = { x = 0, y = 0 } }
local right = { name = "VM-2", position = { x = 1920, y = 0 } }
local function reset()
	monitors, windows, calls = { left }, {}, {}
	active, frozen = left, false
	workspace = { name = config.modes.writing.lanes.primary }
end
local function window(name, tags)
	local value = { workspace = { name = name }, tags = tags or {} }
	table.insert(windows, value)
	return value
end
local count = 0
local function test(name, fn)
	reset()
	fn()
	count = count + 1
	print("PASS " .. name)
end
for id, definition in pairs(config.modes) do
	test(id .. ": 1 -> 2 -> 1 monitors and focus", function()
		local primary = window(definition.lanes.primary)
		local secondary = window(definition.lanes.secondary)
		mode.switch(id)
		assert(secondary.workspace.name == definition.lanes.primary)
		assert(secondary.tags[1] == "mode-return-secondary-" .. id)
		monitors, active = { right, left }, right
		mode.switch(id)
		assert(secondary.workspace.name == definition.lanes.secondary)
		assert(#secondary.tags == 0 and active == right)
		assert(primary.workspace.name == definition.lanes.primary)
		monitors = { left }
		mode.switch(id)
		assert(secondary.workspace.name == definition.lanes.primary and active == left)
	end)
end
test("minimized tag/workspace stay hidden; later refresh restores lane", function()
	local tag = "mode-return-secondary-writing"
	local hidden = window("special:minimized", { tag, "minimized", "minimized-from-name:mode-writing-primary" })
	local tagged = window("mode-writing-primary", { tag, "minimized" })
	local special = window("special:minimized", { tag })
	local visible = window("mode-writing-primary", { tag })
	local other = window("mode-code-primary", { "mode-return-secondary-code" })
	monitors = { left, right }
	mode.refresh()
	assert(hidden.workspace.name == "special:minimized" and #hidden.tags == 3)
	assert(tagged.workspace.name == "mode-writing-primary" and #tagged.tags == 2)
	assert(special.workspace.name == "special:minimized")
	assert(visible.workspace.name == "mode-writing-secondary" and #visible.tags == 0)
	assert(other.workspace.name == "mode-code-primary")
	hidden.workspace.name, hidden.tags = "mode-writing-primary", { tag }
	mode.refresh()
	assert(hidden.workspace.name == "mode-writing-secondary" and #hidden.tags == 0)
end)
test("unchanged string/table tags cannot cause repeated dispatch", function()
	monitors, frozen = { left, right }, true
	window("mode-writing-primary", "unrelated,mode-return-secondary-writing")
	window("mode-writing-primary", { "mode-return-secondary-writing" })
	mode.switch("writing")
	assert(#calls == 9)
end)
test("missing monitors/unknown mode do nothing", function()
	monitors = {}
	mode.switch("writing")
	mode.switch("unknown")
	assert(#calls == 0)
end)
test("preferred monitor and stable spatial ordering", function()
	local preferred = { name = "eDP-1", position = { x = 3840, y = 0 } }
	monitors = { right, preferred, left }
	local topology = mode.get_topology()
	assert(topology.primary == preferred and topology.secondary == left)
end)
test("module reload does not switch mode; startup still does", function()
	package.loaded["modes.core"] = nil
	package.loaded["modes.init"] = nil
	require("modes.init")
	assert(#calls == 0)
	assert(callbacks["hyprland.start"])
	callbacks["hyprland.start"]()
	assert(#calls > 0)
end)
print(string.format("%d scenarios passed", count))
