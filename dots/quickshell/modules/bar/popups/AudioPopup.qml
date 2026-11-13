import QtQuick
import "../../../services" as Services
import "../../dashboard" as Dashboard

DetailsPopup {
    id: root
    title: "Audio settings"
    property var audioService: Services.AudioService
    preferredWidth: 400
    preferredHeight: body ? body.implicitHeight + chromeHeight : 350
    bodyComponent: Dashboard.AudioCard {
        compact: true
        title: "Output & microphone"
        audioService: root.audioService
        focusController: root
    }
}
