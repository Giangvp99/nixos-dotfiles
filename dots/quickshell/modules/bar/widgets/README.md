# Bar Widgets

Widget là UI domain-specific của topbar.

## Widget responsibilities

Được:

- đọc service;
- sử dụng reusable component;
- format dữ liệu cho display;
- gửi action về service.

Không được:

- tự chạy polling nếu service đã cung cấp dữ liệu;
- tự sở hữu duplicate system state;
- chứa popup lớn;
- hardcode theme token.

## Template workflow

Copy:

    Template.qml

thành:

    Audio.qml

Sau đó:

1. đổi tên root;
2. import service;
3. xây visual bằng components;
4. thêm vào qmldir;
5. compose trong BarLeft/Center/Right.

## Shared topbar appearance

Use `Components.StatusText` for information and `Components.IconButton` for
interactive controls. IconButton extends StatusText; keep padding, typography,
border and state styling there rather than duplicating a RowLayout.

- Control height 28 px, radius 6 px, horizontal padding 10 px, icon/text gap 6 px.
- UI text 13 px; clock uses the shared DemiBold emphasis weight.
- Status icons 16 px from `iconFontFamily`; desktop app icons 18 px.
- Both control types use `Theme.controlBackground`. Interactive controls add
  hover/pressed feedback; passive status controls keep their background stable.
- No normal border; keyboard focus uses a 1 px accent border.
- `active` means selected/open, not merely clickable. Use `popup.visible` on
  popup triggers. Selected icons use accent; text-only triggers accent the text.
- Battery low uses warning; urgent apps use urgent; minimized apps keep their
  marker and lower icon opacity. App images keep their original colors.
- Widgets do not display tooltips (user preference). Preserve readable
  Accessible.name values for icon-only buttons and app entries.
- Hover color transitions use Animations.fast and standardEasing; reducedMotion
  remains supported. Widgets must not introduce separate animation durations.
- Audio uses IconButton.scrolled with wheelEnabled; other buttons pass wheel
  events through so the surrounding scrollable bar can handle them.

All appearance values above are defined in `config/Theme.qml` and
`config/Config.qml`. Preserve current unavailable-hardware visibility rules.

Validated on j4n9-proxmox (2026-11-10): live reload, qmllint, 640 px bar,
shared control dimensions/colors and bounded labels. Tooltip support and its
config tokens were subsequently removed at the user's request. Popup interaction
validation is documented in `../popups/README.md`.

The Notifications bell reads only NotificationState, so an always-loaded bar does
not claim the notification service while its optional backend is off. It shows
unread count/DND and uses the shared popup lifecycle. See notifications/CENTER.md.
