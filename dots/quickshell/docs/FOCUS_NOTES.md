# Focus session and quick notes

Both cards live in the lazy dashboard, use shared Theme/components and participate
in its Tab/Shift+Tab focus cycle. No tooltips, new topbar items, packages or binds.

## Focus session

Choose 25/50 minutes or 1–180 custom minutes, then Start. Pause, Resume and End
are available while active. A deadline derived from Date.now keeps running time
accurate after suspend; the one-second timer stops when idle/paused/completed.
The session continues while the dashboard is closed and survives QML live reload.
It resets when the shell process restarts. Completion is shown in the card,
without a sound or automatic notification.

Current mode is the default. Writing/Code/Relax are optional, explicit requests
through the existing ModeService. Ending a session does not switch workspaces.
DND is opt-in and disabled when the native notification backend is unavailable
(it does not control mako). A session only restores DND if it enabled DND itself
and no subsequent user change occurred. A revision counter catches even an
on/off/on sequence; the ownership flag survives live reload.

## Quick notes

A single plain-text scratchpad, stored at
`Quickshell.statePath("quick-notes/note.txt")`, normally
`$XDG_STATE_HOME/quickshell/by-shell/<shell-id>/quick-notes/note.txt`.
It persists across shell restarts. The enclosing directory is created with mode
0700 on first save. FileView uses atomic writes. No file is written for an
untouched empty scratchpad. Notes are local plain text, not encrypted.

Autosave follows 800 ms without edits. Save, Ctrl+S, leaving the editor and closing
the dashboard also request saving. Enter inserts a newline; Tab/Shift+Tab leave
the editor. Unsaved drafts survive QML reload. Save errors keep the draft and
show Retry; read errors prevent editing until Retry succeeds. A process crash
before a successful save can lose the unsaved draft. External file edits are
not watched while the shell is running.

## Validation on j4n9-proxmox

`tests/run-focus-notes.py` runs a copy of the production shell with fake mode/DND
and temporary XDG_STATE_HOME. It checks validation, pause/resume, wall-clock
completion, DND ownership/manual override, real QML reload, Unicode/multiline
notes, autosave, directory permissions, failed write/retry and process restart.
It also checks keyboard Start/Pause/End, editor newline/Ctrl+S, Tab and
a 340px dashboard layout. It opens/closes the real dashboard to instantiate both cards. No real mode,
DND or user note is changed. Logs: `/tmp/focus-notes-tests.log`.
