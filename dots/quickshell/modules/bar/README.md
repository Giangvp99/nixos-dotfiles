# Bar Module

`shell.qml` creates `Bars.qml`, which uses Variants to create one `Bar.qml` for
each Quickshell screen. `Bar.qml` remains a directly instantiable PanelWindow for
isolated tests. Each reserves only the top area of its own screen.

BarLeft contains Dashboard, ModeIndicator and RunningApps. Its workspace/monitor
come from the owning bar; mode and normal/minimized window lists therefore
follow that screen. BarCenter optionally shows that workspace's window title.
BarRight composes the existing compact metrics and fixed essential controls;
widget dimensions and telemetry services remain shared/unchanged.

Widgets bind to services. Popups anchor to their own bar and close on screen
loss; PopupState enforces global popup exclusivity. Notification centers register
per screen while sharing the same notification state. See
[MULTISCREEN](../../docs/MULTISCREEN.md) for routing policy and tests.

When adding a widget: create/reuse its service, export the widget in qmldir,
compose it into the appropriate bar group, and update documentation. Keep system
logic in services and pass screen/workspace context explicitly when relevant.
