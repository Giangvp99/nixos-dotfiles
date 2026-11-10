import QtQuick
import QtQuick.Layouts
import "../../config" as Config
import "./widgets" as Widgets

RowLayout {
    spacing: Config.Config.barSpacing
    Widgets.Dashboard {}
    Widgets.ModeIndicator {}
    Widgets.RunningApps { Layout.fillWidth: true }
}
