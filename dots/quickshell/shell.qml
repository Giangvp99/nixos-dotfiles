//@ pragma IconTheme Papirus-Dark

import QtQuick
import Quickshell

import "modules/bar" as BarModule
import "modules/launcher" as Launcher
import "modules/bar/popups" as BarPopups
import "modules/notifications" as NotificationsModule
import "services" as Services
import "modules/dashboard" as DashboardModule
import "modules/osd" as OsdModule
import "modules/keybinds" as Keybinds

ShellRoot {
    PersistentProperties {
        id: dashboardMemory
        reloadableId: "dashboard-session"
        property int page: 0
        property bool opened: false
        property string screenName: ""
        onLoaded: dashboard.restoreSession(dashboardMemory)
    }
    PersistentProperties {
        id: notificationMemory
        reloadableId: "notification-history-memory"
        property string historyJson: "[]"
        property string detailsJson: "{}"
        property bool dnd: false
        onLoaded: Services.NotificationState.attachMemory(notificationMemory)
    }

    PersistentProperties {
        id: metricsMemory
        reloadableId: "system-metrics-history"
        property string cpuJson: "[]"
        property string memoryJson: "[]"
        onLoaded: Services.SystemMonitor.attachHistory(metricsMemory)
    }
    PersistentProperties {
        id: focusMemory
        reloadableId: "focus-session"
        property string status: "idle"
        property double deadline: 0
        property int durationSeconds: 1500
        property int remainingSeconds: 1500
        property string modeId: ""
        property bool managesDnd: false
        onLoaded: Qt.callLater(function() { Services.FocusSession.attachMemory(focusMemory) })
    }
    PersistentProperties {
        id: notesMemory
        reloadableId: "quick-notes-draft"
        property bool hasDraft: false
        property bool dirty: false
        property string draft: ""
        onLoaded: Services.NotesService.attachMemory(notesMemory)
    }

    PersistentProperties {
        id: keybindMemory
        reloadableId: "keybinds-session"
        property bool opened: false
        property string screenName: ""
        onLoaded: keybinds.restoreSession(keybindMemory)
    }
    // Interactive overlays hand focus off; the audio OSD stays passive.
    Keybinds.KeybindSheet {
        id: keybinds
        onOpening: {
            launcher.close(false)
            dashboard.close(false)
            if (BarPopups.PopupState.current) BarPopups.PopupState.current.close(false)
        }
    }
    BarModule.Bars { id: bars }

    Launcher.Launcher {
        id: launcher
        onOpening: {
            keybinds.close(false)
            dashboard.close(false)
            if (BarPopups.PopupState.current) BarPopups.PopupState.current.close(false)
        }
    }
    NotificationsModule.NotificationHost {}
    DashboardModule.Dashboard {
        id: dashboard
        onOpening: {
            keybinds.close(false)
            launcher.close(false)
            if (BarPopups.PopupState.current) BarPopups.PopupState.current.close(false)
        }
        onShortcutsRequested: {
            const origin = dashboard.returnFocusItem
            const screen = dashboard.targetScreen
            dashboard.close(false)
            keybinds.open(origin, screen)
        }
        onLauncherRequested: {
            const origin = dashboard.returnFocusItem
            const screen = dashboard.targetScreen
            dashboard.close(false)
            launcher.open(origin, screen)
        }
        onNotificationsRequested: {
            const origin = dashboard.returnFocusItem
            const center = Services.NotificationState.centerForScreen(dashboard.targetScreen)
            dashboard.close(false)
            if (Services.NotificationState.available && center) center.open(origin)
        }
    }
    Connections {
        target: BarPopups.PopupState
        function onCurrentChanged() {
            if (BarPopups.PopupState.current) { launcher.close(false); dashboard.close(false); keybinds.close(false) }
        }
    }
    //LauncherModule.Launcher {}
    //ControlCenterModule.ControlCenter {}
    //NotificationModule.NotificationCenter {}
    OsdModule.AudioOsd { id: audioOsd }
}
