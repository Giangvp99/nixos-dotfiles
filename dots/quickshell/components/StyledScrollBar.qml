import QtQuick
import QtQuick.Controls
import "../config" as Config

ScrollBar {
    id: root
    padding: Config.Theme.spaceTiny
    contentItem: Rectangle {
        visible: root.policy===ScrollBar.AlwaysOn || root.size<1
        implicitWidth: Config.Theme.spaceSmall
        implicitHeight: Config.Theme.spaceSmall
        radius: Config.Theme.spaceTiny
        color: root.pressed ? Config.Theme.primary : root.hovered ? Config.Theme.text : Config.Theme.subtext
        opacity: root.active || root.hovered || root.pressed ? 1 : 0.65
    }
    background: Rectangle { color: "transparent" }
}
