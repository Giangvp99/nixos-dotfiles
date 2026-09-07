import QtQuick

import "../config" as Config

Rectangle {
    id: root

    property string icon: ""
    property bool active: false
    property bool hovered: mouseArea.containsMouse

    signal clicked()

    implicitWidth: 28
    implicitHeight: 28

    radius: Config.Theme.radiusSmall

    color: {
        if (active)
            return Config.Theme.surface

        if (hovered)
            return Config.Theme.surfaceHover

        return "transparent"
    }

    Text {
        anchors.centerIn: parent

        text: root.icon

        color: root.active
            ? Config.Theme.primary
            : Config.Theme.subtext

        font.family: Config.Theme.fontFamily
        font.pixelSize: Config.Theme.fontLarge
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true

        cursorShape: Qt.PointingHandCursor

        onClicked:
            root.clicked()
    }

    Behavior on color {
        ColorAnimation {
            duration: Config.Animations.fast
        }
    }
}
