import QtQuick
import QtQuick.Layouts
import "../../../config" as Config
import "../../../components" as Components
import "../../../services" as Services
import "../../dashboard" as Dashboard

DetailsPopup {
    id: root
    title: "Network details"
    property var monitor: Services.SystemMonitor
    property var networkService: Services.NetworkService
    property var appService: Services.AppService
    property var detailsReader: reader
    preferredWidth: 440
    preferredHeight: body ? body.implicitHeight + chromeHeight : 450
    Services.NetworkDetails {
        id: reader
        interfaceName: root.monitor.networkInterface
        active: root.visible && root.detailsReader===reader
    }
    bodyComponent: ColumnLayout {
        spacing: Config.Theme.spaceMedium
        function focusTargets() { return [refresh].concat(network.focusTargets()) }
        component Detail: RowLayout {
            property string label: ""
            property string value: ""
            Layout.fillWidth: true
            Components.StyledText {
                Layout.preferredWidth: 78
                text: parent.label
                color: Config.Theme.subtext
                font.pixelSize: Config.Theme.fontSmall
            }
            Components.StyledText {
                Layout.fillWidth: true
                text: parent.value || "—"
                textFormat: Text.PlainText
                font.pixelSize: Config.Theme.fontSmall
                elide: Text.ElideRight
            }
        }
        Components.Surface {
            Layout.fillWidth: true
            implicitHeight: info.implicitHeight + Config.Theme.popupPadding * 2
            ColumnLayout {
                id: info
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Config.Theme.popupPadding
                spacing: Config.Theme.spaceSmall
                Detail { label: "Interface"; value: root.monitor.networkInterface }
                Detail { label: "Type"; value: root.detailsReader.details["GENERAL.TYPE"] || root.networkService.connectionKind(root.monitor.networkInterface) }
                Detail { label: "Profile"; value: root.detailsReader.details["GENERAL.CONNECTION"] || "" }
                Detail { label: "IPv4"; value: root.detailsReader.details["IP4.ADDRESS"] || "" }
                Detail { label: "Gateway"; value: root.detailsReader.details["IP4.GATEWAY"] || "" }
                Detail { label: "DNS"; value: root.detailsReader.details["IP4.DNS"] || "" }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Components.StyledText {
                Layout.fillWidth: true
                text: root.detailsReader.busy ? "Reading connection…" : root.detailsReader.error || "Connection details"
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.pixelSize: Config.Theme.fontSmall
                color: Config.Theme.subtext
            }
            Components.IconButton {
                id: refresh
                objectName: "networkRefresh"
                icon: "󰑓"
                Accessible.name: "Refresh connection details"
                enabled: !root.detailsReader.busy
                focusController: root
                onClicked: root.detailsReader.refresh()
            }
        }
        Dashboard.NetworkCard {
            id: network
            Layout.fillWidth: true
            compact: true
            networkService: root.networkService
            focusController: root
            settingsAvailable: root.appService.byId("nm-connection-editor")!==null
            onSettingsRequested: {
                const entry=root.appService.byId("nm-connection-editor")
                if (entry) { root.close(false); root.appService.launch(entry) }
            }
        }
        Item { Layout.fillHeight: true }
    }
}
