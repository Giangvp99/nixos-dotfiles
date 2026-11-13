import QtQuick

import "../../../config" as Config
import "../../../components" as Components
import "../../../services" as Services

Components.StatusText {
    id: root
    visible: Services.InputMethodService.language !== "--"

    implicitWidth:
        Config.Config.keyboardWidth

    icon: ""

    text:
        Services.InputMethodService.language

}
