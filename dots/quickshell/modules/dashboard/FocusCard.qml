import QtQuick
import QtQuick.Layouts
import "../../components" as Components
import "../../config" as Config
import "../../services" as Services

DashboardCard {
    id: root
    title: "Focus session"
    property var session: Services.FocusSession
    property var notifications: Services.NotificationState
    property var focusController: null
    property string selectedMode: ""
    property bool quiet: false
    signal focusRequested(var item)
    function focusTargets() {
        let items = [minutes]
        for (let i = 0; i < presets.count; i++) items.push(presets.itemAt(i))
        for (let i = 0; i < modes.count; i++) items.push(modes.itemAt(i))
        return items.concat([dnd, primary, stop]).filter(item => item.visible && item.enabled)
    }
    component Button: Components.IconButton {
        border.width: active || activeFocus ? Config.Theme.focusBorderWidth : 0
        focusController: root.focusController
        onActiveFocusChanged: if (activeFocus) root.focusRequested(this)
    }
    RowLayout {
        Layout.fillWidth: true
        Components.StyledText {
            text: root.session.clockText
            font.pixelSize: Config.Theme.fontDisplay
            font.weight: Config.Theme.emphasisFontWeight
        }
        Components.StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
            text: ({idle: "Ready", running: "Focusing", paused: "Paused", completed: "Completed"})[root.session.status]
            color: Config.Theme.subtext
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Repeater {
            id: presets
            model: [25, 50]
            delegate: Button {
                required property int modelData
                text: modelData + " min"
                enabled: !root.session.active
                onClicked: minutes.text = String(modelData)
            }
        }
        Components.Surface {
            Layout.fillWidth: true
            implicitHeight: Config.Theme.controlHeight
            color: Config.Theme.inputBackground
            border.width: 1
            border.color: minutes.activeFocus ? Config.Theme.controlSelected : Config.Theme.border
            TextInput {
                id: minutes
                objectName: "focusMinutes"
                anchors.fill: parent
                anchors.margins: Config.Theme.spaceSmall
                text: String(Math.round(root.session.durationSeconds / 60))
                color: Config.Theme.text
                selectionColor: Config.Theme.primary
                selectedTextColor: Config.Theme.onAccent
                font.family: Config.Theme.fontFamily
                font.pixelSize: Config.Theme.fontNormal
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                selectByMouse: true
                enabled: !root.session.active
                validator: IntValidator { bottom: 1; top: 180 }
                activeFocusOnTab: true
                Accessible.name: "Focus duration in minutes"
                Keys.onTabPressed: if (root.focusController) root.focusController.cycleFocus(1)
                Keys.onBacktabPressed: if (root.focusController) root.focusController.cycleFocus(-1)
                onActiveFocusChanged: if (activeFocus) root.focusRequested(this)
            }
        }
        Components.StyledText { text: "min"; color: Config.Theme.subtext }
    }
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        Repeater {
            id: modes
            model: ["", "writing", "code", "relax"]
            delegate: Button {
                required property string modelData
                Layout.fillWidth: true
                text: modelData ? modelData.charAt(0).toUpperCase() + modelData.slice(1) : "Current mode"
                active: (root.session.active ? root.session.modeId : root.selectedMode) === modelData
                enabled: !root.session.active
                onClicked: root.selectedMode = modelData
            }
        }
    }
    Button {
        id: dnd
        Layout.fillWidth: true
        text: !root.notifications.available ? "DND unavailable"
            : root.session.active ? (root.session.managesDnd ? "DND enabled by session" : root.notifications.dnd ? "DND already on" : "DND off")
            : "Enable DND · " + (root.quiet ? "On" : "Off")
        active: root.session.active ? root.notifications.dnd : root.quiet
        enabled: !root.session.active && root.notifications.available
        onClicked: root.quiet = !root.quiet
    }
    RowLayout {
        Layout.fillWidth: true
        Button {
            id: primary
            objectName: "focusPrimary"
            Layout.fillWidth: true
            text: root.session.status === "running" ? "Pause" : (root.session.status === "paused" ? "Resume" : "Start")
            enabled: root.session.ready && (root.session.active || minutes.acceptableInput)
            onClicked: {
                if (root.session.status === "running") root.session.pause()
                else if (root.session.status === "paused") root.session.resume()
                else root.session.start(Number(minutes.text) * 60, root.quiet, root.selectedMode)
            }
        }
        Button {
            id: stop
            objectName: "focusStop"
            text: "End"
            enabled: root.session.active
            onClicked: { root.session.stop(); primary.forceActiveFocus() }
        }
    }
    Components.StyledText {
        Layout.fillWidth: true
        visible: root.session.error.length > 0
        text: root.session.error
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        color: Config.Theme.subtext
    }
}
