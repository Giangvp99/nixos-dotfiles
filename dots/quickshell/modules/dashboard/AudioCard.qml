pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../config" as Config
import "../../components" as Components
import "../../services" as Services

DashboardCard {
    id: root
    objectName: "dashboardAudio"
    title: "Audio"
    property var audioService: Services.AudioService
    property var focusController: null
    property bool compact: false
    contentPadding: compact ? Config.Theme.spaceLarge : Config.Theme.panelPadding
    signal focusRequested(var item)

    function focusTargets() {
        return output.focusTargets().concat(input.focusTargets()).filter(item => item.visible && item.enabled)
    }
    function cycleFocus(delta) {
        if (focusController) { focusController.cycleFocus(delta); return }
        const targets = focusTargets()
        if (!targets.length) return
        const current = targets.findIndex(item => item.activeFocus)
        const index = current < 0 ? (delta > 0 ? 0 : targets.length - 1)
            : (current + delta + targets.length) % targets.length
        targets[index].forceActiveFocus()
    }

    component AudioButton: Components.IconButton {
        focusController: root
        border.width: activeFocus || active ? Config.Theme.focusBorderWidth : 0
        onActiveFocusChanged: if (activeFocus) root.focusRequested(this)
    }
    component Endpoint: ColumnLayout {
        id: section
        required property bool isInput
        property bool expanded: false
        onExpandedChanged: {
            if (root.compact && expanded) {
                if (section.isInput) output.expanded=false
                else input.expanded=false
            }
        }
        property bool deviceFocus: false
        readonly property var service: root.audioService
        readonly property var devices: isInput ? service.inputs : service.outputs
        readonly property var current: isInput ? service.source : service.sink
        readonly property bool available: isInput ? service.inputAvailable : service.available
        readonly property bool muted: isInput ? service.inputMuted : service.muted
        readonly property int percent: isInput ? service.inputVolumePercent : service.volumePercent
        readonly property string prefix: isInput ? "dashboardInput" : "dashboardOutput"
        spacing: Config.Theme.spaceSmall

        function focusTargets() {
            let targets = [mute, slider, choose]
            if (deviceLoader.item) targets = targets.concat(deviceLoader.item.focusTargets())
            return targets
        }
        onDevicesChanged: Qt.callLater(function() {
            if (section.deviceFocus && !section.focusTargets().some(item => item.activeFocus)) {
                section.deviceFocus = false
                if (choose.enabled) choose.forceActiveFocus()
                else root.cycleFocus(1)
            }
        })
        Keys.onEscapePressed: event => {
            if (expanded) {
                expanded = false
                deviceFocus = false
                Qt.callLater(function() { choose.forceActiveFocus() })
            } else event.accepted = false
        }
        Components.StyledText {
            visible: !root.compact || !section.expanded
            text: section.isInput ? "Microphone" : "Output"
            color: Config.Theme.subtext
            font.pixelSize: Config.Theme.fontSmall
        }
        RowLayout {
            visible: !root.compact || !section.expanded
            Layout.fillWidth: true
            spacing: Config.Theme.spaceSmall
            Components.StyledText {
                Layout.fillWidth: true
                text: !section.available ? (section.isInput ? "No microphone" : "No audio output")
                    : (section.muted ? "Muted" : section.percent + "%")
                font.pixelSize: Config.Theme.fontLarge
                elide: Text.ElideRight
            }
            AudioButton {
                id: mute
                objectName: section.isInput ? "dashboardInputMute" : "dashboardMute"
                icon: section.isInput ? (section.muted ? "󰍭" : "󰍬") : (section.muted ? "󰖁" : "󰕾")
                text: section.muted ? "Unmute" : "Mute"
                Accessible.name: (section.isInput ? "Microphone: " : "Output: ") + text
                enabled: section.available
                active: section.muted
                onClicked: if (section.isInput) section.service.toggleInputMute(); else section.service.toggleMute()
                onActiveFocusChanged: if (activeFocus) section.deviceFocus = false
            }
        }
        Components.StyledSlider {
            id: slider
            visible: !root.compact || !section.expanded
            objectName: section.isInput ? "dashboardInputVolume" : "dashboardVolume"
            Layout.fillWidth: true
            enabled: section.available
            value: section.available ? (section.isInput ? section.service.inputVolume : section.service.volume) : 0
            Accessible.name: section.isInput ? "Microphone volume" : "Output volume"
            onMoved: if (section.isInput) section.service.setInputVolume(value); else section.service.setVolume(value)
            onActiveFocusChanged: if (activeFocus) {
                section.deviceFocus = false
                root.focusRequested(this)
            }
            Keys.onTabPressed: root.cycleFocus(1)
            Keys.onBacktabPressed: root.cycleFocus(-1)
        }
        AudioButton {
            id: choose
            objectName: section.prefix + "Devices"
            Layout.fillWidth: true
            fillContentWidth: true
            icon: section.expanded ? "󰅃" : "󰅀"
            text: (root.compact && section.expanded ? (section.isInput ? "Microphone · " : "Output · ") : "")
                + (section.service.deviceLabel(section.current) || (section.isInput ? "No input devices" : "No output devices"))
            textFormat: Text.PlainText
            Accessible.name: (section.isInput ? "Choose microphone: " : "Choose output: ") + text
            active: section.expanded
            enabled: section.devices.length > 0
            onClicked: section.expanded = !section.expanded
            onActiveFocusChanged: if (activeFocus) section.deviceFocus = false
        }
        Loader {
            id: deviceLoader
            Layout.fillWidth: true
            active: section.expanded
            visible: active
            sourceComponent: ColumnLayout {
                spacing: Config.Theme.spaceSmall
                function focusTargets() {
                    let targets = []
                    for (let i = 0; i < choices.count; ++i) targets.push(choices.itemAt(i))
                    return targets.concat(pager.focusTargets())
                }
                Repeater {
                    id: choices
                    model: section.devices.slice(pager.start, pager.start + pager.pageSize)
                    delegate: AudioButton {
                        required property int index
                        readonly property var device: section.devices[pager.start + index]
                        objectName: section.prefix + "Device_" + device.id
                        Layout.fillWidth: true
                        fillContentWidth: true
                        text: section.service.deviceLabel(device)
                        textFormat: Text.PlainText
                        active: section.current === device
                        icon: active ? "󰄬" : ""
                        Accessible.name: text + (active ? ", selected" : "")
                        onClicked: if (section.isInput) section.service.selectInput(device); else section.service.selectOutput(device)
                        onActiveFocusChanged: if (activeFocus) section.deviceFocus = true
                    }
                }
                ChoicePager {
                    id: pager
                    Layout.fillWidth: true
                    count: section.devices.length
                    pageSize: root.compact ? 2 : Math.max(1, count)
                    focusController: root
                    onFocusRequested: item => root.focusRequested(item)
                }
                Components.StyledText {
                    visible: section.devices.length === 0
                    Layout.fillWidth: true
                    text: "Device disconnected"
                    color: Config.Theme.subtext
                }
            }
        }
    }
    Endpoint { id: output; isInput: false; Layout.fillWidth: true }
    Endpoint { id: input; isInput: true; Layout.fillWidth: true }
}
