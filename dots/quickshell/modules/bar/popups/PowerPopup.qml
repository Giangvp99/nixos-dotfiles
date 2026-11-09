import QtQuick
import QtQuick.Layouts

import Quickshell

import "../../../config" as Config
import "../../../components" as Components
import "../../../services" as Services

PopupWindow {
    id: root

    property Item anchorItem

    width: 220
    height: content.implicitHeight + 24

    visible: false
    grabFocus: true

    color: "transparent"

    anchor {
        item:
            root.anchorItem

        edges:
            Edges.Bottom
            | Edges.Right

        gravity:
            Edges.Bottom
            | Edges.Left

        margins.bottom: 8

        adjustment:
            PopupAdjustment.Slide
            | PopupAdjustment.Flip
    }

    Rectangle {
        anchors.fill: parent

        color:
            Config.Theme.background

        radius:
            Config.Theme.radiusMedium

        border.width: 1
        border.color:
            Config.Theme.surface

        ColumnLayout {
            id: content

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 12
            }

            spacing: 6

            Components.StyledText {
                Layout.fillWidth: true

                text: "Session"

                font.bold: true

                font.pixelSize:
                    Config.Theme.fontLarge
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1

                color:
                    Config.Theme.surface
            }

            PowerItem {
                icon: "󰌾"
                label: "Lock"

                onTriggered: {
                    root.visible = false
                    Services.PowerService.lock()
                }
            }

            PowerItem {
                icon: "󰍃"
                label: "Logout"

                onTriggered: {
                    root.visible = false
                    Services.PowerService.logout()
                }
            }

            PowerItem {
                icon: "󰜉"
                label: "Reboot"

                onTriggered: {
                    root.visible = false
                    Services.PowerService.reboot()
                }
            }

            PowerItem {
                icon: "󰐥"
                label: "Shutdown"
                dangerous: true

                onTriggered: {
                    root.visible = false
                    Services.PowerService.shutdown()
                }
            }
        }
    }

    component PowerItem: Rectangle {
        id: item

        property string icon: ""
        property string label: ""
        property bool dangerous: false

        signal triggered()

        Layout.fillWidth: true

        implicitHeight: 42

        radius:
            Config.Theme.radiusSmall

        color:
            mouseArea.containsMouse
            ? Config.Theme.surfaceHover
            : "transparent"

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 10
                rightMargin: 10
            }

            spacing: 10

            Components.StyledText {
                text:
                    item.icon

                color:
                    item.dangerous
                    ? Config.Theme.urgent
                    : Config.Theme.text

                font.pixelSize:
                    Config.Theme.fontLarge
            }

            Components.StyledText {
                Layout.fillWidth: true

                text:
                    item.label

                color:
                    item.dangerous
                    ? Config.Theme.urgent
                    : Config.Theme.text
            }
        }

        MouseArea {
            id: mouseArea

            anchors.fill: parent

            hoverEnabled: true

            cursorShape:
                Qt.PointingHandCursor

            onClicked:
                item.triggered()
        }

        Behavior on color {
            ColorAnimation {
                duration:
                    Config.Animations.fast
            }
        }
    }
}
