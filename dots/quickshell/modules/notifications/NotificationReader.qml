import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../config" as Config
import "../../components" as Components
import "../../services" as Services

ColumnLayout {
    id: root
    required property var entry
    readonly property alias backControl: back
    readonly property alias scrollView: scroll
    signal backRequested()
    spacing: Config.Theme.spaceMedium
    Keys.priority: Keys.BeforeItem
    Keys.onPressed: event => {
        if (event.key===Qt.Key_PageDown || event.key===Qt.Key_PageUp) {
            root.scrollPage(event.key===Qt.Key_PageDown ? 1 : -1);event.accepted=true
        } else event.accepted=false
    }
    function focusTargets() { return [back].concat(card.focusTargets().filter(item=>item!==card)) }
    function cycleFocus(delta) {
        const targets=focusTargets().filter(item=>item.visible && item.enabled)
        const current=targets.findIndex(item=>item.activeFocus)
        const next=targets[(current+delta+targets.length)%targets.length]
        next.forceActiveFocus()
        if (next!==back) {
            scroll.cancelFlick()
            const y=next.mapToItem(scroll.contentItem,0,0).y
            if (y<scroll.contentY) scroll.contentY=y
            else if (y+next.height>scroll.contentY+scroll.height) scroll.contentY=y+next.height-scroll.height
        }
    }
    function scrollBy(pixels) {
        scroll.cancelFlick()
        scroll.contentY=Math.max(0,Math.min(Math.max(0,scroll.contentHeight-scroll.height),scroll.contentY+pixels))
    }
    function scrollPage(direction) { scrollBy(direction*scroll.height*.85) }
    RowLayout {
        Layout.fillWidth: true
        Components.IconButton {
            id: back
            focus: true
            objectName: "notificationReaderBack"
            icon: "󰅁"
            text: "Back"
            focusController: root
            onClicked: root.backRequested()
        }
        Components.StyledText {
            Layout.fillWidth: true
            text: "Notification · " + root.entry.appName
            textFormat: Text.PlainText
            elide: Text.ElideRight
            font.pixelSize: Config.Theme.fontLarge
            horizontalAlignment: Text.AlignRight
        }
    }
    Components.StyledText {
        Layout.fillWidth: true
        visible: !root.entry.fullAvailable
        text: "Only the previously saved preview is available for this older notification."
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        color: Config.Theme.subtext
        font.pixelSize: Config.Theme.fontSmall
    }
    Flickable {
        id: scroll
        objectName: "notificationReaderScroll"
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        contentWidth: width
        contentHeight: card.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: event => {
            if (event.key===Qt.Key_PageDown || event.key===Qt.Key_PageUp) {
                root.scrollPage(event.key===Qt.Key_PageDown ? 1 : -1);event.accepted=true
            } else event.accepted=false
        }
        ScrollBar.vertical: Components.StyledScrollBar { policy: ScrollBar.AsNeeded }
        ToastCard {
            id: card
            width: scroll.width
            expandedContent: true
            focusController: root
            readonly property var live: Services.NotificationState.liveNotification(root.entry.id)
            record: ({notification:{appName:root.entry.appName,appIcon:root.entry.appIcon,
                summary:root.entry.summary,body:root.entry.body,urgency:root.entry.urgency,
                actions:live ? live.actions.map(action=>({identifier:action.identifier,text:action.text})) : []}})
            metadata: Qt.formatDateTime(new Date(root.entry.receivedAt),"HH:mm") + (live ? "" : " · Archived")
            dismissLabel: "Remove notification"
            onDismissRequested: Services.NotificationState.removeHistory(root.entry.id)
            onActionRequested: identifier=>Services.NotificationState.invokeHistory(root.entry.id,identifier)
        }
    }
}
