import Quickshell
import Quickshell.Io
import "../../config" as Config
import "../../services" as Services

Scope {
    id: root
    // A PID + process-start token survives QML reloads, never another process.
    readonly property string processStart: {
        if (!processInfo.loaded) return ""
        const stat = processInfo.text()
        const end = stat.lastIndexOf(") ")
        return end < 0 ? "" : (stat.slice(end + 2).trim().split(/\s+/)[19] || "")
    }
    readonly property bool sessionEnabled: processStart.length > 0
        && sessionFile.loaded && sessionFile.text().trim() === processStart
    readonly property bool enabled: Config.Config.notificationsEnabled || sessionEnabled

    FileView {
        id: processInfo
        path: "/proc/self/stat"
        preload: true
        blockLoading: true
    }
    FileView {
        id: sessionFile
        path: "/tmp/quickshell-notifications-" + Quickshell.processId
        preload: true
        blockLoading: true
        blockWrites: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
    }
    IpcHandler {
        target: "notifications"
        function start(): void {
            if (!root.processStart.length) throw new Error("Cannot read process start token")
            sessionFile.setText(root.processStart + "\n")
        }
        function toggleCenter(): bool {
            const state = Services.NotificationState
            const center=state.centerForScreen(Services.ScreenService.focusedScreen)
            if (!state.available || !center) return false
            center.toggle()
            return true
        }
        function setDnd(value: bool): void {
            if (Services.NotificationState.dnd !== value) Services.NotificationState.toggleDnd()
        }
        function remove(id: int): void { Services.NotificationState.removeHistory(id) }
        function started(): bool { return root.enabled }
        function status(): string {
            return JSON.stringify({enabled: root.enabled, processId: Quickshell.processId,
                processStart: root.processStart, stateLoaded: sessionFile.loaded,
                marker: sessionFile.loaded ? sessionFile.text().trim() : "",
                available: Services.NotificationState.available,
                historyCount: Services.NotificationState.history.length,
                liveCount: Services.NotificationState.service ? Services.NotificationState.service.count : 0,
                visibleToastCount: Services.NotificationState.service ? Services.NotificationState.service.visibleRecords.length : 0,
                unreadCount: Services.NotificationState.unreadCount,
                dnd: Services.NotificationState.dnd,
                centerOpen: Services.NotificationState.centerOpen})
        }
    }
    LazyLoader {
        active: root.enabled
        NotificationToasts {}
    }
}
