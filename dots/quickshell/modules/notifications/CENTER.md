# Notification center — stage 3, second iteration

Implemented and validated on j4n9-proxmox, 2026-11-10.

## User behavior

The topbar bell displays unread count (capped visually at 99+) and DND state.
It is disabled while the optional Quickshell notification backend is not loaded;
rendering the bell never initializes a native notification server. No tooltips.

Opening the center marks all history read. Notifications received while it is
open are also read and do not open competing toasts. Opening another bar popup
or the launcher closes the center. Same-button toggle, Escape and outside-click
behavior comes from the shared BarPopup/PopupState implementation.

The center is a compact newest-first list with two-line titles and four-line body
previews. Each snapshot retains up to 8192 body characters for the list. Click a
card, click Read notification, or press Enter/Space on a selected row to open a
separate reading mode in the same popup (up to 760×700 logical pixels, clamped
to the owning screen). The complete title/body appear there with a single scroll
area. Back/Escape returns to the selected row and its list position; a subsequent
Escape closes the center. Wheel, PageUp/PageDown and Up/Down scroll the reader.

Opening a reader never invokes the application's default action. Explicit native
action buttons remain available in the reader only while the native notification
is tracked. Archived notifications remain readable from their saved full text.
Remove and Clear all also release saved full payloads. Header DND, unread counts,
overlay exclusivity, no tooltips and compact toast previews remain unchanged.

Tab/Shift+Tab cycle controls in the active view and reveal action/remove buttons.
Up/Down in the list select rows; Delete removes a selected row. Transient messages
are excluded from both history and full-text storage.

## State and bounds

`services/NotificationState.qml` owns plain history snapshots, unread/read state,
DND and the center-open flag. It has no native server/API and is safe to reference
from the always-loaded bar. `NotificationService` remains the only server owner.

`ShellRoot` supplies a top-level PersistentProperties containing historyJson and detailsJson
(strings) and dnd (a boolean). NotificationState attaches after the reload stage.
JSON is serialized **in RAM only**, not written to a history file. Persisting a
raw JS array directly was rejected during validation because Qt cannot reassign
that JSValue to another engine. String snapshots are parsed by the new engine.

Reload preserves snapshots, unread flags and DND; native keepOnReload rebinds
live IDs without creating duplicate entries. Rebinding temporarily marks stored
rows archived until their live records return. Process restart/log out clears
history and DND. The existing PID/start-time runtime marker is unchanged and
contains only the notification backend opt-in token, never history contents.

Defaults in Config.qml:

| Setting | Default |
| --- | --- |
| notificationHistoryLimit | 100 entries |
| notificationHistoryBodyLimit | 8192 characters per list preview |
| notificationReaderWidth / Height | 760 / 700 logical px |
| notificationFullTextBudget | 2097152 characters across saved full payloads |
| notificationCenterWidth | 420 logical px |
| notificationCenterHeight | 580 logical px |

Summary/app previews retain 4096/256 character bounds. Complete summary/body text
is stored separately by notification ID in detailsJson, in RAM only. It survives
native expiry and QML reload until removal, clearing, process exit or history
retention eviction. Native QObject/action references are never saved there.

Retention keeps at most 100 notifications and normally at most 2 Mi characters of
full text. When over budget, whole oldest notifications are evicted instead of
cutting their reader content. One oversized newest message is retained intact,
so the budget is a soft aggregate limit rather than a per-message truncation.
The original live-record expiry guards remain in force for evicted entries.

Older snapshots are migrated: any text still present is moved to detail storage
before their preview is shortened to 8K. If an older archived snapshot had already
lost text, the reader identifies it as a saved preview. Missing text cannot be
reconstructed; new messages retain their complete body.

Custom shell entrypoints must supply the PersistentProperties memory and call
NotificationState.attachMemory as shell.qml does before enabling the backend.
This state is deliberately outside the lazy toast module so UI lifetime is
independent from native notification lifetime.

## Files

- services/NotificationState.qml: snapshots/read/DND and guarded history actions.
- services/NotificationService.qml: snapshot/update/close integration, suppression
  and expiry of evicted live records.
- services/NotificationRecord.qml: suppressed-record one-shot lifetime.
- modules/bar/widgets/Notifications.qml: bell, unread badge and center trigger.
- NotificationCenter.qml: shared popup, virtualized list and keyboard navigation.
- NotificationHistoryItem.qml: snapshot presentation through ToastCard; live
  action labels are copied only for rendering and resolved by ID on invocation.
- ToastCard.qml: shared metadata/unread presentation and focus targets.
- shell.qml: in-memory reload storage; existing launcher closes the active popup.

## Validation

The full module tree was copied to `/tmp/notification-center-tree` with normal
relative imports. A private D-Bus without activatable services was used; no
handoff or daemon change was performed in the real desktop session.

QtTest TestEvent and native Notify/CloseNotification calls verified:

