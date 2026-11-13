pragma Singleton
import QtQuick
import Quickshell.Services.UPower
import "../config" as Config

QtObject {
    id: root
    property var backend: UPower
    readonly property var battery: backend.displayDevice
    readonly property bool available: !!battery && battery.ready
        && ((battery.type === UPowerDeviceType.Battery && battery.isPresent)
            || battery.type === UPowerDeviceType.Ups)
    // Quickshell normalizes UPower's percentage to a fraction, including values below 1%.
    readonly property real rawPercentage: available ? battery.percentage : 0
    readonly property bool percentageKnown: available && Number.isFinite(rawPercentage)
        && rawPercentage >= 0 && rawPercentage <= 1
    readonly property int percent: percentageKnown ? Math.round(rawPercentage * 100) : 0
    readonly property bool charging: available && battery.state === UPowerDeviceState.Charging
    readonly property bool discharging: available && battery.state === UPowerDeviceState.Discharging
    readonly property bool fullyCharged: available && battery.state === UPowerDeviceState.FullyCharged
    readonly property bool pendingCharge: available && battery.state === UPowerDeviceState.PendingCharge
    readonly property bool pendingDischarge: available && battery.state === UPowerDeviceState.PendingDischarge
    readonly property bool usingBattery: root.available && root.backend.onBattery
    // Keep the existing API while sharing the canonical source binding internally.
    readonly property alias onBattery: root.usingBattery
    readonly property bool pluggedIn: available && !usingBattery
    readonly property bool low: percentageKnown && (usingBattery || discharging) && percent <= Config.Config.batteryLow
    readonly property bool critical: percentageKnown && (usingBattery || discharging) && percent <= Config.Config.batteryCritical
    readonly property string statusText: {
        if (!available) return "Unavailable"
        if (charging) return "Charging"
        if (fullyCharged) return "Full"
        if (pendingCharge) return "Charge paused"
        if (pendingDischarge) return "Pending discharge"
        if (discharging) return "Discharging"
        if (battery.state === UPowerDeviceState.Empty) return "Empty"
        return "Unknown"
    }
    readonly property real timeToEmpty: available ? battery.timeToEmpty : 0
    readonly property real timeToFull: available ? battery.timeToFull : 0
}
