import QtQuick

import "../config" as Config

Text {
    color: Config.Theme.text

    font.family: Config.Theme.fontFamily
    font.pixelSize: Config.Theme.fontNormal

    verticalAlignment: Text.AlignVCenter
}
