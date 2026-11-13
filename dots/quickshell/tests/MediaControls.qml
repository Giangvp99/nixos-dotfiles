import QtQuick
import QtTest
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../modules/dashboard" as Dashboard
import "../services" as Services

ShellRoot {
    id: root
    property bool mockMode: false
    property int assertions: 0
    function check(value,message) { if(!value) throw new Error(message); assertions++ }
    function find(node,name) {
        if(!node) return null
        if(node.objectName===name) return node
        if(node.contentItem) { const result=find(node.contentItem,name); if(result) return result }
        for(const child of (node.children||[])) { const result=find(child,name); if(result) return result }
        return null
    }
    component Player: QtObject {
        property string dbusName: "org.mpris.MediaPlayer2.test"
        property string identity: "Test player"
        property string desktopEntry: "test-player"
        property bool isPlaying: false
        property bool canControl: true
        property bool canGoPrevious: true
        property bool canGoNext: true
        property bool canTogglePlaying: true
        property string trackTitle: "Test track"
        property string trackArtist: "Test artist"
        property string trackArtUrl: ""
        property int previousCalls: 0
        property int nextCalls: 0
        property int toggleCalls: 0
        function previous() { previousCalls++ }
        function next() { nextCalls++ }
        function togglePlaying() { toggleCalls++; isPlaying=!isPlaying }
    }
    Player { id: paused; dbusName:"org.mpris.MediaPlayer2.paused"; identity:"Paused player" }
    Player { id: playing; dbusName:"org.mpris.MediaPlayer2.playing"; identity:"Playing player"; isPlaying:true }
    Player { id: locked; dbusName:"org.mpris.MediaPlayer2.locked"; identity:"Read-only player"; canControl:false }
    QtObject { id: backend; property ScriptModel players: ScriptModel { values:[paused,playing,locked] } }
    PanelWindow {
        id: window
        implicitWidth: 420
        implicitHeight: 600
        color: "transparent"
        focusable: true
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        Loader {
            id: loader
            width: parent.width
            active: true
            sourceComponent: Dashboard.MediaCard { property TestEvent events:TestEvent{} }
        }
    }
    PersistentProperties {
        id: memory
        reloadableId: "media-dashboard-test"
        property bool opened: false
        property string screenName: ""
        property bool mockEnabled: false
        property int generation: 0
        onLoaded: {
            generation++
            if (mockEnabled) mediaIpc.mocks()
            if (opened) window.visible=false
            dashboard.restoreSession(memory)
        }
    }
    Dashboard.Dashboard { id: dashboard }
    IpcHandler {
        id:mediaIpc
        target:"mediaTest"
        function status():string {
            const s=Services.MediaService
            return JSON.stringify({loaded:loader.item!==null,visible:loader.item?loader.item.visible:false,
                count:s.players.length,name:s.playerName,available:s.available,title:s.trackTitle,artist:s.trackArtist,
                selected:s.selectedBusName,isPlaying:s.isPlaying,canToggle:s.canToggle,canNext:s.canNext,canPrevious:s.canPrevious,
                height:loader.item?loader.item.implicitHeight:0,width:loader.item?loader.item.width:0,
                art:loader.item?loader.item.artworkStatus:-1,
                focus:loader.item?loader.item.focusTargets().filter(item=>item.activeFocus).map(item=>item.objectName):[],
                assertions:root.assertions})
        }
        function mocks():void { Services.MediaService.backend=backend; root.mockMode=true; memory.mockEnabled=true }
        function serviceTests():int {
            root.check(root.mockMode,"mock backend required")
            const s=Services.MediaService
            root.check(s.activePlayer===playing,"prefer playing player")
            playing.isPlaying=false; root.check(s.activePlayer===paused,"fallback first player")
            playing.isPlaying=true; root.check(s.activePlayer===playing,"react to playback")
            s.selectPlayer(paused); root.check(s.activePlayer===paused,"manual selection")
            root.check(s.selectedBusName===paused.dbusName,"selection uses stable bus identity")
            playing.isPlaying=false; playing.isPlaying=true
            root.check(s.activePlayer===paused,"manual choice survives other playback changes")
            s.previous(); s.togglePlaying(); s.next()
            root.check(paused.previousCalls===1&&paused.nextCalls===1&&paused.toggleCalls===1,"actions routed to selected player")
            paused.trackTitle=""; paused.trackArtist=""
            root.check(s.trackTitle==="Unknown title"&&s.trackArtist==="Unknown artist","missing metadata fallback")
            s.selectPlayer(locked)
            root.check(!s.canPrevious&&!s.canNext&&!s.canToggle,"capabilities include canControl")
            s.previous();s.next();s.togglePlaying()
            root.check(locked.previousCalls===0&&locked.nextCalls===0&&locked.toggleCalls===0,"blocked actions ignored")
            locked.canControl=true;locked.canGoNext=false;locked.canGoPrevious=false
            root.check(s.canToggle&&!s.canNext&&!s.canPrevious,"partial capabilities")
            s.next();s.previous();s.togglePlaying()
            root.check(locked.toggleCalls===1&&locked.nextCalls===0&&locked.previousCalls===0,"partial action guards")
            backend.players.values=[paused,playing]
            root.check(s.selectedBusName===""&&s.activePlayer===paused,"remove selected player; prefer remaining playing")
            s.selectPlayer(locked);root.check(s.selectedBusName==="","reject stale player")
            backend.players.values=[]
            root.check(!s.available&&s.activePlayer===null,"all players disappear")
            s.previous();s.next();s.togglePlaying()
            root.check(paused.nextCalls===1&&playing.nextCalls===0,"no calls while unavailable")
            return root.assertions
        }
        function reset():void {
            paused.isPlaying=false;paused.trackTitle="A very long title <b>plain text</b> repeated for layout testing";paused.trackArtist="Artist";
            playing.isPlaying=true
            locked.canControl=false;locked.isPlaying=false;locked.canGoNext=true;locked.canGoPrevious=true
            paused.nextCalls=0;paused.previousCalls=0;paused.toggleCalls=0
            playing.nextCalls=0;playing.previousCalls=0;playing.toggleCalls=0
            Services.MediaService.selectedBusName=""
            backend.players.values=[paused,playing,locked]
        }
        function focus(name:string):void { root.find(loader.item,name).forceActiveFocus() }
        function key(name:string):bool {
            return loader.item.events.keyClick(({Return:Qt.Key_Return,Escape:Qt.Key_Escape,Tab:Qt.Key_Tab,Backtab:Qt.Key_Backtab})[name],0,0)
        }
        function click(name:string):void { root.find(loader.item,name).clicked() }
        function uiCheck(stage:string):int {
            root.check(root.mockMode,"mock backend required")
            if(stage==="controls") root.check(playing.nextCalls===1&&playing.previousCalls===1&&playing.toggleCalls===1,"keyboard player actions")
            if(stage==="selected") root.check(Services.MediaService.activePlayer===paused,"Enter selects player")
            if(stage==="returned") root.check(root.find(loader.item,"mediaChoosePlayer").activeFocus,"selection returns focus")
            if(stage==="escape") root.check(root.find(loader.item,"mediaChoosePlayer").activeFocus,"Escape returns focus")
            if(stage==="blocked") root.check(!root.find(loader.item,"mediaNext").enabled&&!root.find(loader.item,"mediaPlayPause").enabled,"disabled controls")
            if(stage==="hidden") root.check(!loader.item.visible&&loader.item.focusTargets().length===0,"hide when unavailable")
            return root.assertions
        }
        function lockPlayer():void { Services.MediaService.selectPlayer(locked) }
        function removeSelected():void { backend.players.values=[playing,locked] }
        function removeAll():void { backend.players.values=[] }
        function single():void { backend.players.values=[paused];Services.MediaService.selectedBusName="" }
        function artwork(url:string):void { paused.trackArtUrl=url }
        function metadata(longTitle:bool):void { paused.trackTitle=longTitle?"Long title ".repeat(50):"Short";paused.trackArtist=longTitle?"Long artist ".repeat(30):"Artist" }
        function resize(width:int):void { window.implicitWidth=width }
        function unload():void { loader.active=false }
        function load():void { loader.active=true }
        function fullOpen():void { window.visible=false;dashboard.open() }
        function fullStatus():string {
            const c=dashboard.content
            const card=root.find(dashboard.panel,"dashboardMedia")
            return JSON.stringify({generation:memory.generation,opened:dashboard.opened,loaded:c!==null,
                targets:c?c.focusTargets().map(item=>item.objectName):[],
                focus:c?c.focusTargets().filter(item=>item.activeFocus).map(item=>item.objectName):[],
                cardVisible:card?card.visible:false,screen:dashboard.targetScreen?dashboard.targetScreen.name:""})
        }
        function fullArtwork(url:string):void {
            root.check(root.mockMode,"mock backend required")
            Services.MediaService.activePlayer.trackArtUrl=url
        }
        function fullFocus(name:string):void { root.find(dashboard.panel,name).forceActiveFocus() }
    }
}
