import QtQuick
import QtQuick.Layouts
import "../../components" as Components
import "../../config" as Config

RowLayout {
    id: root
    objectName: "choicePager"
    property int count: 0
    property int pageSize: 2
    property int page: 0
    property var focusController: null
    readonly property int pageCount: Math.max(1, Math.ceil(count / Math.max(1, pageSize)))
    readonly property int start: page * Math.max(1, pageSize)
    visible: pageCount > 1
    signal focusRequested(var item)
    function focusTargets() { return visible ? [previous, next] : [] }
    onPageCountChanged: page = Math.min(page, pageCount - 1)
    Components.IconButton {
        id: previous
        icon: "󰅁"
        Accessible.name: "Previous choices"
        focusController: root.focusController
        onClicked: root.page = (root.page + root.pageCount - 1) % root.pageCount
        onActiveFocusChanged: if (activeFocus) root.focusRequested(this)
    }
    Components.StyledText {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: (root.page + 1) + " / " + root.pageCount
        color: Config.Theme.subtext
        font.pixelSize: Config.Theme.fontSmall
    }
    Components.IconButton {
        id: next
        icon: "󰅂"
        Accessible.name: "Next choices"
        focusController: root.focusController
        onClicked: root.page = (root.page + 1) % root.pageCount
        onActiveFocusChanged: if (activeFocus) root.focusRequested(this)
    }
}
