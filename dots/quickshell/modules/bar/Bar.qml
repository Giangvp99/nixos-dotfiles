import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config" as Config
import "./popups" as Popups

PanelWindow {
    id: root
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
                Layout.fillWidth: true
                Layout.minimumWidth: Config.Config.workspaceWidth
            }
            BarCenter {
                Layout.maximumWidth: Math.min(300, root.width * 0.2)
            }
            Flickable {
                // Keep every status control reachable even on narrow VM displays.
                Layout.preferredWidth: Math.min(status.implicitWidth, root.width * 0.65)
                Layout.preferredHeight: Config.Theme.controlHeight
                contentWidth: status.implicitWidth
                contentHeight: height
                clip: true
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds
                BarRight { id: status }
            }
        }
    }
}
