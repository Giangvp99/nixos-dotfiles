import QtQuick
import QtQuick.Layouts
import "../../config" as Config
import "./widgets" as Widgets

RowLayout {
    id: root
    property var workspace: null
    property var monitor: null
    spacing: Config.Config.barSpacing
    Widgets.Dashboard {}
    Widgets.ModeIndicator { workspace: root.workspace }
    Widgets.RunningApps { workspace: root.workspace; monitor: root.monitor; Layout.fillWidth: true }
}
