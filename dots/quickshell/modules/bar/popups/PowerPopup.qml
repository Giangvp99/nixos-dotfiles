import QtQuick
import QtQuick.Layouts

import "../../../config" as Config
import "../../../components" as Components
import "../../../services" as Services

BarPopup {
    id: root

    preferredWidth: 220
    preferredHeight: content.implicitHeight + Config.Theme.popupPadding * 2

    initialFocusItem: lockAction
    function moveActionFocus(delta) {
        const actions = [lockAction, logoutAction, rebootAction, shutdownAction]
        const current = actions.findIndex(action => action.activeFocus)
        const index = current < 0 ? (delta > 0 ? 0 : actions.length - 1)
            : (current + delta + actions.length) % actions.length
        const next = actions[index]
        next.forceActiveFocus()
        scroll.contentY = Math.max(0, Math.min(next.y, scroll.contentHeight - scroll.height))
    }

    function cycleFocus(delta) { moveActionFocus(delta) }

    Connections {
        target: root
        function onVisibleChanged() { if (root.visible) scroll.contentY = 0 }
    }

    Components.Surface {
        id: popupSurface
        panel: true
        focus: true
        Keys.onDownPressed: root.moveActionFocus(1)
        Keys.onUpPressed: root.moveActionFocus(-1)
        Keys.onTabPressed: root.moveActionFocus(1)
        Keys.onBacktabPressed: root.moveActionFocus(-1)
        Keys.onEscapePressed: root.close(true)
        anchors.fill: parent

        Flickable {
            id: scroll
            anchors.fill: parent
            anchors.margins: Config.Theme.popupPadding
            contentWidth: width
            contentHeight: content.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: content
                width: scroll.width

                spacing: Config.Theme.controlSpacing

                Components.StyledText {
                    Layout.fillWidth: true

                    text: "Session"
                    Layout.preferredHeight: Config.Theme.popupHeaderHeight

                    font.weight: Config.Theme.emphasisFontWeight

                    font.pixelSize:
                        Config.Theme.fontLarge
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Config.Theme.separatorWidth

                    color:
                        Config.Theme.border
                }

                PowerItem {
                    id: lockAction
                    icon: "󰌾"
                    label: "Lock"

                    onTriggered: {
                        root.close(false)
                        Services.PowerService.lock()
                    }
                }

                PowerItem {
                    id: logoutAction
                    icon: "󰍃"
                    label: "Logout"

                    onTriggered: {
                        root.close(false)
                        Services.PowerService.logout()
                    }
                }

                PowerItem {
                    id: rebootAction
                    icon: "󰜉"
                    label: "Reboot"

                    onTriggered: {
                        root.close(false)
                        Services.PowerService.reboot()
                    }
                }

                PowerItem {
                    id: shutdownAction
                    icon: "󰐥"
                    label: "Shutdown"
                    dangerous: true

                    onTriggered: {
                        root.close(false)
                        Services.PowerService.shutdown()
                    }
                }
            }
        }
    }

    component PowerItem: Components.IconButton {
        id: item
        focusController: root
        property alias label: item.text
        property bool dangerous: false
        signal triggered()
        Layout.fillWidth: true
        implicitHeight: Config.Theme.popupActionHeight
        fillContentWidth: true
        background: "transparent"
        foreground: dangerous ? Config.Theme.urgent : Config.Theme.text
        iconColor: foreground
        onClicked: triggered()
    }
}
