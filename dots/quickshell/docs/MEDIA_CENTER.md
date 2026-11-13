# Dashboard Media Center

Implemented on j4n9-proxmox, 2026-11-12. The existing Quickshell 0.3.1 package
already includes Quickshell.Services.Mpris; no packages or system services were
added.

## Behavior

The dashboard's right column shows **Now playing** above the calendar whenever
at least one MPRIS player exists. It hides completely when none exist. Titles,
artists and player names are plain text, elided to a fixed number of lines.
Metadata length and artwork loading do not resize the card.

Previous, Play/Pause and Next use the selected player's native MPRIS methods.
Buttons and service actions both check canControl and the corresponding canX
property. The service observes confirmed playback state rather than changing the
UI optimistically. Unsupported controls remain disabled. There are no tooltips.
The supported properties and methods follow
[Quickshell MprisPlayer](https://quickshell.org/docs/v0.3.0/types/Quickshell.Services.Mpris/MprisPlayer/).

With no manual choice, the service prefers the first playing player, then the
first available player. With multiple players, the chooser lets the user select
one by stable D-Bus name. That choice remains while the player exists, including
when other players begin playback. Removing it returns to automatic selection.
A QML reload establishes a fresh selection; no player preference is written to
disk. A manual selection does not start playback by itself.

Artwork uses an asynchronous Image with a 64px source size (Theme.mediaArtworkSize).
Missing or failed artwork uses the shared Nerd Font music glyph. Images load only
for a visible card, use normal Qt image caching, and their Image items follow the dashboard Loader lifecycle.
Artwork URLs supplied by a player may require network access; tests use a local
SVG only. There is no position/progress timer or continuous animation.

## Architecture and focus

- MediaService is the single owner of player selection and guarded actions. Its
  default backend is native Mpris; the injectable backend supports safe fixtures.
- MediaCard uses DashboardCard, IconButton, StyledText and existing Theme tokens.
  The player list is lazy-loaded; the entire card follows the dashboard Loader.
- DashboardContent includes its available controls in Tab/Backtab order. Focus
  requests participate in the visible dashboard card/page focus order. The dashboard
  no longer scrolls; its compact player chooser is paginated.
- Enter/Space activate controls. Escape closes a player chooser first, then the
  dashboard through the existing overlay handler. Selecting a player returns
  focus after the chooser delegate has been destroyed.
- Capability loss/player disappearance recovers focus without stealing it from
  another focused dashboard control. Removing all players hides the card and
  returns focus to an available dashboard control.

The card inherits dashboard screen routing and reload behavior. It adds no bar
widget, shortcut, playerctl command, external process, polling or system service.
Existing audio volume/mute controls and media-key bindings are unchanged.

## Tests

Run GUI fixtures sequentially on j4n9-proxmox:

```sh
python3 dots/quickshell/tests/run-media-controls.py
python3 dots/quickshell/tests/run-audio-controls.py
```

The media runner copies the shell, reads native player availability without
issuing commands, then injects Qt mock players into the service. Passed:

- Playing-first fallback, playback-state reactivity, manual selection and its
  stable bus identity, removal/recovery, rejection of stale player objects.
- Previous/Next/Play/Pause dispatch to the selected player only; canControl and
  partial capability guards; no calls while unavailable.
- Missing metadata fallback, 340/420px card layouts, constant height for long
  metadata, local SVG artwork and missing-image fallback.
- Enter/Tab/Backtab/Escape, player chooser, five view creation/destruction cycles.
- Full dashboard focus order, actual source-content live reload verified by a
  persistent generation counter, player-disappearance focus recovery and lazy
  destruction. No QML exceptions in the final run. The intentional missing-image
  case emits the expected Cannot open warning.
- Existing audio controls/service/dashboard regression passes unchanged.

Images inspected: /tmp/media-card-fixture.png and /tmp/media-dashboard-fixture.png.
The native backend on this VM reported zero MPRIS players; real playback commands
were therefore not exercised. Native dashboard load/unload is also checked, with
no empty media card when no player exists. Tests do not start, pause or skip real
media, and do not alter audio volume/mute/default devices.

qmllint has only dynamic Loader.item/unqualified access metadata warnings for the
changed views, no syntax errors; git diff --check passes. Missing backlight/fcitx
warnings on the VM are pre-existing. No laptop, Flake, Home Manager, NixOS modules
or packages were modified.
