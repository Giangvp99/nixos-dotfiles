import QtQuick
import QtQuick.Layouts
import "../config" as Config

StatusText {
    clip: true
    spacing: Config.Theme.spaceTiny
    horizontalPadding: Config.Theme.controlPadding
    property int cellWidth: 100
    implicitWidth: cellWidth
    Layout.minimumWidth: cellWidth
    Layout.preferredWidth: cellWidth
    Layout.maximumWidth: cellWidth
    fillContentWidth: false
}
