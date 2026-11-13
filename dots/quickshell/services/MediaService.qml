pragma Singleton
import QtQuick
import Quickshell.Services.Mpris

QtObject {
    id: root
    property var backend: Mpris
    property string selectedBusName: ""
    readonly property var players: backend.players.values.filter(player => player !== null)
    readonly property var activePlayer: {
        const list = players
        const selected = selectedBusName
        for (let i=0; i<list.length; ++i) {
            if (selected && list[i].dbusName === selected) return list[i]
        }
        for (let i=0; i<list.length; ++i) {
            if (list[i].isPlaying) return list[i]
        }
        return list[0] || null
    }
    readonly property bool available: activePlayer !== null
    readonly property bool isPlaying: Boolean(activePlayer && activePlayer.isPlaying)
    readonly property string trackTitle: (activePlayer && activePlayer.trackTitle) || "Unknown title"
    readonly property string trackArtist: (activePlayer && activePlayer.trackArtist) || "Unknown artist"
    readonly property string artwork: (activePlayer && activePlayer.trackArtUrl) || ""
    readonly property string playerName: label(activePlayer)
    readonly property bool canPrevious: Boolean(activePlayer && activePlayer.canControl && activePlayer.canGoPrevious)
    readonly property bool canNext: Boolean(activePlayer && activePlayer.canControl && activePlayer.canGoNext)
    readonly property bool canToggle: Boolean(activePlayer && activePlayer.canControl && activePlayer.canTogglePlaying)
    onPlayersChanged: {
        if (selectedBusName && !players.some(player => player.dbusName === selectedBusName)) selectedBusName=""
    }
    function label(player) { return player ? (player.identity || player.desktopEntry || "Media player") : "" }
    function contains(player) { return !!player && players.some(value => value === player) }
    function selectPlayer(player) {
        if (contains(player) && player.dbusName) selectedBusName=player.dbusName
    }
    function previous() {
        const player=activePlayer
        if (contains(player) && player.canControl && player.canGoPrevious) player.previous()
    }
    function togglePlaying() {
        const player=activePlayer
        if (contains(player) && player.canControl && player.canTogglePlaying) player.togglePlaying()
    }
    function next() {
        const player=activePlayer
        if (contains(player) && player.canControl && player.canGoNext) player.next()
    }
}
