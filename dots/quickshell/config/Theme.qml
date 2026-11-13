pragma Singleton

import QtQuick

QtObject {
    // Dracula: https://draculatheme.com/contribute
    // Raised/deep surfaces and secondary text are UI adaptations of its dark palette.
    readonly property color background: "#282a36"
    readonly property color backgroundDeep: "#21222c"
    readonly property color surface: "#343746"
    readonly property color surfaceHover: "#393c4d"
    readonly property color surfacePressed: backgroundDeep
    readonly property color inputBackground: backgroundDeep

    readonly property color text: "#f8f8f2"
    readonly property color subtext: "#b6bbd2"
    readonly property color comment: "#6272a4"

    readonly property color primary: "#bd93f9"
    readonly property color accent: "#ff79c6"
    readonly property color info: "#8be9fd"
    readonly property color urgent: "#ff5555"
    readonly property color minimized: "#f1fa8c"
    readonly property color success: "#50fa7b"
    readonly property color warning: "#f1fa8c"
    readonly property color orange: "#ffb86c"
    readonly property color border: "#44475a"
    readonly property color onAccent: background
    readonly property string iconFontFamily: fontFamily
    readonly property int controlHeight: 28
    readonly property int spaceTiny: 2
    readonly property int spaceSmall: 4
    readonly property int spaceMedium: 8
    readonly property int spaceLarge: 12
    readonly property int panelPadding: 16

    // Shared compact controls (bar and popup triggers).
    readonly property int controlPadding: 8
    readonly property int controlSpacing: 4
    readonly property int controlIconSize: 16
    readonly property int appIconSize: 18
    readonly property int controlFontWeight: Font.Normal
    readonly property int emphasisFontWeight: Font.DemiBold
    readonly property int focusBorderWidth: 1
    readonly property color controlBackground: surface
    readonly property color controlHovered: surfaceHover
    readonly property color controlPressed: surfacePressed
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

    readonly property color overlay: "#9921222c"
    readonly property int launcherIconSize: 28

    readonly property int notificationIconSize: 32

    readonly property int fontDisplay: 36
    readonly property int dashboardShortcutHeight: 40
    readonly property int mediaArtworkSize: 64
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
