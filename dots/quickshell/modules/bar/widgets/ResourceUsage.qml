import QtQuick
import QtQuick.Layouts
import "../../../config" as Config
import "../../../components" as Components
import "../../../services" as Services
import "../popups" as Popups

Components.FixedStatusButton {
    cellWidth: Config.Config.resourceUsageWidth
    objectName: "resourceUsage"
    property var monitor: Services.SystemMonitor
    visible: Config.Config.showResourceUsage && (monitor.cpuAvailable || monitor.memoryAvailable)
    id: root
    readonly property alias detailsPopup: popup
    active: popup.visible
    onClicked: popup.toggle()
    Popups.ResourcesPopup { id: popup; anchorItem: root; monitor: root.monitor }
    readonly property string cpuText: monitor.cpuAvailable ? monitor.cpuPercent + "%" : "—"
    readonly property string memoryText: monitor.memoryAvailable ? monitor.memoryPercent + "%" : "—"
    horizontalPadding: Config.Theme.controlPadding
    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: root.horizontalPadding
        anchors.rightMargin: root.horizontalPadding
        spacing: 0
        RowLayout {
            visible: root.monitor.cpuAvailable
            Layout.fillWidth: true
            Layout.maximumWidth: parent.width
            Layout.fillHeight: true
            spacing: Config.Theme.spaceTiny
            Components.StyledText {
                objectName: "cpuSymbol"
                text: ""
                Layout.preferredWidth: Config.Theme.fontSmall + 1
                font.family: Config.Theme.iconFontFamily
                font.pixelSize: Config.Theme.fontSmall
                color: root.iconColor
            }
            Components.StyledText {
                Layout.fillWidth: true
                text: root.cpuText
                color: root.foreground
                font.pixelSize: Config.Theme.fontSmall
                horizontalAlignment: Text.AlignRight
            }
        }
        RowLayout {
            visible: root.monitor.memoryAvailable
            Layout.fillWidth: true
            Layout.maximumWidth: parent.width
            Layout.fillHeight: true
            spacing: Config.Theme.spaceTiny
            Components.StyledText {
                objectName: "ramSymbol"
                text: ""
                Layout.preferredWidth: Config.Theme.fontSmall + 1
                font.family: Config.Theme.iconFontFamily
                font.pixelSize: Config.Theme.fontSmall
                color: root.iconColor
            }
            Components.StyledText {
                Layout.fillWidth: true
                text: root.memoryText
                color: root.foreground
                font.pixelSize: Config.Theme.fontSmall
                horizontalAlignment: Text.AlignRight
            }
        }
    }
    foreground: (monitor.cpuAvailable && monitor.cpuPercent >= Config.Config.resourceWarning)
        || (monitor.memoryAvailable && monitor.memoryPercent >= Config.Config.resourceWarning)
        ? Config.Theme.warning : Config.Theme.controlForeground
    textFormat: Text.PlainText
    Accessible.name: [monitor.cpuAvailable ? "CPU " + cpuText : "", monitor.memoryAvailable ? "RAM " + memoryText : ""].filter(value => value.length).join(", ")
}
