import QtQuick
import QtTest
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../modules/osd" as Osd
import "../services" as Services
import "../config" as Config

ShellRoot {
    id: root
    property int presentations: 0
    component Node: QtObject {
        property bool ready: true
        property string description: "Fixture speaker"
        property string name: "fixture-speaker"
        property string nickname: ""
        property int type: PwNodeType.AudioSink
        property bool isStream: false
        property bool isSink: true
        property QtObject audio: QtObject { property real volume: 0.4; property bool muted: false }
    }
    Node { id: speaker }
    Node { id: replacement; description:"Replacement <b>plain text</b>" }
    Node { id: mic; description:"Fixture microphone"; isSink:false; type:PwNodeType.AudioSource }
    QtObject {
        id: backend
        property bool ready: true
        property var defaultAudioSink: speaker
        property var defaultAudioSource: mic
        property ScriptModel nodes: ScriptModel { values:[speaker,replacement,mic] }
        property var preferredDefaultAudioSink: null
        property var preferredDefaultAudioSource: null
    }
    Component.onCompleted: Services.AudioService.backend=backend
    Osd.AudioOsd { id: osd; timeout:1200 }
    Connections {
        target:osd.feedback
        function onPresented() { root.presentations++ }
    }
    TestEvent { id: events }
    PanelWindow {
        id: inputWindow
        implicitWidth: 420
        implicitHeight: 60
        anchors.top: true
        margins.top: 64
        focusable: true
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        color: "#1e1e2e"
        TextInput {
            id: textInput
            objectName:"osdFixtureInput"
            anchors.fill:parent
            color:"white"
            text:""
            focus:true
        }
    }
    IpcHandler {
        target:"osdTest"
        function status():string {
            const f=osd.feedback, p=osd.panel
            return JSON.stringify({shown:f.shown,visible:p.visible,channel:f.channel,percent:f.percent,muted:f.muted,
                timer:f.timerRunning,presentations:root.presentations,focus:textInput.activeFocus,text:textInput.text,
                focusable:p.focusable,mask:[p.mask.width,p.mask.height],width:p.width,height:p.height,
                screen:p.screen?p.screen.name:"",motion:Config.Animations.reducedMotion})
        }
        function change(channel:string,volume:int,muted:bool):void {
            const node=channel==="input"?backend.defaultAudioSource:backend.defaultAudioSink
            node.audio.volume=volume/100
            node.audio.muted=muted
        }
        function replace():void { backend.defaultAudioSink=replacement }
        function unavailable():void { backend.defaultAudioSink=null }
        function recover():void { backend.defaultAudioSink=speaker }
        function backendReady(ready:bool):void { backend.ready=ready }
        function nodeReady(ready:bool):void { speaker.ready=ready }
        function enabled(value:bool):void { osd.enabled=value }
        function reduced(value:bool):void { Config.Animations.reducedMotion=value }
        function inputFocus():void { textInput.forceActiveFocus() }
        function key():bool { return events.keyClick(Qt.Key_A,0,0) }
        function overAmplified():void { speaker.audio.volume=1.25 }
        function nativeStatus():string {
            return JSON.stringify({available:Services.AudioService.available,input:Services.AudioService.inputAvailable})
        }
    }
}
