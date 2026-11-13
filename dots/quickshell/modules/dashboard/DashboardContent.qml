import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config" as Config
import "../../components" as Components
import "../../services" as Services

Item {
    id: root
    property var focusSession: Services.FocusSession
    property var notesService: Services.NotesService
    property var mediaService: Services.MediaService
    property var audioService: Services.AudioService
    property var networkService: Services.NetworkService
    property var appService: Services.AppService
    property var modeService: Services.ModeService
    property var hyprlandService: Services.HyprlandService
    property var notificationState: Services.NotificationState
    property var workspace: hyprlandService.focusedWorkspace
    readonly property string workspaceName: workspace ? workspace.name : ""
    readonly property string modeId: modeService.idFromWorkspace(workspaceName)
    readonly property bool overview: width >= Config.Config.dashboardBreakpoint && height >= 700
    readonly property bool wide: overview
    readonly property real topRowHeight: Math.max(260, focusCard.implicitHeight, audioCard.implicitHeight)
    property int page: 0
    readonly property var pageNames: ["Focus", "Sound", "Network", "Notes", "Calendar", "Media"]
    readonly property var apps: Config.Config.dashboardApps.map(id => appService.byId(id)).filter(app => app !== null).slice(0, 3)
    readonly property string greeting: clock.date.getHours() < 12 ? "Good morning" : (clock.date.getHours() < 18 ? "Good afternoon" : "Good evening")
    readonly property alias closeControl: closeButton
    implicitHeight: 748
    signal focusRequested(var item)
    signal layoutUpdated()
    signal closeRequested()
    signal launchRequested(var app)
    signal launcherRequested()
    signal notificationsRequested()
    signal shortcutsRequested()

    function focusTargets() {
        let targets = [closeButton]
        for (let i = 0; i < modes.count; ++i) targets.push(modes.itemAt(i))
        if (!overview) for (let i = 0; i < pages.count; ++i) targets.push(pages.itemAt(i))
        if (focusCard.visible) targets = targets.concat(focusCard.focusTargets())
        if (calendarCard.visible) targets = targets.concat([calendar.firstControl, calendar.lastControl])
        if (audioCard.visible) targets = targets.concat(audioCard.focusTargets())
        if (networkCard.visible) targets = targets.concat(networkCard.focusTargets())
        if (notesCard.visible) targets = targets.concat(notesCard.focusTargets())
        if (mediaCard.visible) targets = targets.concat(mediaCard.focusTargets())
        for (let i = 0; i < shortcuts.count; ++i) targets.push(shortcuts.itemAt(i))
        return targets.concat([allApps, notificationsButton, shortcutHelp, dndButton]).filter(item => item && item.visible && item.enabled)
    }
    function cycleFocus(delta) {
        const targets = focusTargets()
        if (!targets.length) return
        const current = targets.findIndex(item => item.activeFocus)
        const index = current < 0 ? (delta > 0 ? 0 : targets.length - 1) : (current + delta + targets.length) % targets.length
        targets[index].forceActiveFocus()
        focusRequested(targets[index])
    }
    function revealFocus() {
        const targets = focusTargets()
        if (!targets.some(item => item.activeFocus)) closeButton.forceActiveFocus()
    }
    function selectPage(value) {
        page = value
        networkCard.expanded = false
    }
    onOverviewChanged: Qt.callLater(root.revealFocus)
    Keys.onEscapePressed: closeRequested()
    Keys.onTabPressed: cycleFocus(1)
    Keys.onBacktabPressed: cycleFocus(-1)
    component DashboardButton: Components.IconButton {
        border.width: activeFocus || active ? Config.Theme.focusBorderWidth : 0
        focusController: root
    }
    SystemClock { id: clock; precision: SystemClock.Minutes }

    ColumnLayout {
        anchors.fill: parent
        spacing: Config.Theme.spaceLarge
        RowLayout {
            Layout.fillWidth: true
            spacing: Config.Theme.panelPadding
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 260
                spacing: Config.Theme.spaceTiny
                Components.StyledText {
                    text: Qt.formatDateTime(clock.date, Config.Config.clockFormat)
                    font.pixelSize: root.overview ? Config.Theme.fontDisplay : 26
                    font.weight: Config.Theme.emphasisFontWeight
                }
                Components.StyledText {
                    Layout.fillWidth: true
                    text: Qt.formatDateTime(clock.date, "dddd, dd MMMM yyyy")
                    color: Config.Theme.subtext
                    font.pixelSize: Config.Theme.fontSmall
                    elide: Text.ElideRight
                }
            }
            ColumnLayout {
                visible: root.width >= 680
                Layout.fillWidth: true
                Layout.preferredWidth: 420
                spacing: Config.Theme.spaceSmall
                Components.StyledText {
                    Layout.fillWidth: true
                    text: root.greeting + ", " + Config.Config.dashboardName + " · " + (root.modeId ? root.modeService.name(root.modeId) : root.workspaceName || "Desktop")
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    font.pixelSize: Config.Theme.fontLarge
                }
                Components.StyledText {
                    Layout.fillWidth: true
                    text: { const window = root.hyprlandService.activeToplevelFor ? root.hyprlandService.activeToplevelFor(root.workspace) : root.hyprlandService.activeToplevel; return window ? window.title : "No active window" }
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: Config.Theme.subtext
                    font.pixelSize: Config.Theme.fontSmall
                }
            }
            DashboardButton {
                id: closeButton
                objectName: "dashboardClose"
                icon: "󰅖"
                Accessible.name: "Close dashboard"
                onClicked: root.closeRequested()
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Components.StyledText {
                visible: root.width >= 680
                text: "Workspace"
                color: Config.Theme.subtext
                font.pixelSize: Config.Theme.fontSmall
            }
            Repeater {
                id: modes
                model: ["writing", "code", "relax"]
                delegate: DashboardButton {
                    required property string modelData
                    Layout.fillWidth: !root.overview
                    text: root.modeService.name(modelData)
                    objectName: "dashboardMode_" + modelData
                    active: root.modeId === modelData
                    onClicked: root.modeService.activate(modelData)
                }
            }
            Item { visible: root.overview; Layout.fillWidth: true }
            Components.StyledText {
                visible: root.overview
                text: "Personal dashboard"
                color: Config.Theme.subtext
                font.pixelSize: Config.Theme.fontSmall
            }
        }
        GridLayout {
            visible: !root.overview
            Layout.fillWidth: true
            columns: root.width >= 600 ? 6 : 3
            columnSpacing: Config.Theme.spaceSmall
            rowSpacing: Config.Theme.spaceSmall
            Repeater {
                id: pages
                model: root.pageNames
                delegate: DashboardButton {
                    required property int index
                    required property string modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    objectName: "dashboardPage_" + index
                    text: modelData
                    active: root.page === index
                    onClicked: root.selectPage(index)
                }
            }
        }
        GridLayout {
            objectName: "dashboardBody"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            columns: root.overview ? 3 : 1
            columnSpacing: Config.Theme.spaceLarge
            ColumnLayout {
                visible: root.overview || root.page === 0 || root.page === 4
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                spacing: Config.Theme.spaceLarge
                FocusCard {
                    id: focusCard
                    objectName: "dashboardFocus"
                    Layout.minimumHeight: root.overview ? root.topRowHeight : implicitHeight
                    Layout.preferredHeight: root.topRowHeight
                    Layout.maximumHeight: root.overview ? root.topRowHeight : Infinity
                    visible: root.overview || root.page === 0
                    Layout.fillWidth: true
                    contentPadding: Config.Theme.spaceLarge
                    session: root.focusSession
                    notifications: root.notificationState
                    focusController: root
                    onFocusRequested: item => root.focusRequested(item)
                }
                DashboardCard {
                    id: calendarCard
                    objectName: "dashboardCalendarCard"
                    implicitHeight: 254
                    visible: root.overview || root.page === 4
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 230
                    Layout.maximumHeight: root.overview ? 300 : 360
                    contentPadding: Config.Theme.spaceLarge
                    Components.MonthCalendar {
                        id: calendar
                        objectName: "dashboardCalendar"
                        Layout.fillWidth: true
                        Layout.preferredHeight: calendarCard.height - calendarCard.contentPadding * 2
                        focusHandler: root
                        now: clock.date
                        showFooter: false
                    }
                }
                Item { visible: !root.overview; Layout.fillHeight: true }
            }
            ColumnLayout {
                visible: root.overview || root.page === 1 || root.page === 2
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                spacing: Config.Theme.spaceLarge
                AudioCard {
                    id: audioCard
                    Layout.minimumHeight: root.overview ? root.topRowHeight : implicitHeight
                    Layout.preferredHeight: root.topRowHeight
                    Layout.maximumHeight: root.overview ? root.topRowHeight : Infinity
                    visible: root.overview || root.page === 1
                    Layout.fillWidth: true
                    compact: true
                    audioService: root.audioService
                    focusController: root
                    onFocusRequested: item => root.focusRequested(item)
                }
                NetworkCard {
                    id: networkCard
                    visible: root.overview || root.page === 2
                    Layout.fillWidth: true
                    Layout.fillHeight: root.overview
                    compact: true
                    networkService: root.networkService
                    focusController: root
                    settingsAvailable: root.appService.byId("nm-connection-editor") !== null
                    onSettingsRequested: root.launchRequested(root.appService.byId("nm-connection-editor"))
                    onFocusRequested: item => root.focusRequested(item)
                }
                Item { Layout.fillHeight: true; visible: !root.overview }
            }
            ColumnLayout {
                visible: root.overview || root.page === 3 || root.page === 5
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                spacing: Config.Theme.spaceLarge
                NotesCard {
                    id: notesCard
                    objectName: "dashboardNotes"
                    visible: root.overview || root.page === 3
                    Layout.fillWidth: true
                    Layout.fillHeight: !root.overview
                    Layout.minimumHeight: root.overview ? root.topRowHeight : 180
                    Layout.preferredHeight: root.topRowHeight
                    Layout.maximumHeight: root.overview ? root.topRowHeight : Infinity
                    implicitHeight: 260
                    contentPadding: Config.Theme.spaceLarge
                    editorHeight: Math.max(80, height - 90)
                    notes: root.notesService
                    focusController: root
                    onFocusRequested: item => root.focusRequested(item)
                }
                MediaCard {
                    id: mediaCard
                    Layout.fillHeight: root.overview
                    visible: (root.overview || root.page === 5) && root.mediaService.available
                    Layout.fillWidth: true
                    compact: true
                    mediaService: root.mediaService
                    focusController: root
                    onFocusRequested: item => root.focusRequested(item)
                }
                DashboardCard {
                    objectName: "dashboardMediaEmpty"
                    visible: (root.overview || root.page === 5) && !root.mediaService.available
                    Layout.fillWidth: true
                    Layout.fillHeight: root.overview
                    contentPadding: Config.Theme.spaceLarge
                    title: "Now playing"
                    Components.StyledText {
                        text: "󰝚"
                        font.family: Config.Theme.iconFontFamily
                        font.pixelSize: Config.Theme.fontDisplay
                        color: Config.Theme.subtext
                    }
                    Components.StyledText {
                        Layout.fillWidth: true
                        text: "Play music or video to control it here."
                        wrapMode: Text.Wrap
                        color: Config.Theme.subtext
                    }
                }
                Item { visible: !root.overview && root.page === 5; Layout.fillHeight: true }
            }
        }
        Components.Surface {
            objectName: "dashboardQuickAccess"
            Layout.fillWidth: true
            implicitHeight: Config.Theme.controlHeight + Config.Theme.spaceMedium * 2
            RowLayout {
                anchors.fill: parent
                anchors.margins: Config.Theme.spaceMedium
                spacing: Config.Theme.spaceSmall
                Repeater {
                    id: shortcuts
                    model: root.apps
                    delegate: DashboardButton {
                        required property var modelData
                        objectName: "dashboardApp_" + modelData.id
                        implicitWidth: root.overview ? 136 : Config.Theme.controlHeight
                        Accessible.name: modelData.name
                        onClicked: root.launchRequested(modelData)
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Config.Theme.spaceSmall
                            spacing: Config.Theme.spaceMedium
                            Components.AppIcon { appEntry: modelData; iconSize: Config.Theme.controlIconSize }
                            Components.StyledText {
                                visible: root.overview
                                Layout.fillWidth: true
                                text: modelData.name
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
                Item { Layout.fillWidth: true }
                DashboardButton {
                    id: allApps
                    objectName: "dashboardAllApps"
                    icon: "󰀻"
                    text: root.overview ? "Applications" : ""
                    Accessible.name: "All applications"
                    onClicked: root.launcherRequested()
                }
                DashboardButton {
                    id: notificationsButton
                    objectName: "dashboardNotifications"
                    icon: "󰂚"
                    text: root.overview ? "Notifications · " + root.notificationState.unreadCount : ""
                    Accessible.name: "Notifications"
                    enabled: root.notificationState.available
                    onClicked: root.notificationsRequested()
                }
                DashboardButton {
                    id: shortcutHelp
                    objectName: "dashboardShortcuts"
                    icon: "󰌌"
                    text: root.overview ? "Shortcuts" : ""
                    Accessible.name: "Keyboard shortcuts"
                    onClicked: root.shortcutsRequested()
                }
                DashboardButton {
                    id: dndButton
                    objectName: "dashboardDnd"
                    icon: "󰂛"
                    text: root.overview ? "DND" : ""
                    Accessible.name: "Do not disturb " + (root.notificationState.dnd ? "on" : "off")
                    active: root.notificationState.dnd
                    enabled: root.notificationState.available
                    onClicked: root.notificationState.toggleDnd()
                }
            }
        }
    }
}
