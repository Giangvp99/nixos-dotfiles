import QtQuick

import "../config" as Config

Text {
    color: Config.Theme.text

    font.family: Config.Theme.fontFamily
    font.pixelSize: Config.Theme.fontNormal
    font.weight: Config.Theme.controlFontWeight

    verticalAlignment: Text.AlignVCenter
}
