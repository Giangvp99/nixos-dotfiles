-- Temporary toplevel dialogs only; menus/xdg_popups are positioned by their clients.
-- https://wiki.hypr.land/configuring/core/rules/window-rules/
local M = {}

-- Expressions use the owning monitor's logical size, including its scale.
M.bounds = { "monitor_w * 0.86", "monitor_h * 0.80" }
M.file_size = { "monitor_w * 0.66", "monitor_h * 0.70" }
M.download_size = { "monitor_w * 0.52", "monitor_h * 0.46" }

-- Anchored titles avoid matching normal browser pages such as "Downloads - Brave".
-- Every title match also requires a modal or already-floating window, or a portal class.
M.file_titles = [[(?i)^(save( as| file| image| image as| link as| page as| a file)?|open( file| files| folder)?|select( file| files| folder| a file| a folder)?|choose( file| files| folder| a file| a folder)?|file (upload|chooser)|upload file|lưu( thành| dưới dạng| với tên| tệp| tập tin| ảnh)?|mở( tệp| tập tin| thư mục)?|chọn( tệp| tập tin| thư mục)?)(\.{3}|…)?$]]
M.download_titles = [[(?i)^(download|downloads|downloading|download file|download progress|download status|tải xuống|đang tải xuống)(\.{3}|…)?$]]
M.portal_classes = [[(?i)^(xdg-desktop-portal-(gtk|kde|gnome|lxqt)|org\.freedesktop\.impl\.portal\.desktop\.(gtk|kde|gnome|lxqt))$]]
M.confirmation_titles = [[(?i)^(are you sure\?|confirm(ation)?|confirm (save|replace|delete|overwrite)|replace( file| existing file)?|overwrite( file| existing file)?|authentication( required)?|authenticate|xác nhận|bạn có chắc chắn\?)(\.{3}|…)?$]]

local function rule(name, match, size, tag)
    hl.window_rule({
        name = name,
        match = match,
        float = true,
        center = true,
        max_size = M.bounds,
        size = size,
        tag = "+" .. tag,
    })
end

-- Small confirmation/authentication dialogs keep their requested natural size.
rule("temporary-modal-bounds", { modal = true }, nil, "temporary-dialog")
rule("temporary-portal-bounds", { class = M.portal_classes }, nil, "temporary-dialog")
rule("temporary-confirmation-floating", { float = true, initial_title = M.confirmation_titles }, nil, "temporary-dialog")

-- File pickers get enough room for the file list, path and Save/Open buttons.
rule("file-dialog-modal", { modal = true, initial_title = M.file_titles }, M.file_size, "file-dialog")
rule("file-dialog-portal", { class = M.portal_classes, initial_title = M.file_titles }, M.file_size, "file-dialog")
-- Qt/GTK transients do not always advertise modal through the Wayland protocol.
rule("file-dialog-floating-fallback", {
    float = true, initial_title = M.file_titles,
}, M.file_size, "file-dialog")

rule("download-dialog-modal", { modal = true, initial_title = M.download_titles }, M.download_size, "download-dialog")
rule("download-dialog-portal", { class = M.portal_classes, initial_title = M.download_titles }, M.download_size, "download-dialog")
rule("download-dialog-floating-fallback", {
    float = true, initial_title = M.download_titles,
}, M.download_size, "download-dialog")

return M
