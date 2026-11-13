import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../config" as Config
import "./widgets" as Widgets
import "../../services" as Services
import "./popups" as Popups

RowLayout {
    id: root
    property bool compact: false
    spacing: Config.Config.barSpacing
    onXChanged: Qt.callLater(Popups.PopupState.refreshAnchor)
    onWidthChanged: Qt.callLater(Popups.PopupState.refreshAnchor)
    Flickable {
        id: metricsViewport
        objectName: "barMetricsViewport"
        implicitWidth: metrics.implicitWidth
        implicitHeight: Config.Theme.controlHeight
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        contentWidth: Math.max(width, metrics.implicitWidth)
        contentHeight: height
        onContentXChanged: Qt.callLater(Popups.PopupState.refreshAnchor)
        clip: true
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        ScrollIndicator.horizontal: ScrollIndicator {
            id: metricsScrollIndicator
            contentItem: Rectangle {
                visible: metricsScrollIndicator.size<1
                opacity: metricsScrollIndicator.active ? 1 : 0
                implicitWidth: Config.Theme.spaceMedium
                implicitHeight: Config.Theme.spaceTiny
                radius: Config.Theme.spaceTiny / 2
                color: Config.Theme.primary
            }
        }
        MouseArea {
            x: Math.max(0, metricsViewport.width - width)
            width: metrics.implicitWidth
            height: metrics.implicitHeight
            acceptedButtons: Qt.NoButton
            // Child controls (e.g. the audio wheel) handle their own events first.
            onWheel: event => {
                const maximum = Math.max(0, metricsViewport.contentWidth - metricsViewport.width)
                if (!maximum) { event.accepted = false; return }
                const pixels = event.pixelDelta.x || event.pixelDelta.y
                const angle = event.angleDelta.x || event.angleDelta.y
                const step = pixels || angle / 120 * Config.Theme.controlHeight
                metricsViewport.contentX = Math.max(0, Math.min(maximum, metricsViewport.contentX - step))
                event.accepted = true
            }
            RowLayout {
                id: metrics
                spacing: Config.Config.barSpacing
                Widgets.NetworkSpeed {}
                Widgets.ResourceUsage {}
                Widgets.Temperature {}
                Widgets.Wifi { visible: !Config.Config.showNetworkSpeed && Services.NetworkService.available }
                Widgets.Battery {}
                Widgets.Brightness {}
                Widgets.Audio { visible: Config.Config.showAudio && Services.AudioService.available }
            }
        }
    }
    Widgets.Notifications { objectName: "barNotifications" }
    Widgets.Date { objectName: "barDate"; compact: root.compact }
    Widgets.Clock { objectName: "barClock"; visible: Config.Config.showClock }
    Widgets.Keyboard { objectName: "barKeyboard" }
    Widgets.PowerMenu { objectName: "barPowerMenu" }
}
