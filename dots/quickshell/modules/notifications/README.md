# Notifications

Backend and toast UI for Quickshell 0.3.1, validated on j4n9-proxmox.
Notification center, unread counts, in-memory history and DND are implemented;
see [CENTER.md](CENTER.md) for behavior, architecture and stage 3 validation.

## Current activation state

An earlier session-only trial was approved on j4n9-proxmox. In that historical
trial, Quickshell PID 4183 owned org.freedesktop.Notifications on connection :1.8. The previous mako PID 4363
was managed by the transient unit
`dbus-:1.2-org.freedesktop.Notifications@0.service`; that unit was stopped without
being disabled, masked or changing any unit file. No Nix, Home Manager, package
or laptop configuration was changed.

The desktop subsequently restarted. Stage 3 iteration 2 was first validated
while the new process was off and mako owned notifications. The user then approved
a live handoff: Quickshell PID 3967 is now enabled for this session and the
identified transient mako unit was stopped. See CENTER.md for current validation.
`Config.notificationsEnabled` remains **false**. The always-loaded
`NotificationHost.qml` provides an explicit session opt-in:

```sh
qs ipc call notifications start
qs ipc call notifications started
qs ipc call notifications status
qs ipc call notifications toggleCenter
qs ipc call notifications setDnd true
qs ipc call notifications setDnd false
```

The host gates NotificationToasts with LazyLoader. The runtime marker
`/tmp/quickshell-notifications-<PID>` contains the process start token from
`/proc/self/stat`. PID and start time must both match, so QML reloads retain the
opt-in while a new process stays off (including PID reuse). FileView preloads
and explicitly tracks loaded state before computing this token; no polling is
used. These are runtime markers, not generated Nix Store configuration.

The start command initializes a notification server; do not use it for an
unapproved daemon handoff. `started` reports the host opt-in, not independently
verified D-Bus ownership. Use GetServerInformation when checking the actual owner.

**Reverting the trial:** the native notification server is a process singleton.
Unloading the QML or deleting the marker does not release its bus name. Keep the
config flag false, restart Quickshell when a brief shell interruption is acceptable,
and restore/allow the existing D-Bus-activated mako. Do not attempt to run both as
owners. The session trial deliberately makes no permanent daemon migration;
after restarting/logging out, mako can be activated again by the unchanged system
configuration. A permanent migration is a separate change.

## Architecture

- `services/NotificationService.qml`: the only native NotificationServer owner;
  creates/removes records, exposes visible records, dismisses and invokes actions.
- `services/NotificationState.qml`: history snapshots/read/DND, without native API.
- `NotificationCenter.qml` and `NotificationHistoryItem.qml`: bar popup and history UI.
- `services/NotificationRecord.qml`: notification lifetime and one-shot timer.
  No polling, shell commands or persistent history database.
- `NotificationHost.qml`: session opt-in, IPC status and gated loading.
- `NotificationToasts.qml`: non-focusable top-right panel below the bar, bounded
  to screen dimensions. ScriptModel keeps delegate identity during queue updates.
- `ToastCard.qml`: shared Surface/IconButton/StyledText styling; app icon or bell
  fallback, summary, plain body, close button and action buttons. Long bodies and
  long action rows scroll. The entire stack scrolls if the viewport is short.
- `components/StatusText.qml`: adds a configurable textFormat, retaining AutoText
  by default; notification action labels explicitly select PlainText.

There are no tooltips, sounds, inline replies, image attachments, rich markup or
hyperlink handling. Unsupported capabilities are not advertised. Default action
identifiers are presented as explicit buttons rather than making the whole card
clickable. User/application action text is displayed without markup execution;
invocation uses the native action API, not a shell command.

## Lifetime and bounds

- FIFO queue, 3 presented cards and at most 32 tracked records by default.
  Additional incoming notifications receive an Expired close reason. Replacing
  an already tracked notification updates that record without adding another.
- Default timeout: 5000 ms. Zero timeout persists until closed. Critical urgency
  with a server-selected timeout does not expire; explicit positive app timeouts
  are honored. Critical cards use the urgent border color.
- A queued record's timer starts when it is first presented. Hover stops the
  timer; leaving hover restarts the full timeout, allowing time to read/actions.
- Changed notification properties restart the timeout. Quickshell 0.3.1 only
  emits the server notification signal for new records; replacement properties
  update in place. A byte-identical replacement does not emit those change
  signals, so it cannot restart our timer through this API.
- keepOnReload retains native notification IDs. QML record timers restart with
  their full configured lifetime on reload; remaining milliseconds are not
  persisted. A process restart does not preserve notifications.
