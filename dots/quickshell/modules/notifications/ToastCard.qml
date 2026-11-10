import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../../config" as Config
import "../../components" as Components

Components.Surface {
    id: root
    required property var record
    readonly property var notification: record ? record.notification : null
    readonly property bool hovered: hover.hovered
    readonly property string iconSource: notification && notification.appIcon
        ? Quickshell.iconPath(notification.appIcon, true) : ""
    property var focusController: null
    property string metadata: ""
    property string dismissLabel: "Dismiss notification"
    property bool unread: false
    readonly property alias dismissButton: closeButton
    function focusTargets() {
        const targets = [root]
        for (let i = 0; i < actionRepeater.count; ++i) {
            const button = actionRepeater.itemAt(i)
            if (button) targets.push(button)
        }
        targets.push(closeButton)
        return targets
    }
    signal dismissRequested()
    signal actionRequested(string identifier)
    function revealAction(item) {
        const left = item.mapToItem(actions, 0, 0).x
        if (left < actionViewport.contentX) actionViewport.contentX = left
        else if (left + item.width > actionViewport.contentX + actionViewport.width)
            actionViewport.contentX = left + item.width - actionViewport.width
        actionViewport.contentX = Math.max(0, Math.min(actionViewport.contentX,
            actionViewport.contentWidth - actionViewport.width))
    }
    panel: true
    border.color: notification && notification.urgency === NotificationUrgency.Critical
        ? Config.Theme.urgent : (unread ? Config.Theme.primary : Config.Theme.border)
    implicitHeight: content.implicitHeight + Config.Theme.panelPadding * 2

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
                implicitWidth: Config.Theme.notificationIconSize
                implicitHeight: Config.Theme.notificationIconSize
                IconImage {
                    anchors.centerIn: parent
                    implicitSize: Config.Theme.notificationIconSize
                    source: root.iconSource
                    visible: root.iconSource.length > 0
                }
                Components.StyledText {
                    anchors.centerIn: parent
                    visible: root.iconSource.length === 0
                    text: "󰂚"
                    font.family: Config.Theme.iconFontFamily
                    font.pixelSize: Config.Theme.notificationIconSize
                    color: Config.Theme.primary
                }
            }
            Components.StyledText {
                Layout.fillWidth: true
                text: root.notification ? (root.notification.appName || "Notification")
                    + (root.metadata.length ? " · " + root.metadata : "") : ""
                textFormat: Text.PlainText
                color: Config.Theme.subtext
                font.pixelSize: Config.Theme.fontSmall
                elide: Text.ElideRight
                maximumLineCount: 1
            }
            Components.IconButton {
                id: closeButton
                focusController: root.focusController
                objectName: "notificationDismiss"
                icon: "󰅖"
                Accessible.name: root.dismissLabel
                onClicked: root.dismissRequested()
            }
        }
        Components.StyledText {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.notification ? root.notification.summary : ""
            textFormat: Text.PlainText
            font.weight: Config.Theme.emphasisFontWeight
            font.pixelSize: Config.Theme.fontLarge
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
        Flickable {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(body.implicitHeight, Config.Config.notificationBodyMaxHeight)
            visible: body.text.length > 0
            contentWidth: width
            contentHeight: body.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Components.StyledText {
                id: body
                width: parent.width
                text: root.notification ? root.notification.body : ""
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
            }
        }
        Flickable {
            id: actionViewport
            objectName: "notificationActionViewport"
            Layout.fillWidth: true
            Layout.preferredHeight: Config.Theme.controlHeight
            visible: root.notification && root.notification.actions.length > 0
            contentWidth: actions.implicitWidth
            contentHeight: height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.HorizontalFlick
            Row {
                id: actions
                spacing: Config.Theme.spaceMedium
                Repeater {
                    id: actionRepeater
                    model: root.notification ? root.notification.actions : []
                    delegate: Components.IconButton {
                        id: actionButton
                        required property var modelData
                        focusController: root.focusController
                        onActiveFocusChanged: if (activeFocus) root.revealAction(actionButton)
                        objectName: "notificationAction_" + modelData.identifier
                        text: modelData.text || (modelData.identifier === "default" ? "Open" : modelData.identifier)
                        textFormat: Text.PlainText
                        maximumWidth: root.width - Config.Theme.panelPadding * 2
                        onClicked: root.actionRequested(modelData.identifier)
                    }
                }
            }
        }
    }
    HoverHandler { id: hover }
}
