# Mode Manager regression tests

Run from `/etc/nixos` with an existing Lua 5.4+ interpreter:

```sh
lua dots/hypr/tests/modes.lua
luac -p dots/hypr/modes/core.lua
```

No packages, compositor, outputs, or application windows are created by this test.
It loads the production Lua modules against a mocked `hl` API.

Coverage:

- One → two → one monitor transitions for Writing, Code, and Relax.
- Secondary origin markers, primary windows, and physical monitor focus.
- Minimized windows identified by tag or special workspace remain untouched.
- Restored windows retain their secondary marker until a subsequent mode refresh.
- Unchanged tags (table/string metadata) cannot cause unbounded dispatch.
- Empty topology, unknown mode, preferred monitor, and spatial fallback.
- Module reload does not switch modes; the startup callback remains registered.

The unit test does not emulate native dispatch failures, physical hotplug, or QML
activation. Reflow remains explicit via `SUPER + CTRL + R` or mode selection;
this change does not add hotplug handlers or automatically move restored windows.

## Validation on j4n9-proxmox, 2026-11-11

- Lua 5.5 from the existing Nix Store: all 8 scenarios passed.
- `luac -p`: production core and test syntax passed.
- Live `hyprctl reload`: returned `ok`; `configerrors` was empty.
- Active workspace remained `mode-relax-primary` on `Virtual-1` after reload.
- Initial multiple-monitor transitions were mocked; the native follow-up below
  now covers virtual output connection/disconnection and minimize/restore.

## Native integration follow-up

```sh
python3 dots/hypr/tests/run-modes-integration.py
```

Run only on `j4n9-proxmox` with an existing Lua Hyprland session and `kitty`.
The script requires one active monitor, no open special workspace, and no existing
minimized, secondary-lane, or secondary-return-tagged windows. It changes focus
temporarily, opens a disposable kitty, and creates/removes headless outputs.
Do not interact with the desktop while it runs. It does not install packages or
edit monitor configuration. IPC/display access must be allowed by the runner.

The minimize callback is loaded directly from production `binds.lua` in an
isolated environment that discards bind registration; its queries and dispatches
use the native compositor. This tests callback behavior, not physical key delivery
or Quickshell's separate restore action.

Validated on 2026-11-11:

- Writing, Code, Relax: secondary collapse on one monitor records the return tag.
- Native minimize preserves the return marker on `special:minimized`.
- Adding a headless monitor and switching mode leaves the window minimized.
- Live reload preserves active workspace, minimized state, and return marker;
  `configerrors` stays empty.
- The production restore callback returns to the recorded origin and removes the
  minimize tags; explicit mode refresh restores the secondary lane.
- Switching mode preserves focus on the secondary physical output.
- Removing the headless output and switching mode collapses the lane again.
- Cleanup removed test windows/outputs and verified original window workspaces,
  tags, and active workspace; focus and pointer position were restored.

Physical cable hotplug, physical keyboard delivery, and Quickshell activation
remain separate checks. No laptop or Nix configuration was changed.

## Temporary dialogs

`python3 dots/hypr/tests/run-dialogs.py` exercises the native dialog policy with
throwaway Qt windows and an actual Qt file picker (open/cancel only, no writes).
It temporarily changes focus and restores it after cleanup. Run GUI fixtures
sequentially on j4n9-proxmox. See [dialog policy](../modules/DIALOGS.md).
