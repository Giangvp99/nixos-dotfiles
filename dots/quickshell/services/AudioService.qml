pragma Singleton

import QtQuick
import Quickshell.Services.Pipewire

QtObject {
    id: root

    /*
     * AudioService
     *
     * Single owner của trạng thái audio output.
     *
     * Backend:
     *   Quickshell.Services.Pipewire
     *
     * Public API:
     *
     *   outputs / inputs, sink / source, deviceLabel(node)
     *   selectOutput(node) / selectInput(node)
     *   inputAvailable / inputVolume / inputVolumePercent / inputMuted
     *   setInputVolume(value) / toggleInputMute()
     *
     *   available
     *   volume
     *   volumePercent
     *   muted
     *
     *   toggleMute()
     *   setMuted()
     *   setVolume()
     *   increaseVolume()
     *   decreaseVolume()
     */

    // -------------------------------------------------------------------------
    // Backend
    // -------------------------------------------------------------------------

    // Injectable for isolated tests; the live shell always uses native PipeWire.
    property var backend: Pipewire
    readonly property var outputs: backend.ready ? backend.nodes.values.filter(node =>
        (node.type & PwNodeType.Audio) && !node.isStream && node.isSink) : []
    readonly property var inputs: backend.ready ? backend.nodes.values.filter(node =>
        (node.type & PwNodeType.Audio) && !node.isStream && !node.isSink) : []
    readonly property var sink: backend.defaultAudioSink
    readonly property var source: backend.defaultAudioSource
    readonly property var inputAudio: source ? source.audio : null
    readonly property bool inputAvailable: backend.ready && source !== null && source.ready !== false && inputAudio !== null
    readonly property real inputVolume: inputAvailable && inputAudio ? inputAudio.volume : 0
    readonly property int inputVolumePercent: Math.round(inputVolume * 100)
    readonly property bool inputMuted: inputAvailable && inputAudio ? inputAudio.muted : false

    function deviceLabel(node) {
        return node ? (node.description || node.nickname || node.name || "Audio device") : ""
    }
    function selectOutput(node) {
        if (backend.ready && outputs.indexOf(node) >= 0)
            backend.preferredDefaultAudioSink = node
    }
    function selectInput(node) {
        if (backend.ready && inputs.indexOf(node) >= 0)
            backend.preferredDefaultAudioSource = node
    }
    function setInputVolume(value) {
        if (inputAvailable && inputAudio && Number.isFinite(value))
            inputAudio.volume = Math.max(0, Math.min(maxVolume, value))
    }
    function toggleInputMute() {
        if (inputAvailable && inputAudio) inputAudio.muted = !inputAudio.muted
    }

    readonly property var audio:
        sink ? sink.audio : null

    /*
     * PwNode audio properties chỉ hợp lệ khi node đã được bind.
     *
     * Tracker tự cập nhật khi default output/input thay đổi.
     */
    property PwObjectTracker tracker: PwObjectTracker {
        objects: root.backend === Pipewire ? [root.sink, root.source].filter(node => node !== null) : []
    }

    // -------------------------------------------------------------------------
    // Public state
    // -------------------------------------------------------------------------

    readonly property bool available:
        backend.ready
        && sink !== null
        && sink.ready !== false
        && audio !== null

    readonly property real volume:
        available && audio !== null
        ? audio.volume
        : 0.0

    readonly property int volumePercent:
        Math.round(volume * 100)

    readonly property bool muted:
        available && audio !== null
        ? audio.muted
        : false

    // -------------------------------------------------------------------------
    // Configuration
    // -------------------------------------------------------------------------

    readonly property real volumeStep: 0.05
    readonly property real maxVolume: 1.0

    // -------------------------------------------------------------------------
    // Public actions
    // -------------------------------------------------------------------------

    function toggleMute() {
        if (!available || !audio)
            return

        audio.muted = !audio.muted
    }

    function setMuted(value) {
        if (!available || !audio)
            return

        audio.muted = value
    }

    function setVolume(value) {
        if (!available || !audio || !Number.isFinite(value))
            return

        audio.volume = Math.max(
            0.0,
            Math.min(maxVolume, value)
        )
    }

    function increaseVolume() {
        setVolume(volume + volumeStep)
    }

    function decreaseVolume() {
        setVolume(volume - volumeStep)
    }
}
