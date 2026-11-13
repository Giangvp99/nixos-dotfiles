import QtQuick
import Quickshell
import "../services" as Services

// Capture once on open; a lost output closes the owner without restoring focus.
QtObject {
    id: root
    property var screen: null
    property string screenName: ""
    property bool active: false
    readonly property bool valid: Services.ScreenService.contains(screen)
    signal removed()
    function capture(origin, preferred) {
        const next = Services.ScreenService.choose(origin, preferred)
        screenName = next ? next.name : ""
        screen = next
    }
    function validate() { if (active && !valid) removed() }
    onActiveChanged: if (active) Qt.callLater(root.validate)
    onValidChanged: if (active && !valid) Qt.callLater(root.validate)
    property Connections outputs: Connections {
        target: Services.ScreenService
        function onScreensChanged() { root.validate() }
    }
}
