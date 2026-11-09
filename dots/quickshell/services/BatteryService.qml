pragma Singleton

import QtQuick
import Quickshell.Services.UPower

QtObject {
    id: root

    readonly property var battery:
        UPower.displayDevice

    readonly property bool available:
        battery
        && battery.ready
        && battery.isPresent

    /*
     * Quickshell hiện có thể trả:
     *
     *   0.87
     *
     * thay vì:
     *
     *   87
     *
     * nên normalize defensively.
     */
    readonly property real rawPercentage:
        available
        ? battery.percentage
        : 0.0

    readonly property int percent: {
        if (!available)
            return 0

        const value =
            rawPercentage

        return Math.round(
            value <= 1.0
            ? value * 100
            : value
        )
    }

    /*
     * UPower.onBattery:
     *
     * true  = đang chạy bằng pin
     * false = đang có nguồn ngoài
     */
    readonly property bool pluggedIn:
        available
        && !UPower.onBattery

    readonly property bool onBattery:
        available
        && UPower.onBattery

    readonly property bool charging:
        available
        && battery.state
            === UPowerDeviceState.Charging

    readonly property bool discharging:
        available
        && battery.state
            === UPowerDeviceState.Discharging

    readonly property bool fullyCharged:
        available
        && battery.state
            === UPowerDeviceState.FullyCharged

    readonly property bool pendingCharge:
        available
        && battery.state
            === UPowerDeviceState.PendingCharge

    readonly property string statusText: {
        if (!available)
            return ""

        if (fullyCharged)
            return "Full"

        if (charging)
            return "Charging"

        if (pendingCharge)
            return "Plugged"

        /*
         * Có AC nhưng battery state không phải Charging.
         * Trường hợp charge threshold / charger / firmware.
         */
        if (pluggedIn)
            return "Plugged"

        return "Battery"
    }

    readonly property real timeToEmpty:
        available
        ? battery.timeToEmpty
        : 0

    readonly property real timeToFull:
        available
        ? battery.timeToFull
        : 0
}
