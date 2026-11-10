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
    preferredWidth: Config.Config.notificationCenterWidth
    preferredHeight: Services.NotificationState.history.length ? Config.Config.notificationCenterHeight : 210
    initialFocusItem: dndButton
    property int selectedId: -1
    property bool listHadFocus: false
    readonly property ScriptModel historyModel: ScriptModel { values: Services.NotificationState.history }

    function focusRow(index) {
        if (!historyList.count) return
        historyList.currentIndex = (index + historyList.count) % historyList.count
        historyList.positionViewAtIndex(historyList.currentIndex, ListView.Contain)
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
    function cycleFocus(delta) {
        let targets = [dndButton]
        if (clearButton.enabled) targets.push(clearButton)
        if (historyList.currentItem) targets = targets.concat(historyList.currentItem.focusTargets())
        targets = targets.filter(item => item && item.visible && item.enabled)
        if (!targets.length) return
        const current = targets.findIndex(item => item.activeFocus)
        const index = current < 0 ? (delta > 0 ? 0 : targets.length - 1)
            : (current + delta + targets.length) % targets.length
        targets[index].forceActiveFocus()
        if (root.listHadFocus)
            historyList.positionViewAtIndex(historyList.currentIndex, ListView.Contain)
    }
    Connections {
        target: root
        function onVisibleChanged() {
            root.listHadFocus = false
            if (root.visible) { root.selectedId = -1; historyList.currentIndex = 0 }
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
            if (root.listHadFocus && entries.length) Qt.callLater(function() {
                if (root.visible && root.listHadFocus) root.focusRow(historyList.currentIndex)
            })
        }
    }
    Component.onCompleted: Services.NotificationState.center = root
    Component.onDestruction: {
        if (Services.NotificationState.center === root) Services.NotificationState.center = null
        Services.NotificationState.setCenterOpen(false)
    }

    Components.Surface {
        panel: true
        anchors.fill: parent
        Keys.onEscapePressed: root.close(true)
        Keys.onDownPressed: root.moveRow(1)
        Keys.onUpPressed: root.moveRow(-1)
        Keys.onTabPressed: root.cycleFocus(1)
        Keys.onBacktabPressed: root.cycleFocus(-1)
        ColumnLayout {
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
                model: root.historyModel
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                delegate: NotificationHistoryItem {
                    required property var modelData
                    required property int index
                    width: historyList.width
                    entry: modelData
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
