pragma Singleton

import QtQuick

QtObject {
    readonly property int instant: 0
    property bool reducedMotion: false
    readonly property int fast: reducedMotion ? 0 : 120
    readonly property int normal: reducedMotion ? 0 : 200
    readonly property int slow: reducedMotion ? 0 : 320

    readonly property int standardEasing: Easing.OutCubic
    readonly property int emphasizedEasing: Easing.OutQuint
}
