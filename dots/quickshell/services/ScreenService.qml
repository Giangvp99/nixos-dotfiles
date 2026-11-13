pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

QtObject {
    readonly property var screens: Quickshell.screens
    readonly property var focusedMonitor: Hyprland.focusedMonitor
    readonly property var focusedScreen: {
        const monitor = focusedMonitor
        return screens.find(screen => monitor && screen.name === monitor.name) || screens[0] || null
    }
    function contains(screen) { return !!screen && screens.some(item => item === screen) }
    function choose(origin, preferred) {
        if (contains(preferred)) return preferred
        const window = origin ? origin.QsWindow.window : null
        return window && contains(window.screen) ? window.screen : focusedScreen
    }
    function monitorFor(screen) {
        // Track model changes as well as the screen: the two IPC models may arrive in either order.
        const monitors = Hyprland.monitors.values
        return contains(screen) ? monitors.find(monitor => monitor.name === screen.name) || null : null
    }
    function workspaceFor(screen) {
        const monitor = monitorFor(screen)
        return monitor ? monitor.activeWorkspace : null
    }
}
