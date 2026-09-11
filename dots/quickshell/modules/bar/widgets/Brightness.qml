import QtQuick

import "../../../components" as Components
import "../../../services" as Services

Components.StatusText {
    id: root

    visible:
        Services.BrightnessService.available

    icon:
        brightnessIcon(
            Services.BrightnessService.percent
        )

    text:
        Services.BrightnessService.percent
        + "%"

    function brightnessIcon(percent) {
        if (percent <= 20)
            return "󰃞"

        if (percent <= 40)
            return "󰃟"

        if (percent <= 70)
            return "󰃝"

        return "󰃠"
    }
}
