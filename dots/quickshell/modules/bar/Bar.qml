import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config" as Config
import "./popups" as Popups
import "../../services" as Services

PanelWindow {
    id: root
    readonly property var monitor: Services.ScreenService.monitorFor(screen)
    readonly property var workspace: monitor ? monitor.activeWorkspace : null
    anchors { top: true; left: true; right: true }
    implicitHeight: Config.Config.barHeight + Config.Config.barOuterMargin * 2
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        anchors.margins: Config.Config.barOuterMargin
        radius: Config.Theme.radiusMedium
        color: Config.Theme.background
        border.width: 1
        border.color: Config.Theme.surface

        TapHandler {
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            gesturePolicy: TapHandler.DragThreshold
            onTapped: eventPoint => Popups.PopupState.dismissBarTap(parent, eventPoint.position)
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Config.Config.barHorizontalPadding
            anchors.rightMargin: Config.Config.barHorizontalPadding
            spacing: Config.Config.barSpacing

            BarLeft {
                workspace: root.workspace
                monitor: root.monitor
                Layout.fillWidth: true
                Layout.minimumWidth: Config.Config.workspaceWidth
            }
            BarCenter {
                workspace: root.workspace
                Layout.maximumWidth: Math.min(300, root.width * 0.2)
            }
            BarRight {
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignRight
                compact: root.width < 900
                Layout.preferredWidth: Math.min(implicitWidth, root.width * 0.78)
                Layout.maximumWidth: root.width * 0.78
                Layout.minimumWidth: 0
            }
        }
    }
}
