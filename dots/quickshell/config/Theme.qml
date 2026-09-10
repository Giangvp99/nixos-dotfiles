pragma Singleton

import QtQuick

QtObject {
    // Base
    readonly property color background: "#1e1e2e"
    readonly property color surface: "#313244"
    readonly property color surfaceHover: "#45475a"

    // Text
    readonly property color text: "#cdd6f4"
    readonly property color subtext: "#a6adc8"

    // Semantic
    readonly property color primary: "#89b4fa"
    readonly property color urgent: "#f38ba8"
    readonly property color minimized: "#f9e2af"

    // Geometry
    readonly property int radiusSmall: 6
    readonly property int radiusMedium: 10
    readonly property int radiusLarge: 16

    // Typography
    readonly property string fontFamily: "JetBrainsMono Nerd Font"

    readonly property int fontSmall: 11
    readonly property int fontNormal: 13
    readonly property int fontLarge: 15
}
