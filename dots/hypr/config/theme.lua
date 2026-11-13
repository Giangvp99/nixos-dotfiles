-- Dracula palette shared visually with dots/quickshell/config/Theme.qml.
-- Keep geometry/effects in their existing modules; this module owns colors only.
local theme = {
    background = "282a36",
    selection = "44475a",
    purple = "bd93f9",
    pink = "ff79c6",
    shadow = 0xee191a21,
}

function theme.rgba(color)
    return "rgba(" .. color .. "ff)"
end

return theme
