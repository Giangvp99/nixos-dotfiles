import QtQuick
import QtQuick.Layouts

import "../../config" as Config
import "./widgets" as Widgets

RowLayout {
    id: root

    required property var hyprMonitor

    spacing:
        Config.Config.barSpacing

    Widgets.ModeIndicator {}

    Widgets.RunningApps {}
}
