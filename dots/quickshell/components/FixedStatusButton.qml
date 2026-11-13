import QtQuick
import QtQuick.Layouts
import "../config" as Config

IconButton {
    property int cellWidth: 100
    implicitWidth: cellWidth
    Layout.minimumWidth: cellWidth
    Layout.preferredWidth: cellWidth
    Layout.maximumWidth: cellWidth
    horizontalPadding: Config.Theme.controlPadding
    spacing: Config.Theme.spaceTiny
    clip: true
}
