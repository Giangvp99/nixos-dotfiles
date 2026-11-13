import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../bar/popups" as Popups
import "../../config" as Config
import "../../components" as Components
import "../../services" as Services

Popups.BarPopup {
    id: root
    preferredWidth: reading ? Config.Config.notificationReaderWidth : Config.Config.notificationCenterWidth
    preferredHeight: reading ? Config.Config.notificationReaderHeight : Services.NotificationState.history.length ? Config.Config.notificationCenterHeight : 210
    initialFocusItem: reading && reader.item ? reader.item.backControl : dndButton
    property int selectedId: -1
    property int readingId: -1
    property real savedListOffset: 0
    readonly property var readingEntry: Services.NotificationState.detailFor(readingId)
    readonly property bool reading: readingId>=0 && readingEntry!==null
    onReadingEntryChanged: if (readingId>=0 && !readingEntry) Qt.callLater(root.closeMissingReader)
    function closeMissingReader() {
        if (readingId>=0 && !readingEntry) backToList()
    }
    function readNotification(id) {
        if (!Services.NotificationState.entryFor(id)) return
        selectedId=id
        savedListOffset=historyList.currentItem ? historyList.contentY-historyList.currentItem.y : historyList.contentY
        readingId=id
        Qt.callLater(root.focusReader)
    }
    function focusReader() { if (reading && reader.item) reader.item.backControl.forceActiveFocus() }
    function backToList() {
        readingId=-1
        Qt.callLater(function() { Qt.callLater(root.restoreListFocus) })
    }
    function restoreListFocus() {
        if (!visible || reading || !historyList.currentItem) return
        const minimum=historyList.originY, maximum=minimum+Math.max(0,historyList.contentHeight-historyList.height)
        historyList.contentY=Math.max(minimum,Math.min(maximum,historyList.currentItem.y+savedListOffset))
        historyList.currentItem.forceActiveFocus()
    }
    property bool listHadFocus: false
    readonly property ScriptModel historyModel: ScriptModel { values: Services.NotificationState.history }

    function focusRow(index) {
        if (!historyList.count) return
        historyList.currentIndex = (index + historyList.count) % historyList.count
        historyList.positionViewAtIndex(historyList.currentIndex, ListView.Beginning)
        Qt.callLater(function() {
            if (root.visible && historyList.currentItem) {
                root.listHadFocus = true
                historyList.currentItem.forceActiveFocus()
            }
        })
    }
    function moveRow(delta) {
        root.focusRow(root.listHadFocus ? historyList.currentIndex + delta : (delta > 0 ? 0 : historyList.count - 1))
    }
    function handleReadingKey(event) {
        if (event.key===Qt.Key_PageDown || event.key===Qt.Key_PageUp) {
            scrollPage(event.key===Qt.Key_PageDown ? 1 : -1)
            event.accepted=true
        } else event.accepted=false
    }
    function scrollPage(direction) {
        if (reading && reader.item) { reader.item.scrollPage(direction);return }
        historyList.cancelFlick()
        const minimum=historyList.originY
        const maximum=minimum+Math.max(0,historyList.contentHeight-historyList.height)
        historyList.contentY=Math.max(minimum,Math.min(maximum,historyList.contentY+direction*historyList.height*.85))
    }
    function revealControl(item) {
        if (!item || !historyList.currentItem) return
        if (item===historyList.currentItem) {
            historyList.positionViewAtIndex(historyList.currentIndex,ListView.Beginning)
            return
        }
        const top=item.mapToItem(historyList.contentItem,0,0).y
        if (top<historyList.contentY) historyList.contentY=top
        else if (top+item.height>historyList.contentY+historyList.height)
            historyList.contentY=top+item.height-historyList.height
    }
    function cycleFocus(delta) {
        if (reading && reader.item) { reader.item.cycleFocus(delta);return }
        let targets = [dndButton]
        if (clearButton.enabled) targets.push(clearButton)
        if (historyList.currentItem) targets = targets.concat(historyList.currentItem.focusTargets())
        targets = targets.filter(item => item && item.visible && item.enabled)
        if (!targets.length) return
        const current = targets.findIndex(item => item.activeFocus)
        const index = current < 0 ? (delta > 0 ? 0 : targets.length - 1)
            : (current + delta + targets.length) % targets.length
        targets[index].forceActiveFocus()
        if (root.listHadFocus) root.revealControl(targets[index])
    }
    Connections {
        target: root
        function onVisibleChanged() {
            root.listHadFocus = false
            if (!root.visible) root.readingId=-1
            if (root.visible) { root.selectedId = -1; historyList.currentIndex = 0 }
            if (root.visible) Services.NotificationState.center=root
            Services.NotificationState.setCenterOpen(root.visible)
        }
    }
    Connections {
        target: Services.NotificationState
        function onHistoryChanged() {
            if (!root.visible) return
            const entries = Services.NotificationState.history
            const selected = entries.findIndex(entry => entry.id === root.selectedId)
            historyList.currentIndex = selected >= 0 ? selected : 0
            if (!root.reading && root.listHadFocus && entries.length) Qt.callLater(function() {
                if (root.visible && !root.reading && root.listHadFocus && historyList.currentItem)
                    historyList.currentItem.forceActiveFocus()
            })
        }
    }
    Component.onCompleted: Services.NotificationState.registerCenter(root)
    Component.onDestruction: {
        Services.NotificationState.unregisterCenter(root)
    }

    Components.Surface {
        panel: true
        anchors.fill: parent
        Keys.onEscapePressed: { if (root.reading) root.backToList(); else root.close(true) }
        Keys.onDownPressed: { if (root.reading && reader.item) reader.item.scrollBy(40); else root.moveRow(1) }
        Keys.onUpPressed: { if (root.reading && reader.item) reader.item.scrollBy(-40); else root.moveRow(-1) }
        Keys.onPressed: event => root.handleReadingKey(event)
        Keys.onTabPressed: root.cycleFocus(1)
        Keys.onBacktabPressed: root.cycleFocus(-1)
        Loader {
            id: reader
            objectName: "notificationReaderLoader"
            anchors.fill: parent
            anchors.margins: Config.Theme.popupPadding
            active: root.reading
            focus: active
            visible: active
            onLoaded: Qt.callLater(root.focusReader)
            sourceComponent: NotificationReader {
                entry: root.readingEntry || ({id:-1,appName:"",summary:"",body:"",appIcon:"",urgency:1,receivedAt:0,fullAvailable:true})
                onBackRequested: root.backToList()
            }
        }
        ColumnLayout {
            visible: !root.reading
            anchors.fill: parent
            anchors.margins: Config.Theme.popupPadding
            spacing: Config.Theme.spaceMedium
            RowLayout {
                Layout.fillWidth: true
                Components.StyledText {
                    Layout.fillWidth: true
                    text: "Notifications"
                    font.pixelSize: Config.Theme.fontLarge
                    font.weight: Config.Theme.emphasisFontWeight
                    elide: Text.ElideRight
                }
                Components.IconButton {
                    id: clearButton
                    focusController: root
                    objectName: "notificationClearAll"
                    text: "Clear all"
                    enabled: Services.NotificationState.history.length > 0
                    onActiveFocusChanged: if (activeFocus) root.listHadFocus = false
                    onClicked: {
                        root.listHadFocus = false
                        Services.NotificationState.clearHistory()
                        dndButton.forceActiveFocus()
                    }
                }
            }
            Components.IconButton {
                id: dndButton
                focusController: root
                objectName: "notificationDnd"
                Layout.fillWidth: true
                fillContentWidth: true
                icon: Services.NotificationState.dnd ? "󰂛" : "󰂚"
                text: "Do not disturb · " + (Services.NotificationState.dnd ? "On" : "Off")
                active: Services.NotificationState.dnd
                onActiveFocusChanged: if (activeFocus) root.listHadFocus = false
                onClicked: Services.NotificationState.toggleDnd()
            }
            Components.StyledText {
                Layout.fillWidth: true
                text: Services.NotificationState.history.length + " notifications"
                color: Config.Theme.subtext
                font.pixelSize: Config.Theme.fontSmall
            }
            ListView {
                id: historyList
                objectName: "notificationHistoryList"
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: count > 0
                clip: true
                spacing: Config.Theme.spaceMedium
                boundsBehavior: Flickable.StopAtBounds
                keyNavigationEnabled: false
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: event => root.handleReadingKey(event)
                model: root.historyModel
                ScrollBar.vertical: Components.StyledScrollBar { policy: ScrollBar.AsNeeded }
                delegate: NotificationHistoryItem {
                    required property var modelData
                    required property int index
                    width: historyList.width
                    entry: modelData
                    onReadRequested: notificationId=>root.readNotification(notificationId)
                    focusController: root
                    onActiveFocusChanged: if (activeFocus) {
                        historyList.currentIndex = index
                        root.selectedId = entry.id
                        root.listHadFocus = true
                    }
                }
            }
            Components.StyledText {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !historyList.count
                text: "You're all caught up"
                horizontalAlignment: Text.AlignHCenter
                color: Config.Theme.subtext
                wrapMode: Text.Wrap
            }
        }
    }
}
