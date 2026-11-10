import QtQuick
import "../../../config" as Config
import "../../../components" as Components
import "../../../services" as Services

ListView {
    id: root
    implicitWidth: contentWidth
    implicitHeight: Config.Theme.controlHeight
    orientation: ListView.Horizontal
    spacing: Config.Theme.spaceSmall
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    model: Services.HyprlandService.visibleToplevels

    delegate: Components.IconButton {
        id: windowItem
        required property var modelData
        readonly property var ipc: modelData ? modelData.lastIpcObject : null
        readonly property var handle: modelData ? (modelData.wayland ?? modelData.handle) : null
        readonly property string appId: ipc && ipc.class ? ipc.class : (handle ? handle.appId : "")
        active: modelData ? Boolean(modelData.activated) : false
        readonly property bool urgent: modelData ? Boolean(modelData.urgent) : false
        readonly property bool minimized: Services.HyprlandService.isMinimized(modelData)
        Accessible.name: modelData ? modelData.title : ""
        horizontalPadding: 0
        onClicked: Services.HyprlandService.activateToplevel(modelData)
        width: Config.Theme.controlHeight
        height: Config.Theme.controlHeight

        Components.AppIcon {
            anchors.centerIn: parent
            appId: windowItem.appId
            iconSize: Config.Theme.appIconSize
            opacity: windowItem.minimized ? Config.Theme.minimizedOpacity : 1
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Config.Theme.indicatorMargin
            width: windowItem.active ? Config.Theme.indicatorActiveWidth : Config.Theme.indicatorWidth
            height: Config.Theme.indicatorHeight
            radius: Config.Theme.indicatorHeight / 2
            visible: windowItem.active || windowItem.urgent || windowItem.minimized
            color: windowItem.urgent ? Config.Theme.urgent : (windowItem.minimized ? Config.Theme.minimized : Config.Theme.primary)
        }
    }
}
