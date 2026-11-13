import QtQuick
import "../../config" as Config
import "../../services" as Services

// Event-driven state; one timer only while feedback is visible.
QtObject {
    id: root
    property var audioService: Services.AudioService
    property bool enabled: Config.Config.audioOsdEnabled
    property int timeout: Config.Config.audioOsdTimeout
    property bool shown: false
    property string channel: "output"
    property int percent: 0
    property bool muted: false
    property string deviceName: ""
    property var outputSnapshot: null
    property var inputSnapshot: null
    property bool queued: false
    readonly property bool timerRunning: dismissTimer.running
    signal presented()

    function hide() { dismissTimer.stop(); shown = false }
    function scheduleSample() {
        if (!queued) { queued = true; Qt.callLater(root.sample) }
    }
    function readSample(input) {
        const node = input ? audioService.source : audioService.sink
        return {node: node, ready: input ? audioService.inputAvailable : audioService.available,
            percent: input ? audioService.inputVolumePercent : audioService.volumePercent,
            muted: input ? audioService.inputMuted : audioService.muted}
    }
    function changed(before, after) {
        return before && before.ready && after.ready && before.node === after.node
            && (before.percent !== after.percent || before.muted !== after.muted)
    }
    function sample() {
        queued = false
        const output = readSample(false), input = readSample(true)
        const outputChanged = changed(outputSnapshot, output)
        const inputChanged = changed(inputSnapshot, input)
        const current = channel === "input" ? input : output
        const previous = channel === "input" ? inputSnapshot : outputSnapshot
        if (!current.ready || (previous && previous.node !== current.node)) hide()
        outputSnapshot = output
        inputSnapshot = input
        if (!enabled || (!outputChanged && !inputChanged)) return
        const next = outputChanged ? output : input
        channel = outputChanged ? "output" : "input"
        percent = Math.max(0, next.percent)
        muted = next.muted
        deviceName = audioService.deviceLabel(next.node)
        shown = true
        presented()
        dismissTimer.restart()
    }
    onAudioServiceChanged: scheduleSample()
    onEnabledChanged: if (!enabled) hide()
    Component.onCompleted: sample()
    property Timer dismissTimer: Timer {
        interval: root.timeout
        repeat: false
        onTriggered: root.shown = false
    }
    property Connections audioChanges: Connections {
        target: root.audioService
        function onSinkChanged() { root.scheduleSample() }
        function onSourceChanged() { root.scheduleSample() }
        function onAvailableChanged() { root.scheduleSample() }
        function onInputAvailableChanged() { root.scheduleSample() }
        function onVolumePercentChanged() { root.scheduleSample() }
        function onMutedChanged() { root.scheduleSample() }
        function onInputVolumePercentChanged() { root.scheduleSample() }
        function onInputMutedChanged() { root.scheduleSample() }
    }
}
