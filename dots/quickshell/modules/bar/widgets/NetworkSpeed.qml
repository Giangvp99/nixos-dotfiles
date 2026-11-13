import QtQuick
import "../../../config" as Config
import "../../../components" as Components
import "../../../services" as Services
import "../popups" as Popups
import "../../../utils/SystemMetrics.js" as Metrics

Components.FixedStatusButton {
    cellWidth: Config.Config.networkSpeedWidth
    objectName: "networkSpeed"
    property var monitor: Services.SystemMonitor
    visible: Config.Config.showNetworkSpeed && monitor.networkAvailable
    id: root
    property var networkService: Services.NetworkService
    readonly property alias detailsPopup: popup
    readonly property string connectionKind: networkService.connectionKind(monitor.networkInterface)
    readonly property string connectionIcon: networkService.iconForInterface(monitor.networkInterface)
    active: popup.visible
    onClicked: popup.toggle()
    Popups.NetworkPopup {
        id: popup
        anchorItem: root
        monitor: root.monitor
        networkService: root.networkService
    }
    readonly property string downloadText: monitor.networkAvailable ? Metrics.compactRate(monitor.download) : "—"
    readonly property string uploadText: monitor.networkAvailable ? Metrics.compactRate(monitor.upload) : "—"
    horizontalPadding: Config.Theme.controlPadding
    // Draw direction icons as vectors: small font arrows can lose their heads/stems.
    component DirectionArrow: Canvas {
        id: arrow
        property bool upload: false
        property color ink: upload ? Config.Theme.success : Config.Theme.info
        width: 10
        height: 12
        onAvailableChanged: if (available) requestPaint()
        onInkChanged: requestPaint()
        onUploadChanged: requestPaint()
        onPaint: {
            const ctx=getContext("2d")
            ctx.reset()
            ctx.clearRect(0,0,width,height)
            ctx.strokeStyle=ink
            ctx.lineWidth=1.6
            ctx.lineCap="round"
            ctx.lineJoin="round"
            const tip=upload ? 2 : 10, tail=upload ? 10 : 2
            const wing=upload ? 5 : 7
            ctx.beginPath()
            ctx.moveTo(5,tail); ctx.lineTo(5,tip)
            ctx.moveTo(2,wing); ctx.lineTo(5,tip); ctx.lineTo(8,wing)
            ctx.stroke()
        }
    }
    Item {
        anchors.fill: parent
        anchors.leftMargin: root.horizontalPadding
        anchors.rightMargin: root.horizontalPadding
        Components.StyledText {
            id: linkIcon
            objectName: "networkConnectionIcon"
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Config.Theme.controlIconSize
            text: root.connectionIcon
            color: root.iconColor
            font.family: Config.Theme.iconFontFamily
            font.pixelSize: Config.Theme.controlIconSize
        }
        Column {
            anchors.left: linkIcon.right
            anchors.leftMargin: Config.Theme.controlSpacing
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            spacing: 0
            Item {
                width: parent.width
                height: parent.height / 2
                DirectionArrow {
                    id: downloadArrow
                    objectName: "networkDownloadArrow"
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }
                Components.StyledText {
                    objectName: "networkDownloadValue"
                    anchors.left: downloadArrow.right
                    anchors.leftMargin: Config.Theme.spaceTiny
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    text: root.downloadText
                    color: root.foreground
                    font.pixelSize: Config.Theme.fontSmall
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                }
            }
            Item {
                width: parent.width
                height: parent.height / 2
                DirectionArrow {
                    id: uploadArrow
                    objectName: "networkUploadArrow"
                    upload: true
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }
                Components.StyledText {
                    objectName: "networkUploadValue"
                    anchors.left: uploadArrow.right
                    anchors.leftMargin: Config.Theme.spaceTiny
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    text: root.uploadText
                    color: root.foreground
                    font.pixelSize: Config.Theme.fontSmall
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                }
            }
        }
    }
    foreground: monitor.networkAvailable ? Config.Theme.controlForeground : Config.Theme.subtext
    textFormat: Text.PlainText
    Accessible.name: connectionKind.toUpperCase() + " " + (monitor.networkInterface || "unavailable") + ": download "
        + (monitor.networkAvailable ? Metrics.rate(monitor.download) : "unavailable") + ", upload "
        + (monitor.networkAvailable ? Metrics.rate(monitor.upload) : "unavailable")
}
