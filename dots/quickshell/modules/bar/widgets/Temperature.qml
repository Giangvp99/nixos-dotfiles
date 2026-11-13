import QtQuick
import "../../../config" as Config
import "../../../components" as Components
import "../../../services" as Services

Components.FixedStatus {
    cellWidth: Config.Config.temperatureWidth
    objectName: "temperatureStatus"
    property var monitor: Services.SystemMonitor
    visible: Config.Config.showTemperature && monitor.temperatureAvailable
    icon: "󰔏"
    text: monitor.temperatureAvailable ? Math.round(monitor.temperature) + "°C" : "N/A"
    foreground: !monitor.temperatureAvailable ? Config.Theme.subtext
        : (monitor.temperature >= Config.Config.temperatureCritical ? Config.Theme.urgent
        : (monitor.temperature >= Config.Config.temperatureWarning ? Config.Theme.warning : Config.Theme.controlForeground))
    iconColor: foreground
    Accessible.name: monitor.temperatureAvailable ? "Temperature " + text + ", " + monitor.temperatureSources : "Temperature sensor unavailable"
}
