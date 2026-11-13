# Audio OSD

Control Center lượt 3, implemented on j4n9-proxmox, 2026-11-12.

`AudioFeedback.qml` observes AudioService's rounded output/input volume and mute
signals. It batches changes with Qt.callLater, compares a snapshot per default
node, and presents the latest confirmed state. Simultaneous output/input changes
prefer output; later input changes replace the same panel rather than queueing.

Startup, config reload, default-node changes, unavailable nodes and backend
reconnection establish a new baseline silently. Losing the displayed node hides
feedback immediately. Identical rounded values do not extend the timeout.
Disabling OSD hides it immediately and keeps tracking a silent baseline. It does
not replay the old state on re-enable. No audio values are written by OSD.

`AudioOsd.qml` draws one small PanelWindow at the bottom center of the focused
Hyprland monitor, with the first Quickshell screen as fallback. Screen selection
is captured when feedback is presented. It uses the overlay layer, no exclusive
zone, keyboard focus None, and an empty input region. There are no interactive
controls or tooltips. Removing its target screen hides it. Multiple physical
monitor routing has not been exercised on this single-screen VM.

The view reuses Theme, Surface, StyledText and OverlayMotion. Entrance animation
respects reducedMotion; close is immediate. The name is plain text and elided;
volume above 100% keeps the actual percentage but caps the visual meter at full.
One single-shot timer runs only while visible; there is no idle polling, process,
notification, persistence, or popup ownership. Launcher/dashboard focus is not
claimed or dismissed by the OSD.

Config.qml:

| Setting | Default |
| --- | --- |
| audioOsdEnabled | true |
| audioOsdTimeout | 1500 ms |
| audioOsdWidth | 300 px |
| audioOsdBottomMargin | 64 px |

Existing media keys continue using wpctl; changes from those commands, the
bar/dashboard, and other audio applications are observed through PipeWire.
Unchanged volume at a limit does not emit another indicator. Brightness is not
included because its current backend is read-only and hardware-specific.

AudioService also checks node readiness and guards audio getters/actions while
the audio object is transiently null during replacement or disconnection.

## Validation

Run these GUI fixtures sequentially on the VM:

```sh
python3 dots/quickshell/tests/run-audio-osd.py
python3 dots/quickshell/tests/run-audio-controls.py
```

The OSD fixture injects mock nodes into a disposable copy of the shell, without
changing real PipeWire volume, mute or preferred devices. It checks startup,
output/input, mute, duplicate suppression, timeout/restart, keyboard focus,
empty input mask, default replacement, node/backend readiness and recovery,
disable/re-enable, reduced motion, 125%, actual source-content live reload, and
five show/hide cycles. It asserts no QML errors in the final run and saves a
preview to /tmp/audio-osd-fixture.png. The empty input-region configuration is
checked; physical pointer passthrough is not separately synthesized.

The existing audio controls fixture covers service/device controls, hotplug,
keyboard navigation, full dashboard integration and lazy destruction. Production
shell auto reload was confirmed in its log with no new runtime errors (existing
missing backlight/fcitx warnings remain). No packages, system configuration,
laptop files or Hyprland bindings were changed. VM microphone behavior remains
mock-tested because the VM has no microphone.

Multi-screen update: screen capture/removal is shared through OverlayScreen and
ScreenService. Native headless scale 1/2 tests confirm focus routing and dismissal
on output loss; physical external-display hotplug remains untested. Swapping an
injected audio service now also schedules a silent baseline sample. See
[MULTISCREEN](../../docs/MULTISCREEN.md).
