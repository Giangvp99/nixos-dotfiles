pragma Singleton

import QtQuick

QtObject {
    readonly property int instant: 0
    readonly property int fast: 120
    readonly property int normal: 200
    readonly property int slow: 320

    readonly property int standardEasing: Easing.OutCubic
    readonly property int emphasizedEasing: Easing.OutQuint
}
