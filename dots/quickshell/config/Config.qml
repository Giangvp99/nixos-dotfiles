pragma Singleton

import QtQuick

QtObject {
    readonly property int barHeight: 38
    readonly property int barOuterMargin: 6
    readonly property int barHorizontalPadding: 10

    readonly property int barSpacing: 8

    readonly property int workspaceWidth: 36
    readonly property int workspaceSize: 28
    readonly property int workspaceSpacing: 4

    readonly property bool showActiveWindow: false
    readonly property bool showClock: true
    readonly property bool showAudio: true
    readonly property int batteryWidth: 72
    readonly property int networkMaxWidth: 180

    readonly property int keyboardWidth: 42


    // Desktop-entry IDs; unavailable applications are ignored.
    readonly property var launcherPinnedApps: ["kitty", "org.kde.dolphin", "brave-browser"]
    readonly property int launcherWidth: 560
    readonly property int launcherMaxHeight: 520
    readonly property int launcherSearchHeight: 44
    readonly property int launcherRowHeight: 52
    readonly property int launcherVisibleRows: 7
    readonly property int launcherResultLimit: 64

    // Default off; NotificationHost can opt in the current process via IPC.
    readonly property bool notificationsEnabled: false
    readonly property int notificationHistoryLimit: 100
    readonly property int notificationHistoryBodyLimit: 8192
    readonly property int notificationCenterWidth: 420
    readonly property int notificationCenterHeight: 580
    readonly property int notificationWidth: 380
    readonly property int notificationMaxVisible: 3
    readonly property int notificationQueueLimit: 32
    readonly property int notificationDefaultTimeout: 5000
    readonly property int notificationBodyMaxHeight: 120

    readonly property string dashboardName: "jj"
    readonly property int dashboardWidth: 1000
    readonly property int dashboardMaxHeight: 740
    readonly property int dashboardBreakpoint: 740
    readonly property var dashboardApps: launcherPinnedApps

    readonly property string clockFormat: "HH:mm"
}
