# Dark Dracula

Source palette: [Dracula's official contribution palette](https://draculatheme.com/contribute).
The live sources remain QML/Lua, without generation or a Nix rebuild.

| Role | Color |
| --- | --- |
| Background | `#282a36` |
| Deep/input | `#21222c` |
| Raised surface | `#343746` |
| Hover surface | `#393c4d` |
| Pressed surface | deep/input |
| Foreground | `#f8f8f2` |
| Secondary text | `#b6bbd2` |
| Comment/decorative | `#6272a4` |
| Primary/focus | `#bd93f9` |
| Pink accent | `#ff79c6` |
| Info/download | `#8be9fd` |
| Success/upload | `#50fa7b` |
| Warning/minimized | `#f1fa8c` |
| Urgent | `#ff5555` |
| Orange | `#ffb86c` |
| Border/neutral selection | `#44475a` |

Deep/raised/hover surfaces and secondary text are UI adaptations. The original
Comment color remains decorative rather than being used for small secondary
labels. Standard body, secondary labels, accent labels on hover/pressed and
selected text were checked for contrast. Text selection uses a purple background
and dark onAccent text, consistently in launcher, shortcut search, focus duration
and notes. Scrollbars use StyledScrollBar with the same palette; dense topbar
scroll indication uses the purple accent.

`config/Theme.qml` is the shell's single source of color tokens. All existing
bar widgets, dashboard cards, launcher, shortcut overlay, notification previews/
reader/toasts, audio OSD, charts and popups consume these tokens. Download arrows
use cyan and upload arrows use green. Application artwork and branded app icons
retain their original colors.

`../../hypr/config/theme.lua` mirrors the relevant compositor colors:

- active border: purple → pink, existing 45-degree gradient;
- inactive border: `#44475a`;
- shadow: `0xee191a21` (ARGB);
- empty-desktop fallback background: `#282a36` (no wallpaper change).

Hyprland's `rgba(...)` strings use RRGGBBAA; QML eight-digit colors use AARRGGBB.
The overlay is translucent deep Dracula (`#9921222c`). Geometry, fonts, animation,
blur passes, shadow extent, workspace behavior and live symlinks are unchanged.
No laptop-specific settings, Flake/NixOS/Home Manager modules or packages change.

Validation on j4n9-proxmox: QML lint, Lua syntax, live Hyprland reload/getoption/
configerrors, Quickshell source reload and visual checks. Existing dashboard,
shortcut, notification reader and widget fixtures exercise the shared controls.
Logs: `/tmp/dracula-qmllint.log` and each fixture's normal `/tmp/*-tests.log`.
