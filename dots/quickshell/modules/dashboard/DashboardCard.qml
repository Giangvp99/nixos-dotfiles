import QtQuick
import QtQuick.Layouts
import "../../config" as Config
import "../../components" as Components

Components.Surface {
    id: root
    property string title: ""
    default property alias content: layout.data
    implicitWidth: 240
    implicitHeight: layout.implicitHeight + Config.Theme.panelPadding * 2
    radius: Config.Theme.radiusMedium
    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Config.Theme.panelPadding
        spacing: Config.Theme.spaceMedium
        Components.StyledText {
            visible: root.title.length > 0
            text: root.title
            color: Config.Theme.subtext
            font.pixelSize: Config.Theme.fontSmall
            font.weight: Config.Theme.emphasisFontWeight
        }
    }
}
