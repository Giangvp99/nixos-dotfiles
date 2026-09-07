local M = {}

function M.reload(module)
	package.loaded[module] = nil

	local ok, err = pcall(require, module)

	if not ok then
		vim.notify("Failed to reload " .. module .. "\n" .. err, vim.log.levels.ERROR)
		return
	end

	vim.notify("Reloaded " .. module, vim.log.levels.INFO)
end

return M
