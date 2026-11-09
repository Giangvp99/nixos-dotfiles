# Bar Popups

Popup components opened from widgets in the top bar.

## Rules

- A popup is responsible only for presentation and interaction.
- System state belongs to `services/`.
- Popups must not call shell commands directly.
- Prefer native Quickshell APIs.
- Popup positioning is anchored to the widget that opened it.
- Larger features should be moved into their own module when they outgrow the bar.

## Adding a popup

1. Copy `Template.qml`.
2. Add the new type to `qmldir`.
3. Pass an anchor item from the owning widget.
4. Read state/actions through services.
5. Keep popup-specific state local to the popup.
