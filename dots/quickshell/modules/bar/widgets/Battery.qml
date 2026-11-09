import QtQuick

import "../../../config" as Config
import "../../../components" as Components
import "../../../services" as Services

Components.StatusText {
    id: root

    visible:
        Services.BatteryService.available

    /*
     * Vì giờ có thêm status nên widget cần rộng hơn.
     */
    implicitWidth:
        Config.Config.batteryWidth

    icon:
        batteryIcon()

    text:
        Services.BatteryService.percent
        + "% "
        + Services.BatteryService.statusText

    foreground:
        lowBattery
        ? Config.Theme.urgent
        : Config.Theme.text

    iconColor:
        Services.BatteryService.pluggedIn
        ? Config.Theme.primary
        : (
            lowBattery
            ? Config.Theme.urgent
            : Config.Theme.text
        )

    readonly property bool lowBattery:
        Services.BatteryService.onBattery
        && Services.BatteryService.percent <= 15

    function batteryIcon() {
        const percent =
            Services.BatteryService.percent

        /*
         * Có nguồn ngoài.
         */
        if (Services.BatteryService.pluggedIn) {
            if (Services.BatteryService.fullyCharged)
                return "󰂄"

            return "󰂄"
        }

        /*
         * Đang chạy pin.
         */
        if (percent >= 90)
            return "󰁹"

        if (percent >= 80)
            return "󰂂"

        if (percent >= 70)
            return "󰂁"

        if (percent >= 60)
            return "󰂀"

        if (percent >= 50)
            return "󰁿"

        if (percent >= 40)
            return "󰁾"

        if (percent >= 30)
            return "󰁽"

        if (percent >= 20)
            return "󰁼"

        if (percent >= 10)
            return "󰁻"

        return "󰁺"
    }
}
