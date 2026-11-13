import QtQuick
import QtQuick.Layouts
import "../config" as Config

IconButton {
    id: root
    property string label: ""
    property string stateText: active ? "On" : "Off"
    property string symbol: ""
    implicitWidth: 160
    implicitHeight: Config.Theme.controlHeight + Config.Theme.spaceLarge * 2
    border.width: activeFocus || active ? Config.Theme.focusBorderWidth : 0
    Accessible.role: Accessible.CheckBox
    Accessible.checkable: true
    Accessible.checked: active
    Accessible.name: label + ": " + stateText
    RowLayout {
        anchors.fill: parent
        anchors.margins: Config.Theme.controlPadding
        spacing: Config.Theme.spaceMedium
        StyledText {
            text: root.symbol
            font.family: Config.Theme.iconFontFamily
            font.pixelSize: Config.Theme.controlIconSize
            color: root.active ? Config.Theme.controlSelected : root.iconColor
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Config.Theme.spaceTiny
            StyledText { Layout.fillWidth: true; text: root.label; textFormat: Text.PlainText; elide: Text.ElideRight }
            StyledText {
                Layout.fillWidth: true
                text: root.stateText
                textFormat: Text.PlainText
                font.pixelSize: Config.Theme.fontSmall
                color: root.active ? Config.Theme.controlSelected : Config.Theme.subtext
                elide: Text.ElideRight
            }
        }
    }
}
