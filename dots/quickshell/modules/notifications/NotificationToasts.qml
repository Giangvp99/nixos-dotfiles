import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config" as Config
import "../../services" as Services

Scope {
    id: root
    readonly property alias panel: window
    readonly property var records: Services.NotificationService.visibleRecords
    readonly property ScriptModel toastModel: ScriptModel { values: root.records }

    PanelWindow {
        id: window
        visible: root.records.length > 0
        anchors { top: true; right: true }
        margins.top: Config.Config.barHeight + Config.Config.barOuterMargin * 2 + Config.Theme.spaceLarge
        margins.right: Config.Theme.spaceLarge
        implicitWidth: Math.min(Config.Config.notificationWidth,
            screen ? Math.max(1, screen.width - Config.Theme.spaceLarge * 2) : Config.Config.notificationWidth)
        implicitHeight: Math.min(stack.implicitHeight,
            screen ? Math.max(1, screen.height - margins.top - Config.Theme.spaceLarge) : stack.implicitHeight)
        focusable: false
        aboveWindows: true
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        Flickable {
            anchors.fill: parent
            contentWidth: width
            contentHeight: stack.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ColumnLayout {
                id: stack
                width: parent.width
                spacing: Config.Theme.spaceMedium
                Repeater {
                    model: root.toastModel
                    delegate: ToastCard {
                        required property var modelData
                        record: modelData
                        Layout.fillWidth: true
                        Component.onDestruction: if (record) record.paused = false
                        onHoveredChanged: if (record) record.paused = hovered
                        onDismissRequested: Services.NotificationService.dismiss(record)
                        onActionRequested: identifier => Services.NotificationService.invoke(record, identifier)
                    }
                }
            }
        }
    }
}