- App-requested close, user dismissal and expiry remove the record and native
  notification. Non-resident actions close via the native API; resident actions
  keep their notification until explicitly dismissed/expired.

Configuration lives in Config.qml: notificationsEnabled, notificationWidth,
notificationMaxVisible, notificationQueueLimit, notificationDefaultTimeout and
notificationBodyMaxHeight. Theme.notificationIconSize controls the app icon.

**Version-specific timeout detail:** the installed API exposes expireTimeout in
milliseconds, despite the 0.3.1 reference text saying seconds. Both the tagged
source implementation and real D-Bus calls with a 450 ms timeout were checked.
Recheck this behavior when upgrading Quickshell.

## Validation — 2026-11-10

The final harness uses a snapshot of the QML tree under
`/tmp/notification-test-tree` with normal relative imports, and a private D-Bus
with no activatable services. The desktop's bus and mako stay separate.

Confirmed with real D-Bus Notify/CloseNotification and QtTest mouse injection:

- Server identity/capabilities; milliseconds, zero/default/critical timeouts.
- Replacement retains the same ID, updates content and resets a changed payload's
  timeout. Pause/resume and FIFO promotion work.
- Action button click emits ActionInvoked. Resident and non-resident behavior,
  close button and client-requested close work. Monitor output contains native
  close reasons Expired=1, Dismissed=2, CloseRequested=3.
- 34-message burst leaves 32 records and 3 presented cards; overflow is bounded.
- Real QML source change triggers reload: one persistent record keeps its ID,
  lastGeneration is true, no duplicate appears.
- Vietnamese/plain text, missing-icon fallback and long content render; normal
  and 280×240 logical-pixel preview screenshots were inspected. The toast panel
  remains non-focusable. Compact views use stack scrolling.
- Main desktop QML reloads with the module disabled. git diff --check passes.
- qmllint finds no syntax errors; Quickshell PanelWindow/Margins metadata and
  dynamic delegate access warnings remain. Existing backlight/language-file
  warnings remain in the main shell. Isolated tests log EGL/Mesa initialization
  messages and the intentionally unavailable portal on their private bus.

Artifacts: `/tmp/notifications-toast.png`, `/tmp/notifications-compact.png`,
`/tmp/notification-test.log`, `/tmp/notification-signals.log`,
`/tmp/notification-lint-final.log`. They are temporary session artifacts.

Limitations: no permanent daemon migration, physical multi-monitor test, disk
history persistence or remaining-time preservation. Center/DND are now covered
by CENTER.md. No performance improvement is
claimed without measurements. Runtime enable/disable must respect the native
process-singleton ownership described above.

## Live desktop trial — 2026-11-10

After explicit user approval, enabled the current process via IPC and stopped
only the identified transient mako unit. D-Bus GetServerInformation reports
quickshell; ownership moved from :1.29/mako to the existing :1.8/Quickshell PID
4183, without restarting the compositor or shell.

Validated on the real desktop: 800 ms expiry, replacement with the same ID,
plain Vietnamese body and action labels, QML source reload retaining the session
opt-in and notification ID, and client-requested close. The live bus monitor
observed Expired=1 and CloseRequested=3. Only notifications generated by the test
were closed; no application action was invoked on the desktop. Action invocation
and Dismissed=2 were covered by the earlier isolated test.

A separate short-lived NotificationHost process was confirmed off by default
while the main process stayed enabled. After cleanup reload, the main process
still owned :1.8 and the transient mako unit was inactive. Session-token loading
was fixed during live validation; the final implementation has passed the reload
check. Main logs retain the pre-existing unavailable backlight/input-language
warnings. The earlier ownership warning was emitted while mako still owned the
name, before the approved handoff.

Artifacts: `/tmp/notification-live-before-reload.png`,
`/tmp/notification-live-after-reload.png`, `/tmp/notification-live-signals.log`.

## Primary API references

- [NotificationServer](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Notifications/NotificationServer/)
- [Notification](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Notifications/Notification/)
- [NotificationAction](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Notifications/NotificationAction/)
- [Tagged 0.3.1 server implementation](https://github.com/quickshell-mirror/quickshell/blob/v0.3.1/src/services/notifications/server.cpp)
- [Tagged 0.3.1 notification implementation](https://github.com/quickshell-mirror/quickshell/blob/v0.3.1/src/services/notifications/notification.cpp)
- [Desktop notification D-Bus specification](https://specifications.freedesktop.org/notification/latest/protocol.html)
