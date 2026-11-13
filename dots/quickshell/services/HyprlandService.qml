pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

QtObject {
    id: root
    property bool metadataQueued: false
    property var focusHistory: ({})
    function scheduleMetadata() {
        if (!metadataQueued) { metadataQueued=true; Qt.callLater(root.refreshMetadata) }
    }
    function refreshMetadata() { metadataQueued=false; Hyprland.refreshToplevels() }
    function rememberFocused() {
        const window=Hyprland.activeToplevel
        if (!window || !window.workspace) return
        const name=window.workspace.name
        if (focusHistory[name]!==window.address) {
            const next=Object.assign({},focusHistory)
            next[name]=window.address
            focusHistory=next
        }
    }
    Component.onCompleted: { scheduleMetadata(); Qt.callLater(root.rememberFocused) }
    property Connections compositorEvents: Connections {
        target: Hyprland
        function onActiveToplevelChanged() { Qt.callLater(root.rememberFocused) }
        function onRawEvent(event) {
            if (["openwindow","movewindowv2","changefloatingmode","configreloaded"].indexOf(event.name)>=0)
                root.scheduleMetadata()
        }
    }


    property IpcHandler ipcHandler: IpcHandler {
        target: "hyprlandService"

        function refreshOrder(): void {
            Hyprland.refreshToplevels()
        }
    }

    readonly property var workspaces:
        Hyprland.workspaces

    readonly property var focusedWorkspace:
        Hyprland.focusedWorkspace

    readonly property var focusedMonitor:
        Hyprland.focusedMonitor

    readonly property var activeToplevel:
        Hyprland.activeToplevel

    /*
     * Workspace dùng để chứa các cửa sổ minimized.
     */
    readonly property var minimizedWorkspace: {
        const list =
            Hyprland.workspaces.values

        for (let i = 0; i < list.length; ++i) {
            const workspace =
                list[i]

            if (
                workspace
                && workspace.name === "special:minimized"
            ) {
                return workspace
            }
        }

        return null
    }

    /*
     * Model RunningApps:
     *
     *   current workspace
     *       +
     *   special:minimized
     *
     * Không lấy window từ các workspace bình thường khác.
     */

     function windowX(toplevel) {
        if (
            !toplevel
            || !toplevel.lastIpcObject
            || !toplevel.lastIpcObject.at
        ) {
            return 0
        }

        return toplevel.lastIpcObject.at[0]
    }

    function windowY(toplevel) {
        if (
            !toplevel
            || !toplevel.lastIpcObject
            || !toplevel.lastIpcObject.at
        ) {
            return 0
        }

        return toplevel.lastIpcObject.at[1]
    }

    function minimizedOnMonitor(window, monitor) {
        if (!window) return false
        if (!monitor) return true
        const ipc = window.lastIpcObject || {}
        const marker = (ipc.tags || []).find(tag => tag.startsWith("minimized-from-"))
        if (marker) {
            const name = marker.slice("minimized-from-".length).replace(/^name:/, "")
            const origin = workspaces.values.find(workspace => workspace.name === name)
            if (origin && origin.monitor) return origin.monitor === monitor
        }
        return ipc.monitor === monitor.id
    }
    function toplevelsFor(workspace, monitor) {
        const normal = workspace && workspace.toplevels ? workspace.toplevels.values.filter(window => window !== null) : []
        normal.sort((a,b) => windowX(a)-windowX(b) || windowY(a)-windowY(b))
        const minimized = minimizedWorkspace && minimizedWorkspace !== workspace
            ? minimizedWorkspace.toplevels.values.filter(window => minimizedOnMonitor(window, monitor)) : []
        return normal.concat(minimized)
    }
    function activeToplevelFor(workspace) {
        if (!workspace || !workspace.toplevels) return null
        const windows = workspace.toplevels.values
        const last = focusHistory[workspace.name] || (workspace.lastIpcObject ? workspace.lastIpcObject.lastwindow : "")
        return windows.find(window => window && window.activated)
            || windows.find(window => window && last && (window.address || "").replace(/^0x/, "") === last.replace(/^0x/, "")) || null
    }
    readonly property ScriptModel visibleToplevels: ScriptModel {
        values: root.toplevelsFor(root.focusedWorkspace, null)
    }

    function isMinimized(toplevel) {
        if (
            !toplevel
            || !toplevel.workspace
        ) {
            return false
        }

        return (
            toplevel.workspace.name
            === "special:minimized"
        )
    }

    function activateWorkspace(workspace) {
        if (!workspace)
            return

        workspace.activate()
    }

    // Lua and QML share an origin marker stored on the compositor window.
    // It survives configuration reload and does not erase mode return tags.
    function activateToplevel(toplevel) {
        if (!toplevel)
            return

        if (isMinimized(toplevel)) {
            const current = root.focusedWorkspace
            if (!current || !toplevel.address)
                return
            const tags = toplevel.lastIpcObject ? (toplevel.lastIpcObject.tags || []) : []
            const marker = tags.find(tag => tag.startsWith("minimized-from-"))
            const name = current.name
            const target = marker ? marker.slice("minimized-from-".length)
                : (/^\d+$/.test(name) || name.startsWith("special:") ? name : "name:" + name)
            const address = toplevel.address.startsWith("0x") ? toplevel.address : "0x" + toplevel.address
            const selector = "address:" + address
            const window = "hl.get_window(" + JSON.stringify(selector) + ")"
            Hyprland.dispatch("hl.dsp.window.move({window=" + window
                + ",workspace=" + JSON.stringify(target) + ",follow=true})")
            Hyprland.dispatch("hl.dsp.window.tag({window=" + window + ',tag="-minimized"})')
            if (marker)
                Hyprland.dispatch("hl.dsp.window.tag({window=" + window
                    + ",tag=" + JSON.stringify("-" + marker) + "})")
            Hyprland.dispatch("hl.dsp.focus({window=" + window + "})")
            return
        }

        const handle = toplevel.wayland ?? toplevel.handle
        if (handle)
            handle.activate()
    }

    function closeToplevel(toplevel) {
        if (!toplevel)
            return

        const handle =
            toplevel.wayland
            ?? toplevel.handle

        if (handle)
            handle.close()
    }

    function dispatch(command) {
        Hyprland.dispatch(command)
    }
}
