import QtQuick
import "../../../config" as Config
import "../../../components" as Components
import "../../../services" as Services
import "../popups" as Popups

Components.FixedStatusButton {
    id: root
    cellWidth: Config.Config.audioStatusWidth
    spacing: Config.Theme.controlSpacing
    objectName: "barAudio"
    property var audioService: Services.AudioService
    readonly property alias detailsPopup: popup
    doubleClickEnabled: true
    active: popup.visible
    Accessible.name: "Volume " + text + ". Click for audio settings; double-click to mute."
    Popups.AudioPopup {
        id: popup
        anchorItem: root
        audioService: root.audioService
    }
    visible: audioService.available
    icon: volumeIcon
    text: audioService.muted ? "Mute" : audioService.volumePercent + "%"
    foreground: audioService.muted ? Config.Theme.subtext : Config.Theme.controlForeground
    wheelEnabled: true
    onClicked: popup.toggle()
    onDoubleClicked: audioService.toggleMute()
    onScrolled: delta => {
        if (delta > 0) audioService.increaseVolume()
        else if (delta < 0) audioService.decreaseVolume()
    }

    readonly property string volumeIcon: {
        if (!audioService.available)
            return "󰖁"

        if (audioService.muted)
            return "󰖁"

        const volume =
            audioService.volume

        if (volume <= 0.0)
            return "󰖁"

        if (volume < 0.34)
            return "󰕿"

        if (volume < 0.67)
            return "󰖀"

        return "󰕾"
    }

}
