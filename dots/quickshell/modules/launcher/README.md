# Launcher

Native application launcher for the shell.

## Responsibilities

- Display applications from `AppService`.
- Search applications.
- Manage keyboard selection.
- Launch the selected application.
- Own launcher visibility while it is the only shell overlay.

## Architecture

Application data and launching belong to `AppService`.

The launcher owns only UI state:

- visibility
- query
- selected index

## Shortcut

Hyprland global shortcut:

`SUPER + SPACE`