- Expiry leaves an unread archived snapshot; opening the center clears unread
  and the badge. No native actions remain on archived rows; both programmatic
  invocation and Enter on such a row are blocked.
- DND suppression of existing/new ordinary messages, critical bypass, history
  retention, and no stale-toast replay after disabling DND.
- Arrivals while reading remain read and do not display toasts.
- Transient exclusion and in-place replacements without duplicate history IDs.
- A live action button emits the native action, archives its notification and
  cannot subsequently be invoked from the archived item.
- Removing one item and Clear all remove corresponding history/native records.
- History cap was tested at 8 in the copied fixture: an 11-message burst keeps
  exactly the newest 8 and expires native records evicted by the cap. The actual
  source default remains 100.
- Keyboard row navigation/Delete, Tab/backtab/Escape, popup exclusivity and
  coordination with the real launcher component.
- A real source reload preserves history JSON, unread and DND in memory with no
  duplicate IDs or replayed suppressed toasts.
- Default, DND, 300×330 logical-pixel compact and empty center screenshots were
  reviewed. The list scrolls in constrained height.

Artifacts: `/tmp/notification-center.png`, `/tmp/notification-center-compact.png`,
`/tmp/notification-center-empty.png`, `/tmp/notification-center-test.log`,
`/tmp/notification-center-signals.log`, `/tmp/notification-center-lint.log`.
These contain synthetic test messages, not the user's notification history.

Main shell live reload and git diff --check passed. qmllint has no syntax errors;
Quickshell window metadata and dynamic delegate/currentItem warnings remain.
Existing backlight/input-language/UPower warnings are unrelated. The isolated
GUI process also logs existing EGL/Mesa and unavailable-portal messages.

## Current desktop activation

This is a new desktop process/session since the earlier approved trial. At this
iteration's preflight, Quickshell PID 1247 reported its backend off and mako owned
org.freedesktop.Notifications. That state was preserved during development.
The session opt-in and permanent defaults were not changed. A live handoff in
this new session remains separate from implementing/testing the center.

No Nix, Home Manager, packages, laptop configuration, commits or system switches
were changed/performed. Grouping, search, persistent history and image attachments
are outside this iteration. No benchmark-derived performance claim is made.

During final inspection the compositor had a new live instance (PID 3649) and the
old Quickshell connection had closed. No compositor restart was performed by the
agent. Quickshell was relaunched with --no-duplicate --daemonize on that existing
Wayland display (new shell PID 3967). Configuration Loaded was confirmed; the
final IPC status still reported backend off and GetServerInformation still
reported mako. The topbar was restored without switching notification daemons.
Final desktop artifact: `/tmp/notification-center-desktop.png`.

## Approved live activation — follow-up

The user explicitly approved switching this new session. Mako PID 3752 was the
verified owner (:1.43), managed by transient unit
`dbus-:1.2-org.freedesktop.Notifications@1.service`. Enabled the session opt-in in
Quickshell PID 3967 and stopped only that transient unit. GetServerInformation
then reported quickshell. No unit was disabled/masked and no system configuration
or permanent default was changed.

NotificationHost now also exposes local IPC controls:

```sh
qs ipc call notifications toggleCenter
qs ipc call notifications setDnd true
qs ipc call notifications setDnd false
qs ipc call notifications remove ID
qs ipc call notifications status
```

Status reports counts/DND/open state, not message contents; it does not itself
initialize a server. toggleCenter refuses to open when the backend is unavailable.
remove targets one history/native ID and was used only on generated test messages.
NotificationState's non-persistent center reference is cleared on destruction.

Real-desktop validation passed for 500 ms expiry leaving history/unread, DND
suppression of an ordinary message, critical bypass, opening the center clearing
unread/hiding toasts, and a real source reload preserving history/DND/unread with
no duplicates. The center reopened successfully after reload. Native Expired and
Dismissed signals were observed. The test then removed only its three message
IDs, restored prior DND/open state and left the backend enabled. Final test state:
0 history, 0 live, 0 unread, DND off, center closed. No user history was cleared.

Artifacts: `/tmp/notification-center-live.png`,
`/tmp/notification-center-live-before-reload.png`,
`/tmp/notification-center-live-signals.log`. The 3967-process opt-in survives QML
reloads; new processes remain off by default. Permanent migration remains outside
this session-only approval.

## Preview/reader regression

`tests/run-notification-reading.py` uses a fake service and temporary state on
j4n9-proxmox. It checks 8K preview storage, compact list geometry, real clicks,
Enter reader activation without application invocation, wider full text,
wheel/PageUp/PageDown and final-line access, Back/Escape, explicit actions,
archived full text, source reload, retention eviction and cleanup. TestEvent is
attached to the popup surface so synthetic keyboard input targets that window.
No real notification server, DND, actions or user history are changed.
Log: `/tmp/notification-reading-tests.log`.
