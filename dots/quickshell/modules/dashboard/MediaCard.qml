pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../config" as Config
import "../../components" as Components
import "../../services" as Services

DashboardCard {
    id: root
    objectName: "dashboardMedia"
    title: "Now playing"
    property var mediaService: Services.MediaService
    property var focusController: null
    property bool compact: false
    contentPadding: compact ? Config.Theme.spaceLarge : Config.Theme.panelPadding
    property bool expanded: false
    property bool hadFocus: false
    readonly property int artworkStatus: cover.status
    signal focusRequested(var item)
    visible: mediaService.available

    function focusTargets() {
        if (!visible) return []
        let targets=[previous,play,next,choose]
        if (playerLoader.item) targets=targets.concat(playerLoader.item.focusTargets())
        return targets.filter(item => item && item.visible && item.enabled)
    }
    function cycleFocus(delta) {
        if (focusController) { focusController.cycleFocus(delta); return }
        const targets=focusTargets()
        if (!targets.length) return
        const current=targets.findIndex(item=>item.activeFocus)
        targets[(current+delta+targets.length)%targets.length].forceActiveFocus()
    }
    function focusChooser() {
        if (choose.visible && choose.enabled) choose.forceActiveFocus()
        else recoverFocus()
    }
    function closeChooser() { expanded=false; Qt.callLater(root.focusChooser) }
    function recoverFocus() {
        if (!hadFocus) return
        const own=focusTargets()
        if (own.some(item=>item.activeFocus)) return
        const others=focusController ? focusController.focusTargets() : []
        if (others.some(item=>item.activeFocus)) { hadFocus=false; return }
        hadFocus=false
        if (choose.visible && choose.enabled) choose.forceActiveFocus()
        else if (own.length) own[0].forceActiveFocus()
        else if (focusController) focusController.cycleFocus(1)
    }
    onVisibleChanged: if (!visible) { expanded=false; Qt.callLater(root.recoverFocus) }
    Keys.onEscapePressed: event => {
        if (expanded) {
            root.closeChooser()
        } else event.accepted=false
    }
    Connections {
        target: root.mediaService
        function onPlayersChanged() {
            if (root.mediaService.players.length<2) root.expanded=false
            Qt.callLater(root.recoverFocus)
        }
        function onActivePlayerChanged() { Qt.callLater(root.recoverFocus) }
        function onCanPreviousChanged() { Qt.callLater(root.recoverFocus) }
        function onCanToggleChanged() { Qt.callLater(root.recoverFocus) }
        function onCanNextChanged() { Qt.callLater(root.recoverFocus) }
    }
    component MediaButton: Components.IconButton {
        focusController: root
        border.width: activeFocus || active ? Config.Theme.focusBorderWidth : 0
        onActiveFocusChanged: if (activeFocus) { root.hadFocus=true; root.focusRequested(this) }
    }
    RowLayout {
        visible: !root.compact || !root.expanded
        Layout.fillWidth: true
        spacing: Config.Theme.spaceLarge
        Rectangle {
            Layout.preferredWidth: Config.Theme.mediaArtworkSize
            Layout.minimumWidth: Config.Theme.mediaArtworkSize
            Layout.preferredHeight: Config.Theme.mediaArtworkSize
            radius: Config.Theme.radiusSmall
            color: Config.Theme.controlBackground
            clip: true
            Components.StyledText {
                anchors.centerIn: parent
                text: "󰝚"
                font.family: Config.Theme.iconFontFamily
                font.pixelSize: Config.Theme.launcherIconSize
                color: Config.Theme.primary
                visible: cover.status!==Image.Ready
            }
            Image {
                id: cover
                objectName: "mediaArtwork"
                anchors.fill: parent
                source: root.visible ? root.mediaService.artwork : ""
                sourceSize: Qt.size(Config.Theme.mediaArtworkSize,Config.Theme.mediaArtworkSize)
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                visible: status===Image.Ready
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.preferredWidth: 1
            spacing: Config.Theme.spaceSmall
            Components.StyledText {
                objectName: "mediaTitle"
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: root.mediaService.trackTitle
                textFormat: Text.PlainText
                elide: Text.ElideRight
                maximumLineCount: 1
                font.pixelSize: Config.Theme.fontLarge
            }
            Components.StyledText {
                objectName: "mediaArtist"
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: root.mediaService.trackArtist
                textFormat: Text.PlainText
                elide: Text.ElideRight
                maximumLineCount: 1
                color: Config.Theme.subtext
            }
            Components.StyledText {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: root.mediaService.playerName
                textFormat: Text.PlainText
                elide: Text.ElideRight
                font.pixelSize: Config.Theme.fontSmall
                color: Config.Theme.subtext
            }
        }
    }
    RowLayout {
        visible: !root.compact || !root.expanded
        Layout.fillWidth: true
        spacing: Config.Theme.spaceSmall
        MediaButton {
            id: previous
            objectName: "mediaPrevious"
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: "󰒮"
            Accessible.name: "Previous track"
            enabled: root.mediaService.canPrevious
            onClicked: root.mediaService.previous()
        }
        MediaButton {
            id: play
            objectName: "mediaPlayPause"
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: root.mediaService.isPlaying ? "󰏤" : "󰐊"
            Accessible.name: root.mediaService.isPlaying ? "Pause playback" : "Play media"
            active: root.mediaService.isPlaying
            enabled: root.mediaService.canToggle
            onClicked: root.mediaService.togglePlaying()
        }
        MediaButton {
            id: next
            objectName: "mediaNext"
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: "󰒭"
            Accessible.name: "Next track"
            enabled: root.mediaService.canNext
            onClicked: root.mediaService.next()
        }
    }
    MediaButton {
        id: choose
        objectName: "mediaChoosePlayer"
        Layout.fillWidth: true
        fillContentWidth: true
        visible: root.mediaService.players.length>1
        active: root.expanded
        text: "Player: " + root.mediaService.playerName
        textFormat: Text.PlainText
        icon: root.expanded ? "󰅃" : "󰅀"
        Accessible.name: "Choose media player: " + root.mediaService.playerName
        onClicked: { if (root.expanded) root.closeChooser(); else root.expanded=true }
    }
    Loader {
        id: playerLoader
        Layout.fillWidth: true
        active: root.visible && root.expanded
        visible: active
        sourceComponent: ColumnLayout {
            spacing: Config.Theme.spaceSmall
            function focusTargets() {
                let targets=[]
                for (let i=0;i<players.count;i++) targets.push(players.itemAt(i))
                return targets.concat(pager.focusTargets())
            }
            Repeater {
                id: players
                model: root.mediaService.players.slice(pager.start, pager.start + pager.pageSize)
                delegate: MediaButton {
                    required property int index
                    readonly property var player: root.mediaService.players[pager.start + index]
                    objectName: "mediaPlayer_" + (pager.start + index)
                    Layout.fillWidth: true
                    fillContentWidth: true
                    text: root.mediaService.label(player)
                    textFormat: Text.PlainText
                    active: root.mediaService.activePlayer===player
                    icon: active ? "󰄬" : ""
                    Accessible.name: text + (active ? ", selected" : "")
                    onClicked: {
                        root.mediaService.selectPlayer(player)
                        root.closeChooser()
                    }
                }
            }
            ChoicePager {
                id: pager
                Layout.fillWidth: true
                count: root.mediaService.players.length
                pageSize: root.compact ? 2 : Math.max(1, count)
                focusController: root
                onFocusRequested: item => root.focusRequested(item)
            }
        }
    }
}
