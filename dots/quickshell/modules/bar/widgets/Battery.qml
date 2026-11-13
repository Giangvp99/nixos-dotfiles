import QtQuick
import "../../../config" as Config
import "../../../components" as Components
import "../../../services" as Services

Components.FixedStatus {
    cellWidth: Config.Config.batteryStatusWidth
    objectName: "batteryStatus"
    id: root
    property var batteryService: Services.BatteryService
    visible: Config.Config.showBatteryStatus && batteryService.available && batteryService.percentageKnown
    readonly property bool lowBattery: batteryService.low
    icon: !batteryService.available ? "󰚥"
        : (batteryService.charging ? "󰂄" : (batteryService.pluggedIn && !batteryService.fullyCharged ? "󰚥" : batteryIcon()))
    text: batteryService.available
        ? (batteryService.percentageKnown ? batteryService.percent + "%" : "—%")
            + (batteryService.pluggedIn ? " AC" : "")
            + (batteryService.pendingCharge ? " ‖" : (batteryService.pendingDischarge ? " …"
                : (batteryService.pluggedIn && batteryService.discharging ? " ↓"
                : (batteryService.statusText === "Unknown" ? " ?" : ""))))
        : "N/A"
    foreground: !batteryService.available ? Config.Theme.subtext
        : (batteryService.critical ? Config.Theme.urgent : (lowBattery ? Config.Theme.warning : Config.Theme.controlForeground))
    iconColor: batteryService.pluggedIn ? Config.Theme.primary : foreground
    textFormat: Text.PlainText
    Accessible.name: batteryService.available
        ? (batteryService.percentageKnown ? batteryService.percent + "%" : "Percentage unavailable")
            + ", " + (batteryService.pluggedIn ? "AC" : "Battery") + ", " + batteryService.statusText
        : "Battery data unavailable"
    function batteryIcon() {
        if (!batteryService.percentageKnown) return "󰂑"
        const icons = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
        return icons[Math.min(9, Math.floor(batteryService.percent / 10))]
    }
}
