//@ pragma IconTheme Papirus-Dark

import QtQuick
import Quickshell

import "modules/bar" as BarModule
import "modules/launcher" as Launcher
import "modules/bar/popups" as BarPopups
import "modules/notifications" as NotificationsModule
import "services" as Services
import "modules/dashboard" as DashboardModule

ShellRoot {
    PersistentProperties {
        id: dashboardMemory
        reloadableId: "dashboard-session"
        property bool opened: false
        onLoaded: dashboard.restoreSession(dashboardMemory)
    }
    PersistentProperties {
        id: notificationMemory
        reloadableId: "notification-history-memory"
        property string historyJson: "[]"
        property bool dnd: false
        onLoaded: Services.NotificationState.attachMemory(notificationMemory)
    }

    BarModule.Bar {}

    Launcher.Launcher {
        id: launcher
        onOpening: {
            dashboard.close(false)
            if (BarPopups.PopupState.current) BarPopups.PopupState.current.close(false)
        }
    }
    NotificationsModule.NotificationHost {}
    DashboardModule.Dashboard {
        id: dashboard
        onOpening: {
            launcher.close(false)
            if (BarPopups.PopupState.current) BarPopups.PopupState.current.close(false)
        }
        onLauncherRequested: {
            const origin = dashboard.returnFocusItem
            dashboard.close(false)
            launcher.open(origin)
        }
        onNotificationsRequested: {
            const origin = dashboard.returnFocusItem
            dashboard.close(false)
            if (Services.NotificationState.available && Services.NotificationState.center)
                Services.NotificationState.center.open(origin)
        }
    }
    Connections {
        target: BarPopups.PopupState
        function onCurrentChanged() {
            if (BarPopups.PopupState.current) { launcher.close(false); dashboard.close(false) }
        }
    }
    //LauncherModule.Launcher {}
    //ControlCenterModule.ControlCenter {}
    //NotificationModule.NotificationCenter {}
    //OsdModule.Osd {}
}
