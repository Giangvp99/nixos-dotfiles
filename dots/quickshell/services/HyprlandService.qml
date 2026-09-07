pragma Singleton

import QtQuick
import Quickshell.Hyprland

QtObject {
    id: root

    readonly property var workspaces:
        Hyprland.workspaces

    readonly property var focusedWorkspace:
        Hyprland.focusedWorkspace

    readonly property var focusedMonitor:
        Hyprland.focusedMonitor

    readonly property var activeToplevel:
        Hyprland.activeToplevel

    function activateWorkspace(workspace) {
        if (workspace)
            workspace.activate()
    }

    function dispatch(command) {
        Hyprland.dispatch(command)
    }
}
