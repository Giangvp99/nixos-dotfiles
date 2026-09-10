pragma Singleton

import QtQuick
import Quickshell
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
    readonly property ScriptModel visibleToplevels: ScriptModel {
        values: {
            const result = []

            const current =
                root.focusedWorkspace

            const minimized =
                root.minimizedWorkspace

            /*
             * Window của workspace hiện tại.
             */
            if (
                current
                && current.toplevels
            ) {
                const windows =
                    current.toplevels.values

                for (
                    let i = 0;
                    i < windows.length;
                    ++i
                ) {
                    const window =
                        windows[i]

                    if (window)
                        result.push(window)
                }
            }

            /*
             * Window đã minimize.
             *
             * Không thêm lần nữa nếu vì lý do nào đó
             * focusedWorkspace chính là special:minimized.
             */
            if (
                minimized
                && minimized !== current
                && minimized.toplevels
            ) {
                const windows =
                    minimized.toplevels.values

                for (
                    let i = 0;
                    i < windows.length;
                    ++i
                ) {
                    const window =
                        windows[i]

                    if (window)
                        result.push(window)
                }
            }

            return result
        }
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

    /*
     * Click icon trên RunningApps.
     *
     * Nếu window đang minimized:
     *   special:minimized
     *       ↓
     *   current workspace
     *       ↓
     *   activate
     *
     * Nếu window bình thường:
     *   activate trực tiếp.
     */
    function activateToplevel(toplevel) {
        if (!toplevel)
            return

        const handle =
            toplevel.wayland
            ?? toplevel.handle

        if (isMinimized(toplevel)) {
            const current =
                root.focusedWorkspace

            if (
                current
                && toplevel.address
            ) {
                Hyprland.dispatch(
                    "movetoworkspace "
                    + current.name
                    + ",address:"
                    + toplevel.address
                )

                /*
                 * Dispatch thay đổi workspace trước,
                 * sau đó focus ở event-loop kế tiếp.
                 */
                Qt.callLater(function() {
                    if (handle)
                        handle.activate()
                })

                return
            }
        }

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
