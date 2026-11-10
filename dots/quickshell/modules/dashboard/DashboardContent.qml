import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config" as Config
import "../../components" as Components
import "../../services" as Services

Item {
    id: root
    property var audioService: Services.AudioService
    property var networkService: Services.NetworkService
    property var appService: Services.AppService
    property var modeService: Services.ModeService
    property var hyprlandService: Services.HyprlandService
    property var notificationState: Services.NotificationState
    readonly property bool wide: width >= Config.Config.dashboardBreakpoint
    readonly property string workspaceName: hyprlandService.focusedWorkspace ? hyprlandService.focusedWorkspace.name : ""
    readonly property string modeId: modeService.idFromWorkspace(workspaceName)
    readonly property var apps: Config.Config.dashboardApps.map(id => appService.byId(id)).filter(app => app !== null)
    readonly property string greeting: clock.date.getHours() < 12 ? "Good morning" : (clock.date.getHours() < 18 ? "Good afternoon" : "Good evening")
    readonly property alias closeControl: closeButton
    signal focusRequested(var item)
    signal layoutUpdated()
    signal closeRequested()
    signal launchRequested(var app)
    signal launcherRequested()
    signal notificationsRequested()
    implicitHeight: content.implicitHeight

    function focusTargets() {
        let targets = [closeButton]
        for (let i = 0; i < modes.count; ++i) targets.push(modes.itemAt(i))
        targets = targets.concat([muteButton, volumeSlider, wifiButton, networkSettings, calendar.firstControl, calendar.lastControl])
        for (let i = 0; i < shortcuts.count; ++i) targets.push(shortcuts.itemAt(i))
        targets = targets.concat([allApps, notificationsButton, dndButton])
        return targets.filter(item => item && item.visible && item.enabled)
    }
    function cycleFocus(delta) {
        const targets = focusTargets()
        if (!targets.length) return
        const current = targets.findIndex(item => item.activeFocus)
        const index = current < 0 ? (delta > 0 ? 0 : targets.length - 1)
            : (current + delta + targets.length) % targets.length
        const next = targets[index]
        next.forceActiveFocus()
        focusRequested(next)
    }
    function revealFocus() {
        if (!closeButton) return
        const target = focusTargets().find(item => item.activeFocus)
        if (target) focusRequested(target)
    }
    onWidthChanged: layoutUpdated()
    Keys.onEscapePressed: closeRequested()
    Keys.onTabPressed: cycleFocus(1)
    Keys.onBacktabPressed: cycleFocus(-1)
    component DashboardButton: Components.IconButton {
        border.width: activeFocus || active ? Config.Theme.focusBorderWidth : 0
        border.color: Config.Theme.controlSelected
        focusController: root
    }
    SystemClock { id: clock; precision: SystemClock.Minutes }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Config.Theme.panelPadding
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Config.Theme.spaceSmall
                Components.StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    text: root.greeting + ", " + Config.Config.dashboardName
                    color: Config.Theme.subtext
                }
                Components.StyledText {
                    text: Qt.formatDateTime(clock.date, Config.Config.clockFormat)
                    font.pixelSize: Config.Theme.fontDisplay
                    font.weight: Config.Theme.emphasisFontWeight
                }
                Components.StyledText {
                    Layout.fillWidth: true
                    text: Qt.formatDateTime(clock.date, "dddd, dd MMMM yyyy")
                    color: Config.Theme.subtext
                    elide: Text.ElideRight
                }
            }
            DashboardButton {
                id: closeButton
                objectName: "dashboardClose"
                icon: "󰅖"
                Accessible.name: "Close dashboard"
                Layout.alignment: Qt.AlignTop
                onClicked: root.closeRequested()
            }
        }
        GridLayout {
            Layout.fillWidth: true
            columns: root.wide ? 2 : 1
            columnSpacing: Config.Theme.spaceLarge
            rowSpacing: Config.Theme.spaceLarge
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: Config.Theme.spaceLarge
                DashboardCard {
                    title: "Workspace"
                    Layout.fillWidth: true
                    Components.StyledText {
                        Layout.fillWidth: true
                        text: root.modeId ? root.modeService.name(root.modeId) : (root.workspaceName ? "Workspace " + root.workspaceName : "Desktop")
                        font.pixelSize: Config.Theme.fontLarge
                        font.weight: Config.Theme.emphasisFontWeight
                        elide: Text.ElideRight
                    }
                    Components.StyledText {
                        Layout.fillWidth: true
                        textFormat: Text.PlainText
                        text: root.hyprlandService.activeToplevel ? root.hyprlandService.activeToplevel.title : "No active window"
                        color: Config.Theme.subtext
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Config.Theme.spaceMedium
                        Repeater {
                            id: modes
                            model: ["writing", "code", "relax"]
                            delegate: DashboardButton {
                                required property string modelData
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                objectName: "dashboardMode_" + modelData
                                text: root.modeService.name(modelData)
                                active: root.modeId === modelData
                                onClicked: root.modeService.activate(modelData)
                            }
                        }
                    }
                }
                DashboardCard {
                    title: "Audio"
                    Layout.fillWidth: true
                    RowLayout {
                        Layout.fillWidth: true
                        Components.StyledText {
                            Layout.fillWidth: true
                            text: !root.audioService.available ? "No audio output" : (root.audioService.muted ? "Muted" : root.audioService.volumePercent + "%")
                            font.pixelSize: Config.Theme.fontLarge
                        }
                        DashboardButton {
                            id: muteButton
                            objectName: "dashboardMute"
                            icon: root.audioService.muted ? "󰖁" : "󰕾"
                            text: root.audioService.muted ? "Unmute" : "Mute"
                            enabled: root.audioService.available
                            onClicked: root.audioService.toggleMute()
                        }
                    }
                    Components.StyledSlider {
                        id: volumeSlider
                        objectName: "dashboardVolume"
                        Layout.fillWidth: true
                        enabled: root.audioService.available
                        value: root.audioService.available ? root.audioService.volume : 0
                        Accessible.name: "Volume"
                        onMoved: root.audioService.setVolume(value)
                        Keys.onTabPressed: root.cycleFocus(1)
                        Keys.onBacktabPressed: root.cycleFocus(-1)
                    }
                }
                DashboardCard {
                    title: "Network"
                    Layout.fillWidth: true
                    RowLayout {
                        Layout.fillWidth: true
                        Components.StyledText {
                            text: root.networkService.connectionIcon
                            font.family: Config.Theme.iconFontFamily
                            font.pixelSize: Config.Theme.launcherIconSize
                            color: root.networkService.linkConnected ? Config.Theme.primary : Config.Theme.subtext
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Components.StyledText {
                                Layout.fillWidth: true
                                text: root.networkService.connectionLabel
                                elide: Text.ElideRight
                            }
                            Components.StyledText {
                                Layout.fillWidth: true
                                text: root.networkService.connectivityText
                                color: Config.Theme.subtext
                                font.pixelSize: Config.Theme.fontSmall
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        DashboardButton {
                            id: wifiButton
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            objectName: "dashboardWifi"
                            text: root.networkService.available ? (root.networkService.enabled ? "Wi-Fi on" : "Wi-Fi off") : "No Wi-Fi adapter"
                            enabled: root.networkService.available
                            active: root.networkService.available && root.networkService.enabled
                            onClicked: root.networkService.setWifiEnabled(!root.networkService.enabled)
                        }
                        DashboardButton {
                            id: networkSettings
                            objectName: "dashboardNetworkSettings"
                            text: "Settings"
                            enabled: root.appService.byId("nm-connection-editor") !== null
                            onClicked: root.launchRequested(root.appService.byId("nm-connection-editor"))
                        }
                    }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: Config.Theme.spaceLarge
                DashboardCard {
                    Layout.fillWidth: true
                    Components.MonthCalendar {
                        id: calendar
                        objectName: "dashboardCalendar"
                        Layout.fillWidth: true
                        Layout.preferredHeight: Config.Theme.dashboardCalendarHeight
                        focusHandler: root
                        now: clock.date
                        showFooter: false
                    }
                }
                DashboardCard {
                    title: "Quick access"
                    Layout.fillWidth: true
                    GridLayout {
                        Layout.fillWidth: true
                        columns: root.wide ? 3 : 1
                        columnSpacing: Config.Theme.spaceSmall
                        rowSpacing: Config.Theme.spaceSmall
                        Repeater {
                            id: shortcuts
                            model: root.apps
                            delegate: DashboardButton {
                                required property var modelData
                                objectName: "dashboardApp_" + modelData.id
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                implicitHeight: Config.Theme.dashboardShortcutHeight
                                Accessible.name: modelData.name
                                onClicked: root.launchRequested(modelData)
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Config.Theme.controlPadding
                                    anchors.rightMargin: Config.Theme.controlPadding
                                    spacing: Config.Theme.spaceMedium
                                    Components.AppIcon { appEntry: modelData; iconSize: Config.Theme.controlIconSize }
                                    Components.StyledText {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        textFormat: Text.PlainText
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                    Components.StyledText {
                        visible: !root.apps.length
                        text: "No pinned applications"
                        color: Config.Theme.subtext
                    }
                    GridLayout {
                        Layout.fillWidth: true
                        columns: root.wide ? 3 : 1
                        columnSpacing: Config.Theme.spaceSmall
                        rowSpacing: Config.Theme.spaceSmall
                        DashboardButton {
                            id: allApps
                            Layout.fillWidth: true
                            objectName: "dashboardAllApps"
                            text: "All applications"
                            onClicked: root.launcherRequested()
                        }
                        DashboardButton {
                            id: notificationsButton
                            objectName: "dashboardNotifications"
                            Layout.fillWidth: true
                            text: root.notificationState.available ? "Notifications · " + root.notificationState.unreadCount : "Notifications off"
                            enabled: root.notificationState.available
                            onClicked: root.notificationsRequested()
                        }
                        DashboardButton {
                            id: dndButton
                            Layout.fillWidth: !root.wide
                            text: root.wide ? "" : "Do not disturb"
                            objectName: "dashboardDnd"
                            icon: "󰂛"
                            Accessible.name: "Do not disturb"
                            active: root.notificationState.dnd
                            enabled: root.notificationState.available
                            onClicked: root.notificationState.toggleDnd()
                        }
                    }
                }
            }
        }
    }
}
