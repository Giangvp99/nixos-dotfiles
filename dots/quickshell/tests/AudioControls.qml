import QtQuick
import QtTest
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../modules/dashboard" as Dashboard
import "../services" as Services

ShellRoot {
    id: root
    property int assertions: 0
    property bool mockMode: false
    function check(value, message) { if (!value) throw new Error(message); assertions++ }
    function find(node, name) {
        if (!node) return null
        if (node.objectName === name) return node
        if (node.contentItem) { const found = find(node.contentItem, name); if (found) return found }
        for (const child of (node.children || [])) { const found = find(child, name); if (found) return found }
        return null
    }
    QtObject { id: speakerAudio; property real volume: 0.4; property bool muted: false }
    QtObject { id: headphoneAudio; property real volume: 0.5; property bool muted: false }
    QtObject { id: micAudio; property real volume: 0.4; property bool muted: false }
    property var speaker: ({id:101,name:"speaker",description:"Speakers",type:PwNodeType.AudioSink,isSink:true,isStream:false,audio:speakerAudio})
    property var headphones: ({id:102,name:"headphones",description:"Headphones with a very long name <b>plain text</b>",type:PwNodeType.AudioSink,isSink:true,isStream:false,audio:headphoneAudio})
    property var mic: ({id:103,name:"mic",description:"Microphone",type:PwNodeType.AudioSource,isSink:false,isStream:false,audio:micAudio})
    property var stream: ({id:104,type:PwNodeType.AudioOutStream,isSink:true,isStream:true})
    property var camera: ({id:105,type:PwNodeType.VideoSource,isSink:false,isStream:false})
    QtObject {
        id: backend
        property bool ready: true
        property QtObject nodes: QtObject { property var values: [speaker, headphones, mic, stream, camera] }
        property var defaultAudioSink: speaker
        property var defaultAudioSource: mic
        property var preferredDefaultAudioSink: null
        property var preferredDefaultAudioSource: null
    }
    PanelWindow {
        id: window
        implicitWidth: 420
        implicitHeight: 850
        focusable: true
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        Loader {
            id: content
            width: parent.width
            active: true
            sourceComponent: Dashboard.AudioCard { audioService: Services.AudioService; property TestEvent events: TestEvent {} }
        }
    }
    Dashboard.Dashboard { id: dashboard }
    IpcHandler {
        target: "audioTest"
        function status(): string {
            const s=Services.AudioService
            return JSON.stringify({loaded:content.item!==null,assertions:root.assertions,
                outputs:s.outputs.map(n=>s.deviceLabel(n)),inputs:s.inputs.map(n=>s.deviceLabel(n)),
                available:s.available,inputAvailable:s.inputAvailable,volume:s.volume,muted:s.muted,
                focus:content.item?content.item.focusTargets().map(item=>({name:item.objectName,focus:item.activeFocus})):[],
                width:content.item?content.item.width:0,height:content.item?content.item.implicitHeight:0})
        }
        function mocks(): void { Services.AudioService.backend=backend; root.mockMode=true }
        function serviceTests(): int {
            const s=Services.AudioService
            root.check(root.mockMode,"mock backend required")
            root.check(s.outputs.length===2 && s.inputs.length===1,"filter video and streams")
            s.setVolume(5); root.check(s.volume===1,"output upper bound")
            s.setVolume(-1); root.check(s.volume===0,"output lower bound")
            s.setVolume(NaN); root.check(s.volume===0,"ignore nonfinite output")
            s.toggleMute(); root.check(s.muted,"output mute")
            s.setInputVolume(2); root.check(s.inputVolume===1,"input upper bound")
            s.setInputVolume(-1); root.check(s.inputVolume===0,"input lower bound")
            s.setInputVolume(NaN); root.check(s.inputVolume===0,"ignore nonfinite input")
            s.toggleInputMute(); root.check(s.inputMuted,"input mute")
            s.selectOutput(headphones); root.check(backend.preferredDefaultAudioSink===headphones,"output selection")
            root.check(s.sink===speaker,"selection waits for backend confirmation")
            backend.defaultAudioSink=headphones
            root.check(s.sink===headphones,"external default change")
            s.selectInput(mic); root.check(backend.preferredDefaultAudioSource===mic,"input selection")
            s.selectOutput(stream); s.selectOutput(null)
            root.check(backend.preferredDefaultAudioSink===headphones,"reject invalid output")
            s.selectInput(speaker); root.check(backend.preferredDefaultAudioSource===mic,"reject invalid input")
            backend.ready=false
            s.selectOutput(speaker); root.check(backend.preferredDefaultAudioSink===headphones,"reject while disconnected")
            root.check(!s.available && !s.inputAvailable,"backend unavailable")
            backend.ready=true
            backend.defaultAudioSink=speaker
            return root.assertions
        }
        function expand(): void { root.find(content.item,"dashboardOutputDevices").clicked() }
        function focus(name: string): void {
            root.find(content.item,name).forceActiveFocus()
        }
        function key(name: string): bool {
            return content.item.events.keyClick(({Return:Qt.Key_Return,Escape:Qt.Key_Escape,Tab:Qt.Key_Tab,Backtab:Qt.Key_Backtab,Right:Qt.Key_Right})[name],0,0)
        }
        function prepareSelection(): void { backend.preferredDefaultAudioSink=speaker }
        function keyboardCheck(stage: string): int {
            root.check(root.mockMode,"mock backend required")
            if(stage==="selection") root.check(backend.preferredDefaultAudioSink===headphones,"Enter selects device")
            if(stage==="escape") root.check(root.find(content.item,"dashboardOutputDevices").activeFocus,"Escape returns focus")
            if(stage==="tab") root.check(root.find(content.item,"dashboardInputMute").activeFocus,"Tab reaches microphone")
            if(stage==="backtab") root.check(root.find(content.item,"dashboardOutputDevices").activeFocus,"Backtab returns to output")
            if(stage==="slider") root.check(Services.AudioService.inputVolume>0,"keyboard adjusts mic")
            return root.assertions
        }
        function focusDevice(): void {
            const toggle=root.find(content.item,"dashboardOutputDevices")
            toggle.clicked()
            Qt.callLater(function(){root.find(content.item,"dashboardOutputDevice_102").forceActiveFocus()})
        }
        function disconnect(): void {
            backend.nodes.values=[mic,stream,camera]
            backend.defaultAudioSink=null
            Services.AudioService.selectOutput(headphones)
        }
        function disconnectedTests(): int {
            root.check(root.mockMode,"mock backend required")
            root.check(!Services.AudioService.available && Services.AudioService.outputs.length===0,"output disappeared")
            root.check(!root.find(content.item,"dashboardMute").enabled,"mute disabled")
            root.check(!root.find(content.item,"dashboardVolume").enabled,"slider disabled")
            root.check(!root.find(content.item,"dashboardOutputDevices").enabled,"selector disabled")
            root.check(root.find(content.item,"dashboardInputMute").activeFocus,"focus recovers after hotplug")
            backend.nodes.values=[speaker,headphones,mic]
            backend.defaultAudioSink=speaker
            return root.assertions
        }
        function fullOpen(): void { window.visible=false; dashboard.open() }
        function fullKey(name: string): bool {
            return content.item.events.keyClick(({Tab:Qt.Key_Tab,Backtab:Qt.Key_Backtab,Escape:Qt.Key_Escape})[name],0,0)
        }
        function fullFocus(): void { root.find(dashboard.panel,"dashboardOutputDevices").forceActiveFocus() }
        function fullStatus(): string {
            return JSON.stringify({opened:dashboard.opened,loaded:dashboard.content!==null,
                focus:dashboard.content?dashboard.content.focusTargets().filter(item=>item.activeFocus).map(item=>item.objectName):[]})
        }
        function fullCheck(): int {
            root.check(dashboard.content!==null,"full dashboard loaded")
            const targets=dashboard.content.focusTargets()
            root.check(targets.some(item=>item.objectName==="dashboardInputMute"),"microphone integrated into Tab order")
            root.check(root.find(dashboard.panel,"dashboardMute")!==null,"output integrated")
            return root.assertions
        }
        function resize(width: int): void { window.implicitWidth=width }
        function unload(): void { content.active=false }
        function load(): void { content.active=true }
        function viewTests(): int {
            root.check(content.item.width<=window.width,"card fits viewport")
            root.check(content.item.focusTargets().every(item=>item.width>0),"controls laid out")
            root.check(Services.AudioService.available,"backend recovery")
            return root.assertions
        }
    }
}
