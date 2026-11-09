pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

QtObject {
    id: root

    function lock() {
        /*
         * Dùng loginctl để phát yêu cầu lock session.
         * Nếu bạn đã cấu hình hyprlock/systemd lock handler,
         * locker sẽ được kích hoạt từ đây.
         */
        Quickshell.execDetached([
            "loginctl",
            "lock-session"
        ])
    }

    function logout() {
        Hyprland.dispatch("exit")
    }

    function reboot() {
        Quickshell.execDetached([
            "systemctl",
            "reboot"
        ])
    }

    function shutdown() {
        Quickshell.execDetached([
            "systemctl",
            "poweroff"
        ])
    }
}
