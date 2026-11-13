import QtQuick
import "../config" as Config

StatusText {
    id: root
    property bool active: false
    property bool wheelEnabled: false
    property bool doubleClickEnabled: false
    readonly property bool clickPending: singleClick.running
    property var focusController: null
    readonly property bool pressed: mouseArea.pressed
    signal clicked()
    signal doubleClicked()
    signal rightClicked()
    signal middleClicked()
    signal scrolled(real delta)

    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: text
    Keys.onTabPressed: event => {
        if (focusController) focusController.cycleFocus(1)
        else event.accepted = false
    }
    Keys.onBacktabPressed: event => {
        if (focusController) focusController.cycleFocus(-1)
        else event.accepted = false
    }
    Keys.onEnterPressed: if (enabled) clicked()
    Keys.onReturnPressed: if (enabled) clicked()
    Keys.onSpacePressed: if (enabled) clicked()
    border.width: activeFocus || active ? Config.Theme.focusBorderWidth : 0
    border.color: Config.Theme.controlSelected
    foreground: active && icon.length === 0 ? Config.Theme.controlSelected : Config.Theme.controlForeground
    iconColor: active ? Config.Theme.controlSelected : Config.Theme.controlIcon
    opacity: enabled ? 1 : Config.Theme.disabledOpacity
    color: pressed ? Config.Theme.controlPressed
        : (hovered ? Config.Theme.controlHovered : background)

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            switch (mouse.button) {
            case Qt.LeftButton:
                if (root.doubleClickEnabled) singleClick.restart()
                else root.clicked()
                break
            case Qt.RightButton: root.rightClicked(); break
            case Qt.MiddleButton: root.middleClicked(); break
            }
        }
        onDoubleClicked: mouse => {
            if (root.doubleClickEnabled && mouse.button === Qt.LeftButton) {
                singleClick.stop()
                root.doubleClicked()
                mouse.accepted = true
            } else {
                // A connected double-click handler consumes the second ordinary click.
                // Preserve two activations for buttons that do not opt into the gesture.
                switch (mouse.button) {
                case Qt.LeftButton: root.clicked(); break
                case Qt.RightButton: root.rightClicked(); break
                case Qt.MiddleButton: root.middleClicked(); break
                }
                mouse.accepted = true
            }
        }
        onWheel: event => {
            if (root.wheelEnabled) root.scrolled(event.angleDelta.y)
            else event.accepted = false
        }
    }
    onVisibleChanged: if (!visible) singleClick.stop()
    onEnabledChanged: if (!enabled) singleClick.stop()
    Timer {
        id: singleClick
        interval: Qt.styleHints.mouseDoubleClickInterval
        onTriggered: if (root.enabled && root.visible) root.clicked()
    }
    Behavior on color {
        ColorAnimation {
            duration: Config.Animations.fast
            easing.type: Config.Animations.standardEasing
        }
    }
}
