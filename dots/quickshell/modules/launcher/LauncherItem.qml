import QtQuick
import QtQuick.Layouts
import "../../config" as Config
import "../../components" as Components

Components.IconButton {
    id: root
    required property var app
    required property bool selected
    property bool pinned: false
    signal activated()

    activeFocusOnTab: false
    Accessible.name: app ? app.name : ""
    implicitHeight: Config.Config.launcherRowHeight
    active: selected
    background: selected ? Config.Theme.surfaceHover : "transparent"
    border.width: selected ? Config.Theme.focusBorderWidth : 0
    border.color: Config.Theme.primary
    onClicked: activated()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Config.Theme.spaceLarge
        anchors.rightMargin: Config.Theme.spaceLarge
        spacing: Config.Theme.spaceLarge

        Components.AppIcon {
            appEntry: root.app
            appId: root.app ? root.app.id : ""
            iconSize: Config.Theme.launcherIconSize
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Components.StyledText {
                Layout.fillWidth: true
                text: root.app ? root.app.name : ""
                font.weight: root.selected ? Config.Theme.emphasisFontWeight : Config.Theme.controlFontWeight
                elide: Text.ElideRight
                maximumLineCount: 1
            }
            Components.StyledText {
                Layout.fillWidth: true
                visible: text.length > 0
                text: root.app ? (root.app.genericName || "") : ""
                color: Config.Theme.subtext
                font.pixelSize: Config.Theme.fontSmall
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }
        Components.StyledText {
            visible: root.pinned
            text: "󰐃"
            color: Config.Theme.primary
            font.family: Config.Theme.iconFontFamily
            font.pixelSize: Config.Theme.controlIconSize
            Accessible.name: "Pinned"
        }
    }
}
