# Application launcher

Open or close with `Super+Space`. The launcher uses the shared dark palette,
fonts, surfaces, focus border and icon fallback. No tooltips or polling are used.

## Behavior

- Empty query: configured pinned apps first, followed by applications sorted by
  display name and desktop ID. Missing pins are ignored and duplicate pin IDs
  do not duplicate results. Pinned rows have a pin icon.
- Search: exact name, name prefix, word prefix, name substring, generic name,
  keywords, then desktop ID. Case and repeated whitespace are normalized.
  Pins do not override relevance when a query is present. Equal scores are sorted
  by normalized display name, then ID; the limit is applied after sorting.
- Up/Down and Tab/Shift+Tab cycle selection. Selection scrolls into view.
  Query changes reset selection and scroll. Enter opens the selected app;
  Escape or clicking the scrim closes. Clicking panel padding keeps it open.
  Enter with no results does nothing.
- Opening emits `opening`; `shell.qml` closes the active topbar popup before
  the launcher takes focus. Every open clears the query and focuses search.
- Width, height and top offset are bounded by the host window. Results shrink
  and scroll within the available space; the search field stays visible.

## Configuration

Edit `config/Config.qml` live; no Nix rebuild is required:

```qml
readonly property var launcherPinnedApps: ["kitty", "org.kde.dolphin", "brave-browser"]
```

Use desktop-entry IDs, with or without the `.desktop` suffix. Other preferences:
`launcherWidth` (560), `launcherMaxHeight` (520), `launcherSearchHeight` (44),
`launcherRowHeight` (52), `launcherVisibleRows` (7), `launcherResultLimit` (64).
The result limit bounds the list; it is not a count of all matching installed
applications. There is no recency tracking or persistent usage database.

## Architecture

- `services/AppService.qml`: catalog, cached normalized index, search and launch.
- `utils/AppSearch.js`: pure indexing/ranking helpers; no system access/state.
- `Launcher.qml`: query, selection, focus, bounds and overlay lifecycle.
- `LauncherItem.qml`: shared IconButton interaction and AppIcon rendering.
- `components/AppIcon.qml`: optional desktop entry supplied directly by launcher;
  existing app-ID lookup remains available to the topbar.
- `shell.qml`: coordination with bar popup state.

The launcher exposes `opened`, `query`, `selectedIndex`, `results`, `opening`,
`open/close/toggle` and a read-only `panel` reference for geometry/custom previews.
`shortcutAppId` defaults to `quickshell`; isolated previews can use another name
without registering a duplicate production shortcut.

## Validation — j4n9-proxmox, 2026-11-10

A temporary harness loads the actual module, uses the installed QtTest TestEvent
and a separate shortcut namespace. Confirmed:

- Ranking fixtures cover each match tier, exact matches beyond the former first
  eight entries, pins/missing pins/duplicate pins, normalization, stable ties,
  limit-after-ranking, and missing desktop-icon fallback.
- The live catalog resolves the default pins to Kitty, Dolphin and Brave.
- Closing Calendar on open, initial search focus, wrap navigation, Tab/backtab,
  scrolling into view, resetting selection after query changes and empty results.
- Real Kitty launches through Enter and result click. Only the two newly created
  test windows were closed; existing client windows were retained.
- Clicking padding, outside dismissal, Escape and reopen. Actual module preview
  at 360×320 logical px stays within bounds and supports list scrolling.
- Automatic reload of the main Quickshell instance and git diff --check pass.
- qmllint has no syntax errors; metadata warnings remain for Quickshell's
  PanelWindow/GlobalShortcut and unqualified delegate references.

Reviewed temporary screenshots: `/tmp/launcher-phase2.png`,
`/tmp/launcher-compact.png`, `/tmp/launcher-empty.png`. The harness logs existing
EGL/Mesa initialization messages; the main shell retains existing unavailable
backlight/input-language warnings. No performance improvement is claimed without
measurement. Very small windows below the fixed input/footer minimum and multiple
physical monitors are not validated. No packages, Nix or laptop configuration
were changed.
