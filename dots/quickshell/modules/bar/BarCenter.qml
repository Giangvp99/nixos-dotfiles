import QtQuick
import QtQuick.Layouts
import "../../config" as Config
import "./widgets" as Widgets

RowLayout {
    id: root
    property var workspace: null
    visible: Config.Config.showActiveWindow
    Widgets.ActiveWindow { workspace: root.workspace; Layout.fillWidth: true }
}
