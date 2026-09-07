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

    readonly property var sink:
        Pipewire.defaultAudioSink

    readonly property var audio:
        sink ? sink.audio : null

    /*
     * PwNode audio properties chỉ hợp lệ khi node đã được bind.
     *
     * Tracker sẽ tự cập nhật khi defaultAudioSink thay đổi.
     */
    property PwObjectTracker tracker: PwObjectTracker {
        objects: [root.sink]
    }

    // -------------------------------------------------------------------------
    // Public state
    // -------------------------------------------------------------------------

    readonly property bool available:
        Pipewire.ready
        && sink !== null
        && audio !== null

    readonly property real volume:
        available
        ? audio.volume
        : 0.0

    readonly property int volumePercent:
        Math.round(volume * 100)

    readonly property bool muted:
        available
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
        if (!available)
            return

        audio.muted = !audio.muted
    }

    function setMuted(value) {
        if (!available)
            return

        audio.muted = value
    }

    function setVolume(value) {
        if (!available)
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
