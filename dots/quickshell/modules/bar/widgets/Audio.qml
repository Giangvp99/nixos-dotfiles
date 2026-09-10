import QtQuick
import QtQuick.Layouts

import "../../../config" as Config
import "../../../components" as Components
import "../../../services" as Services

Components.Surface {
    id: root

    visible:
        Services.AudioService.available

    implicitWidth:
        content.implicitWidth + 16

    implicitHeight: 28

    color:
        mouseArea.containsMouse
        ? Config.Theme.surfaceHover
        : Config.Theme.surface

    RowLayout {
        id: content

        anchors.centerIn: parent

        spacing: 6

        Components.StyledText {
            text: root.volumeIcon

            color:
                Services.AudioService.muted
                ? Config.Theme.subtext
                : Config.Theme.text

            font.pixelSize:
                Config.Theme.fontLarge
        }

        Components.StyledText {
            text:
                Services.AudioService.muted
                ? "Mute"
                : Services.AudioService.volumePercent + "%"

            color:
                Services.AudioService.muted
                ? Config.Theme.subtext
                : Config.Theme.text
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent

        hoverEnabled: true

        cursorShape: Qt.PointingHandCursor

        onClicked:
            Services.AudioService.toggleMute()

        onWheel: event => {
            if (event.angleDelta.y > 0)
                Services.AudioService.increaseVolume()
            else if (event.angleDelta.y < 0)
                Services.AudioService.decreaseVolume()
        }
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

    Behavior on color {
        ColorAnimation {
            duration:
                Config.Animations.fast
        }
    }
}
