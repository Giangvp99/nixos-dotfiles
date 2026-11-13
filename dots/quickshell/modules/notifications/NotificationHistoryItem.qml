import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../../config" as Config
import "../../components" as Components
import "../../services" as Services

Components.Surface {
    id: root
    required property var entry
    property var focusController: null
    readonly property var activeNotification: Services.NotificationState.liveNotification(entry.id)
    readonly property alias dismissButton: dismiss
    signal readRequested(int notificationId)
    objectName: "notificationHistory_" + entry.id
    implicitHeight: content.implicitHeight + Config.Theme.panelPadding*2
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: entry.appName + ": " + entry.summary + ". Read notification"
    panel: true
    border.color: activeFocus || entry.unread ? Config.Theme.primary : entry.urgency===2 ? Config.Theme.urgent : Config.Theme.border
    border.width: activeFocus ? 2 : 1
    function focusTargets() { return [root,read,dismiss] }
    Keys.onReturnPressed: readRequested(entry.id)
    Keys.onEnterPressed: readRequested(entry.id)
    Keys.onSpacePressed: readRequested(entry.id)
    Keys.onDeletePressed: Services.NotificationState.removeHistory(entry.id)
    Keys.onTabPressed: if (focusController) focusController.cycleFocus(1)
    Keys.onBacktabPressed: if (focusController) focusController.cycleFocus(-1)
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: { root.forceActiveFocus(); root.readRequested(root.entry.id) }
    }
    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Config.Theme.panelPadding
        spacing: Config.Theme.spaceMedium
        RowLayout {
            Layout.fillWidth: true
            spacing: Config.Theme.spaceMedium
            Item {
                implicitWidth: Config.Theme.controlHeight
                implicitHeight: Config.Theme.controlHeight
                IconImage {
                    anchors.centerIn: parent
                    implicitSize: Config.Theme.controlIconSize
                    source: root.entry.appIcon ? Quickshell.iconPath(root.entry.appIcon,true) : ""
                    visible: root.entry.appIcon.length>0
                }
                Components.StyledText {
                    anchors.centerIn: parent
                    visible: !root.entry.appIcon
                    text: "󰂚"
                    font.family: Config.Theme.iconFontFamily
                    font.pixelSize: Config.Theme.controlIconSize
                    color: Config.Theme.primary
                }
            }
            Components.StyledText {
                Layout.fillWidth: true
                text: root.entry.appName + " · " + Qt.formatDateTime(new Date(root.entry.receivedAt),"HH:mm") + (root.activeNotification ? "" : " · Archived")
                textFormat: Text.PlainText
                font.pixelSize: Config.Theme.fontSmall
                color: Config.Theme.subtext
                elide: Text.ElideRight
            }
            Components.IconButton {
                id: dismiss
                objectName: "notificationDismiss"
                icon: "󰅖"
                Accessible.name: "Remove notification"
                focusController: root.focusController
                onClicked: Services.NotificationState.removeHistory(root.entry.id)
            }
        }
        Components.StyledText {
            objectName: "notificationPreviewSummary"
            Layout.fillWidth: true
            text: root.entry.summary
            textFormat: Text.PlainText
            font.pixelSize: Config.Theme.fontLarge
            font.weight: Config.Theme.emphasisFontWeight
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
        Components.StyledText {
            objectName: "notificationPreviewBody"
            Layout.fillWidth: true
            visible: text.length>0
            text: root.entry.body
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: 4
            elide: Text.ElideRight
            color: Config.Theme.subtext
        }
        Components.IconButton {
            id: read
            objectName: "notificationRead_" + root.entry.id
            Layout.fillWidth: true
            text: "Read notification"
            focusController: root.focusController
            onClicked: root.readRequested(root.entry.id)
        }
    }
}
