import QtQuick
import QtQuick.Layouts
import "../../../config" as Config
import "../../../components" as Components

BarPopup {
    id: root
    property string title: ""
    property Component bodyComponent: null
    readonly property int chromeHeight: Config.Theme.popupPadding*2 + Config.Theme.controlHeight + Config.Theme.spaceLarge
    readonly property alias body: bodyLoader.item
    initialFocusItem: closeButton
    function focusTargets() {
        const controls=body && body.focusTargets ? body.focusTargets() : []
        return [closeButton].concat(controls).filter(item=>item && item.visible && item.enabled)
    }
    function cycleFocus(delta) {
        const controls=focusTargets()
        if (!controls.length) return
        const current=controls.findIndex(item=>item.activeFocus)
        controls[(current+delta+controls.length)%controls.length].forceActiveFocus()
    }
    Components.Surface {
        anchors.fill: parent
        panel: true
        Keys.onEscapePressed: root.close(true)
        Keys.onTabPressed: root.cycleFocus(1)
        Keys.onBacktabPressed: root.cycleFocus(-1)
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Config.Theme.popupPadding
            spacing: Config.Theme.spaceLarge
            RowLayout {
                Layout.fillWidth: true
                Components.StyledText {
                    Layout.fillWidth: true
                    text: root.title
                    textFormat: Text.PlainText
                    font.pixelSize: Config.Theme.fontLarge
                    font.weight: Config.Theme.emphasisFontWeight
                }
                Components.IconButton {
                    id: closeButton
                    objectName: "detailsClose"
                    icon: "󰅖"
                    Accessible.name: "Close " + root.title
                    focusController: root
                    onClicked: root.close(true)
                }
            }
            Loader {
                id: bodyLoader
                Layout.fillWidth: true
                Layout.fillHeight: true
                active: root.visible
                sourceComponent: root.bodyComponent
            }
        }
    }
}
