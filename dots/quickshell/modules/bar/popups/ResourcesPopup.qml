import QtQuick
import QtQuick.Layouts
import "../../../config" as Config
import "../../../components" as Components
import "../../../services" as Services

DetailsPopup {
    id: root
    title: "CPU & memory"
    property var monitor: Services.SystemMonitor
    preferredWidth: 420
    preferredHeight: 360
    bodyComponent: ColumnLayout {
        spacing: Config.Theme.spaceMedium
        function focusTargets() { return [] }
        RowLayout {
            Layout.fillWidth: true
            Components.StyledText { text: "  CPU"; color: Config.Theme.primary }
            Components.StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: root.monitor.cpuAvailable ? root.monitor.cpuPercent + "%" : "Waiting for CPU sample…"
            }
        }
        Components.HistoryChart {
            objectName: "cpuHistoryChart"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 60
            series: root.monitor.cpuHistory
            windowMs: root.monitor.historyWindowMs
            maximumGap: Math.max(1000, Config.Config.metricsInterval)*3
        }
        RowLayout {
            Layout.fillWidth: true
            Components.StyledText { text: "  RAM"; color: Config.Theme.success }
            Components.StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                font.pixelSize: Config.Theme.fontSmall
                text: root.monitor.memory ? (root.monitor.memory.used/1073741824).toFixed(1) + " / "
                    + (root.monitor.memory.total/1073741824).toFixed(1) + " GiB · " + root.monitor.memoryPercent + "%" : "Waiting for memory sample…"
            }
        }
        Components.HistoryChart {
            objectName: "memoryHistoryChart"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 60
            series: root.monitor.memoryHistory
            lineColor: Config.Theme.success
            windowMs: root.monitor.historyWindowMs
            maximumGap: Math.max(1000, Config.Config.metricsInterval)*3
        }
        RowLayout {
            Layout.fillWidth: true
            Components.StyledText { text: Math.round(root.monitor.historyWindowMs/60000) + " min ago"; color: Config.Theme.subtext; font.pixelSize: Config.Theme.fontSmall }
            Components.StyledText { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: "0–100%"; color: Config.Theme.subtext; font.pixelSize: Config.Theme.fontSmall }
            Components.StyledText { text: "Now"; color: Config.Theme.subtext; font.pixelSize: Config.Theme.fontSmall }
        }
    }
}
