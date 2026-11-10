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

    readonly property color border: "#45475a"
    readonly property color success: "#a6e3a1"
    readonly property color warning: "#f9e2af"
    readonly property string iconFontFamily: fontFamily
    readonly property int controlHeight: 28
    readonly property int spaceSmall: 4
    readonly property int spaceMedium: 8
    readonly property int spaceLarge: 12
    readonly property int panelPadding: 16

    // Shared compact controls (bar and popup triggers).
    readonly property int controlPadding: 10
    readonly property int controlSpacing: 6
    readonly property int controlIconSize: 16
    readonly property int appIconSize: 18
    readonly property int controlFontWeight: Font.Normal
    readonly property int emphasisFontWeight: Font.DemiBold
    readonly property int focusBorderWidth: 1
    readonly property color controlBackground: surface
    readonly property color controlHovered: surfaceHover
    readonly property color controlPressed: border
    readonly property color controlForeground: text
    readonly property color controlIcon: subtext
    readonly property color controlSelected: primary
    readonly property int indicatorActiveWidth: 14
    readonly property int indicatorWidth: 4
    readonly property int indicatorHeight: 2
    readonly property int indicatorMargin: 1
    readonly property real minimizedOpacity: 0.45
    readonly property real disabledOpacity: 0.45

    readonly property int popupPadding: 12
    readonly property int popupHeaderHeight: 32
    readonly property int popupActionHeight: 42
    readonly property int separatorWidth: 1

    readonly property color overlay: "#66000000"
    readonly property int launcherIconSize: 28

    readonly property int notificationIconSize: 32

    readonly property int fontDisplay: 36
    readonly property int dashboardShortcutHeight: 40
    readonly property int dashboardCalendarHeight: 230

    // Geometry
    readonly property int radiusSmall: 6
    readonly property int radiusMedium: 10
    readonly property int radiusLarge: 16

    // Typography
    readonly property string fontFamily: "FiraCode Nerd Font"

    readonly property int fontSmall: 11
    readonly property int fontNormal: 13
    readonly property int fontLarge: 15
}
