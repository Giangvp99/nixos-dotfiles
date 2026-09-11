pragma Singleton

import QtQuick

QtObject {
    readonly property int barHeight: 38
    readonly property int barOuterMargin: 6
    readonly property int barHorizontalPadding: 10

    readonly property int barSpacing: 8

    readonly property int workspaceWidth: 32
    readonly property int workspaceSize: 28
    readonly property int workspaceSpacing: 4

    readonly property bool showActiveWindow: true
    readonly property bool showClock: true
    readonly property bool showAudio: true
    readonly property int batteryWidth: 72

    readonly property string clockFormat: "HH:mm"
}
