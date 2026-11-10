import QtQuick
import QtQuick.Layouts
import "../config" as Config

Rectangle {
    id: root
    property string icon: ""
    property string text: ""
    readonly property bool hovered: hover.hovered
    property color foreground: Config.Theme.controlForeground
    property color iconColor: Config.Theme.controlIcon
    property color background: Config.Theme.controlBackground
    property int horizontalPadding: Config.Theme.controlPadding
    property int spacing: Config.Theme.controlSpacing
    property int iconSize: Config.Theme.controlIconSize
    property int textSize: Config.Theme.fontNormal
    property int textFormat: Text.AutoText
    property int textWeight: Config.Theme.controlFontWeight
    property bool fillContentWidth: false
    property real maximumWidth: Infinity

    implicitWidth: Math.min(maximumWidth, content.implicitWidth + horizontalPadding * 2)
    implicitHeight: Config.Theme.controlHeight
    radius: Config.Theme.radiusSmall
    border.width: 0
    color: background
    Accessible.role: Accessible.StaticText
    Accessible.name: text

    RowLayout {
        id: content
        anchors.centerIn: parent
        width: root.fillContentWidth ? Math.max(0, root.width - root.horizontalPadding * 2)
            : Math.min(implicitWidth, Math.max(0, root.width - root.horizontalPadding * 2))
        spacing: root.spacing

        Text {
            visible: root.icon.length > 0
            text: root.icon
            color: root.iconColor
            font.family: Config.Theme.iconFontFamily
            font.pixelSize: root.iconSize
            verticalAlignment: Text.AlignVCenter
        }
        StyledText {
            Layout.fillWidth: true
            visible: root.text.length > 0
            text: root.text
            textFormat: root.textFormat
            color: root.foreground
            font.pixelSize: root.textSize
            font.weight: root.textWeight
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }

    HoverHandler { id: hover }
}
