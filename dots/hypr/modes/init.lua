-- ============================================================================
-- Mode subsystem
-- ============================================================================

local Config = require("modes.config")

local Mode = require("modes.core")

require("modes.binds")

-- ============================================================================
-- Startup
-- ============================================================================
--
-- Hyprland mặc định khởi động ở workspace 1.
--
-- Workspace 1 không thuộc Mode nào, nên nếu người dùng mở ứng dụng trước khi
-- bấm Super+1/2/3, window đó sẽ bị nằm ngoài hệ thống Mode.
--
-- Khi Hyprland thực sự start, tự chuyển sang default_mode.
--
-- Không gọi Mode.switch() trực tiếp lúc load file vì config này live reload.
-- Nếu gọi trực tiếp, mỗi lần save config sẽ bị kéo về Writing.
-- ============================================================================

hl.on("hyprland.start", function()
	Mode.switch(Config.default_mode)
end)

return Mode
