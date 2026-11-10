import QtQuick
import "../../../config" as Config
import "../../../components" as Components
import "../../../services" as Services

Components.IconButton {
    id: root
    visible: Services.AudioService.available
    icon: volumeIcon
    text: Services.AudioService.muted ? "Mute" : Services.AudioService.volumePercent + "%"
    foreground: Services.AudioService.muted ? Config.Theme.subtext : Config.Theme.controlForeground
    wheelEnabled: true
    onClicked: Services.AudioService.toggleMute()
    onScrolled: delta => {
        if (delta > 0) Services.AudioService.increaseVolume()
        else if (delta < 0) Services.AudioService.decreaseVolume()
    }

    readonly property string volumeIcon: {
        if (!Services.AudioService.available)
            return "󰖁"

        if (Services.AudioService.muted)
            return "󰖁"

        const volume =
            Services.AudioService.volume

        if (volume <= 0.0)
            return "󰖁"

        if (volume < 0.34)
            return "󰕿"

        if (volume < 0.67)
            return "󰖀"

        return "󰕾"
    }

}
