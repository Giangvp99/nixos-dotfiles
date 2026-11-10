import QtQuick
import QtQuick.Controls
import "../config" as Config

Slider {
    id: root
    from: 0
    to: 1
    stepSize: 0.01
    implicitHeight: Config.Theme.controlHeight
    opacity: enabled ? 1 : Config.Theme.disabledOpacity
    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth
        height: Config.Theme.spaceSmall
        radius: height / 2
        color: Config.Theme.surfaceHover
        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: parent.radius
            color: Config.Theme.primary
        }
    }
    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        implicitWidth: Config.Theme.spaceLarge
        implicitHeight: Config.Theme.spaceLarge
        radius: width / 2
        color: root.pressed || root.hovered ? Config.Theme.primary : Config.Theme.text
        Behavior on color {
            ColorAnimation {
                duration: Config.Animations.fast
                easing.type: Config.Animations.standardEasing
            }
        }
        border.width: root.activeFocus ? Config.Theme.focusBorderWidth : 0
        border.color: Config.Theme.primary
    }
}
