import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../config" as Config
import "../../components" as Components
import "../../services" as Services

Scope {
    id: root
    property bool opened: false
    property var sessionMemory: null
    onOpenedChanged: if (sessionMemory) sessionMemory.opened = opened
    function restoreSession(memory) {
        const wasOpen = memory.opened
        sessionMemory = memory
        if (wasOpen) Qt.callLater(root.open)
    }
    readonly property alias panel: window
    readonly property alias content: loader.item
    readonly property alias returnFocusItem: focusReturn.origin
    Components.OverlayFocus { id: focusReturn; opened: root.opened; windowVisible: window.backingWindowVisible }
    signal opening()
    signal launcherRequested()
    signal notificationsRequested()
    function open(origin) { opening(); focusReturn.remember(origin); scroll.contentY = 0; opened = true; Qt.callLater(focusContent) }
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
        visible: root.opened
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
                loader.item ? loader.item.implicitHeight + Config.Theme.panelPadding * 2 : 0,
                parent.height - Config.Theme.panelPadding * 2))
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.min(Math.max(Config.Theme.panelPadding, parent.height * 0.1),
                Math.max(Config.Theme.panelPadding, parent.height - height - Config.Theme.panelPadding))
            MouseArea { anchors.fill: parent }
            Flickable {
                id: scroll
                onHeightChanged: Qt.callLater(root.revealFocus)
                onContentHeightChanged: Qt.callLater(root.revealFocus)
                objectName: "dashboardScroll"
                anchors.fill: parent
                anchors.margins: Config.Theme.panelPadding
                contentWidth: width
                contentHeight: loader.item ? loader.item.implicitHeight : 0
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                Loader {
                    id: loader
                    width: scroll.width
                    height: item ? item.implicitHeight : 0
                    active: root.opened
                    onLoaded: Qt.callLater(root.focusContent)
                    sourceComponent: DashboardContent {
                        onLayoutUpdated: Qt.callLater(root.revealFocus)
                        onFocusRequested: item => {
                            const top = item.mapToItem(loader.item, 0, 0).y
                            if (top < scroll.contentY) scroll.contentY = top
                            else if (top + item.height > scroll.contentY + scroll.height)
                                scroll.contentY = top + item.height - scroll.height
                            scroll.contentY = Math.max(0, Math.min(scroll.contentY, scroll.contentHeight - scroll.height))
                        }
                        onCloseRequested: root.close()
                        onLaunchRequested: app => { root.close(false); Services.AppService.launch(app) }
                        onLauncherRequested: root.launcherRequested()
                        onNotificationsRequested: root.notificationsRequested()
                    }
                }
            }
        }
    }
}
