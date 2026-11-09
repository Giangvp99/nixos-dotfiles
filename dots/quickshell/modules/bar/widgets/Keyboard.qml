import QtQuick

import "../../../config" as Config
import "../../../components" as Components
import "../../../services" as Services

Components.StatusText {
    id: root

    implicitWidth:
        Config.Config.keyboardWidth

    icon: ""

    text:
        Services.InputMethodService.language

    foreground:
        Config.Theme.text
}
