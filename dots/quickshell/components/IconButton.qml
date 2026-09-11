import QtQuick
import QtQuick.Layouts

import "../config" as Config

Rectangle {
    id: root

    property string icon: ""
    property string text: ""

    property bool active: false
    property bool hovered: mouseArea.containsMouse

    property int horizontalPadding: 8
    property int spacing: 6

    signal clicked()
    signal rightClicked()
    signal middleClicked()

    implicitWidth:
        content.implicitWidth
        + horizontalPadding * 2

    implicitHeight: 28

    radius:
        Config.Theme.radiusSmall

    color: {
        if (hovered)
            return Config.Theme.surfaceHover

        if (active)
            return Config.Theme.surface

        return "transparent"
    }

    RowLayout {
        id: content

        anchors.centerIn: parent

        spacing:
            root.spacing

        Text {
            visible:
                root.icon.length > 0

            text:
                root.icon

            color:
                root.active
                ? Config.Theme.primary
                : Config.Theme.subtext

            font.family:
                Config.Theme.fontFamily

            font.pixelSize:
                Config.Theme.fontLarge

            verticalAlignment:
                Text.AlignVCenter
        }

        Text {
            visible:
                root.text.length > 0

            text:
                root.text

            color:
                Config.Theme.text

            font.family:
                Config.Theme.fontFamily

            font.pixelSize:
                Config.Theme.fontNormal

            verticalAlignment:
                Text.AlignVCenter

            elide:
                Text.ElideRight
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent

        hoverEnabled: true

        acceptedButtons:
            Qt.LeftButton
            | Qt.RightButton
            | Qt.MiddleButton

        cursorShape:
            Qt.PointingHandCursor

        onClicked: mouse => {
            switch (mouse.button) {
            case Qt.LeftButton:
                root.clicked()
                break

            case Qt.RightButton:
                root.rightClicked()
                break

            case Qt.MiddleButton:
                root.middleClicked()
                break
            }
        }
    }

    Behavior on color {
        ColorAnimation {
            duration:
                Config.Animations.fast
        }
    }
}
