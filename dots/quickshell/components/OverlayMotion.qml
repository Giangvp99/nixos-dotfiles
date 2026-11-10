import QtQuick
import "../config" as Config

// Entrance only: closing never delays focus release or Loader destruction.
QtObject {
    id: root
    required property Item targetItem
    property bool shown: false
    readonly property bool running: fade.running
    function settle() {
        fade.stop()
        if (targetItem) targetItem.opacity = 1
    }
    function reveal() {
        settle()
        if (!targetItem) return
        if (shown && !Config.Animations.reducedMotion) fade.restart()
    }
    onShownChanged: reveal()
    Component.onCompleted: reveal()
    property NumberAnimation fade: NumberAnimation {
        target: root.targetItem
        property: "opacity"
        from: 0
        to: 1
        duration: Config.Animations.fast
        easing.type: Config.Animations.standardEasing
    }
    property Connections preferences: Connections {
        target: Config.Animations
        function onReducedMotionChanged() {
            if (Config.Animations.reducedMotion) root.settle()
        }
    }
}
