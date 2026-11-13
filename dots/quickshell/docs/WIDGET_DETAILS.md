# Topbar spacing and interactive details

## Shared geometry

All StatusText/IconButton controls use Theme.controlPadding=8 and
Theme.controlSpacing=4. Fixed status cells use the same horizontal padding.
Dense two-line CPU/RAM and transfer rows retain spaceTiny=2 between their small
row icons and values. Height remains 28, with shared typography, radius, semantic
colors, hover/pressed/focus and selected border. No tooltips.

Fixed widths (logical units): network including link icon 96, CPU/RAM 60, audio 72.
The icon/value rows do not resize when counters or mute text change. Existing
battery/temperature availability guards and right-aligned scrolling metrics group
remain. The separate Wi-Fi widget is a fallback when network speed is disabled.

## Network

NetworkSpeed places a LAN/Wi-Fi icon to the left of the existing download/upload
stack. NetworkService classifies the exact interface that SystemMonitor measures,
not an unrelated active adapter. Unknown/VPN interfaces use a generic network
icon rather than being labeled Wi-Fi or LAN.

Selection priority: explicit networkRateInterface, lowest-metric default IPv4
route, then the connected NetworkManager device. The existing sampler refreshes
the route; no new timer/process is added to select it. IPv6-only systems can use
the NetworkManager fallback or an explicit interface. Counter resets and
interface switches still require a fresh baseline.

Click opens NetworkPopup, anchored through the existing BarPopup/PopupState
system. It shows interface/type/profile/IPv4/gateway/DNS, refresh and the existing
NetworkCard controls (Wi-Fi, saved/open network selection, Settings when
nm-connection-editor exists). No packages are installed. Detail fields are plain
text; the read-only `nmcli` command runs only on open/refresh/interface change,
with a five-second timeout. No background detail polling. Settings launches the
existing application only on explicit user action. Popup height follows content.

## CPU/RAM

Click ResourceUsage to open two Canvas charts over a 0–100% scale. The singleton
SystemMonitor retains 90 samples per series (about three minutes at the default
2s interval), including repeated equal values. CPU and RAM use their own sample
timestamps. Missing/invalid values and long gaps break the line; clock rollback
resets future samples. Painting occurs only in the visible lazy popup.

CPU and memory series survive QML live reload through in-memory
PersistentProperties. They reset on process restart; no history file is written.
The existing sampler/FileViews supply the data; no extra telemetry poller.

## Audio

Click opens AudioPopup, reusing AudioCard output/microphone volume, mute and
device selection. Double-click mutes/unmutes without also opening the popup.
Wheel volume adjustment is unchanged. Audio alone enables deferred single-click:
it waits Qt.styleHints.mouseDoubleClickInterval and cancels the pending click on
a double-click, hide or disable. Enter/Space open details immediately. Other
buttons retain ordinary MouseArea behavior. Popup height follows content.

All three popups share DetailsPopup header, padding, lazy Loader, close/Escape,
Tab/Shift+Tab, screen validation, focus grab and overlay exclusivity. Device,
network and player controls continue using the existing guarded services.

## VM validation

- `tests/run-widget-details.py`: fake providers, real mouse single/double clicks,
  ordinary-button baseline, audio keyboard/wheel, fixed widths/padding, lazy and
  exclusive popups, chart gaps, bounded/restored history validation, detail parser,
  process failure and timeout. No real mute/network actions.
- `tests/run-widget-live.py`: production shell copy, temporary state, native
  read-only network/audio/resource popups, geometry and real source reload;
  history timestamps survive and volume/mute/Wi-Fi are unchanged.
- `tests/run-system-widgets.py`: parser/sensor/battery availability, fixed widths,
  480/640/800/1600 bar layouts, audio wheel and popup reanchoring.
- Existing dashboard, audio and network fixtures verify shared-control regression.

Run GUI fixtures sequentially on j4n9-proxmox. Logs are under
`/tmp/widget-details-tests.log`, `/tmp/widget-live-tests.log` and the existing
per-fixture log paths. No laptop, NixOS, Flake, Home Manager or package changes.
