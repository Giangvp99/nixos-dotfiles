//@ pragma IconTheme Papirus-Dark

import Quickshell

import "modules/bar" as BarModule
import "modules/launcher" as Launcher

ShellRoot {
    BarModule.Bar {}

    Launcher.Launcher {}
    //LauncherModule.Launcher {}
    //ControlCenterModule.ControlCenter {}
    //NotificationModule.NotificationCenter {}
    //OsdModule.Osd {}
}
