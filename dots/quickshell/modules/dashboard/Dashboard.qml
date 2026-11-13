import QtQuick
import Quickshell
import Quickshell.Io
import "../../config" as Config
import "../../components" as Components
import "../../services" as Services

Scope {
    id: root
    property bool opened: false
    property var sessionMemory: null
    onOpenedChanged: if (sessionMemory) { sessionMemory.opened = opened; sessionMemory.screenName = route.screenName }
    function restoreSession(memory) {
        const wasOpen = memory.opened
        sessionMemory = memory
        if (wasOpen) Qt.callLater(function() {
            const preferred=Services.ScreenService.screens.find(screen => screen.name === memory.screenName)
            if (memory.screenName && !preferred) { memory.opened=false; return }
            root.open(null, preferred)
        })
    }
    readonly property alias panel: window
    readonly property alias content: loader.item
    readonly property alias returnFocusItem: focusReturn.origin
    Components.OverlayFocus { id: focusReturn; opened: root.opened; windowVisible: window.backingWindowVisible }
    readonly property var targetScreen: route.screen
    Components.OverlayScreen { id: route; active: root.opened; onRemoved: root.close(false) }
    signal opening()
    signal launcherRequested()
    signal notificationsRequested()
    signal shortcutsRequested()
    function open(origin, preferredScreen) { if (!opened) route.capture(origin, preferredScreen); opening(); focusReturn.remember(origin); opened = true; Qt.callLater(focusContent) }
    function close(restoreFocus = true) { opened = false; focusReturn.finish(restoreFocus) }
    function toggle(origin) { if (opened) close(); else open(origin) }
    function focusContent() { if (opened && loader.item) loader.item.closeControl.forceActiveFocus() }
    function revealFocus() { if (opened && loader.item) loader.item.revealFocus() }
    Component.onCompleted: Services.DashboardState.controller = root
    Component.onDestruction: if (Services.DashboardState.controller === root) Services.DashboardState.controller = null
    IpcHandler {
        target: "dashboard"
        function open(): void { root.open() }
        function close(): void { root.close() }
        function toggle(): void { root.toggle() }
        function status(): string { return JSON.stringify({opened: root.opened, loaded: loader.item !== null}) }
    }
    PanelWindow {
        id: window
        screen: route.screen
        visible: root.opened && route.valid
        focusable: true
        aboveWindows: true
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        onBackingWindowVisibleChanged: if (backingWindowVisible) Qt.callLater(root.focusContent)
        Rectangle {
            anchors.fill: parent
            color: Config.Theme.overlay
            MouseArea { anchors.fill: parent; onClicked: root.close(false) }
        }
        Components.OverlayMotion {
            targetItem: surface
            shown: window.backingWindowVisible && root.opened
        }
        Components.Surface {
            id: surface
            objectName: "dashboardSurface"
            panel: true
            radius: Config.Theme.radiusLarge
            width: Math.max(0, Math.min(Config.Config.dashboardWidth, parent.width - Config.Theme.panelPadding * 2))
            height: Math.max(0, Math.min(Config.Config.dashboardMaxHeight,
                parent.height - Config.Theme.panelPadding * 2))
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            MouseArea { anchors.fill: parent }
            Loader {
                id: loader
                anchors.fill: parent
                anchors.margins: Config.Theme.panelPadding
                active: root.opened
                onLoaded: Qt.callLater(root.focusContent)
                sourceComponent: DashboardContent {
                    page: root.sessionMemory && typeof root.sessionMemory.page === "number" ? root.sessionMemory.page : 0
                    onPageChanged: if (root.sessionMemory && typeof root.sessionMemory.page === "number") root.sessionMemory.page = page
                    workspace: Services.ScreenService.workspaceFor(window.screen)
                    onCloseRequested: root.close()
                    onLaunchRequested: app => { root.close(false); Services.AppService.launch(app) }
                    onLauncherRequested: root.launcherRequested()
                    onNotificationsRequested: root.notificationsRequested()
                    onShortcutsRequested: root.shortcutsRequested()
                }
            }
        }
    }
}
