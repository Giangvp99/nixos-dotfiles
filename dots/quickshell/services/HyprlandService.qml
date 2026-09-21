pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

QtObject {
    id: root

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

    readonly property ScriptModel visibleToplevels: ScriptModel {
        values: {
            const normalWindows = []
            const minimizedWindows = []

            const current =
                root.focusedWorkspace

            const minimized =
                root.minimizedWorkspace


            // ================================================================
            // Current workspace
            // ================================================================

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
                        normalWindows.push(window)
                }
            }


            // ================================================================
            // Sort theo layout thực tế
            // ================================================================
            //
            // Scrolling layout:
            //
            //      A       B       C
            //      x=0     x=1280  x=2560
            //
            // Nếu swap B ↔ C thì tọa độ thay đổi.
            // Widget vì thế cũng đổi thứ tự.
            //
            // Nếu nhiều window cùng một column,
            // sort tiếp theo Y.
            // ================================================================

            normalWindows.sort(function(a, b) {
                const ax =
                    root.windowX(a)

                const bx =
                    root.windowX(b)

                if (ax !== bx)
                    return ax - bx

                return (
                    root.windowY(a)
                    - root.windowY(b)
                )
            })


            // ================================================================
            // Minimized windows
            // ================================================================

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
                        minimizedWindows.push(window)
                }
            }


            // Minimized luôn nằm sau các window của Mode hiện tại.
            return normalWindows.concat(
                minimizedWindows
            )
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
