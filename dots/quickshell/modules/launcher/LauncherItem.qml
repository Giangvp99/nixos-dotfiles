import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../config" as Config
import "../../components" as Components

Rectangle {
    id: root

    required property var app
    required property bool selected

    signal activated()

    implicitHeight: 52
    radius: Config.Theme.radiusSmall

    color:
        selected || mouseArea.containsMouse
            ? Config.Theme.surfaceHover
            : "transparent"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        spacing: 12

        Image {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28

            source:
                root.app.icon
                    ? Quickshell.iconPath(
                        root.app.icon,
                        true
                    )
                    : ""

            fillMode:
                Image.PreserveAspectFit
        }

        ColumnLayout {
            Layout.fillWidth: true

            spacing: 1

            Components.StyledText {
                Layout.fillWidth: true

                text:
                    root.app.name || ""

                color:
                    Config.Theme.text

                font.pixelSize:
                    Config.Theme.fontNormal

                elide:
                    Text.ElideRight
            }

            Components.StyledText {
                Layout.fillWidth: true

                visible:
                    text.length > 0

                text:
                    root.app.genericName || ""

                color:
                    Config.Theme.subtext

                font.pixelSize:
                    Config.Theme.fontSmall

                elide:
                    Text.ElideRight
            }
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent

        hoverEnabled: true

        cursorShape:
            Qt.PointingHandCursor

        onClicked:
            root.activated()
    }
}
