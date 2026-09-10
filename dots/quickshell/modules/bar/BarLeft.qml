import QtQuick
import QtQuick.Layouts

import "../../config" as Config
import "./widgets" as Widgets

RowLayout {
    spacing:
        Config.Config.barSpacing

    Widgets.CurrentWorkspace {}

    Widgets.RunningApps {}
}
