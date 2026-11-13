import QtQuick
import QtQuick.Layouts
import QtTest
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Networking
import "../modules/bar/widgets" as Widgets
import "../modules/bar/popups" as Popups
import "../services" as Services
import "../components" as Components
import "../config" as Config

ShellRoot {
    id: root
    readonly property alias fixtureMonitor: monitor
    TestEvent { id: events }
    property int singleCount: 0
    property int baselineCount: 0
    property int doubleCount: 0
    property double now: Date.now()
    function find(node,name) {
        if (!node) return null
        if (node.objectName===name) return node
        if (node.contentItem) { const item=find(node.contentItem,name); if (item) return item }
        for (const child of (node.children||[])) { const item=find(child,name); if (item) return item }
        return null
    }
    QtObject {
        id: monitor
        property bool networkAvailable: true
        property string networkInterface: "test-lan"
        property real download: 1024
        property real upload: 2048
        property bool cpuAvailable: true
        property bool memoryAvailable: true
        property int cpuPercent: 42
        property int memoryPercent: 50
        property var memory: ({used:1073741824,total:2147483648,percent:50})
        property int historyWindowMs: 180000
        property var cpuHistory: [{at:root.now-12000,value:10},{at:root.now-10000,value:20},{at:root.now-8000,value:null},{at:root.now-6000,value:40},{at:root.now-4000,value:50}]
        property var memoryHistory: [{at:root.now-10000,value:30},{at:root.now-8000,value:40},{at:root.now-6000,value:50}]
    }
    QtObject {
        id: network
        property string kind: "lan"
        property bool available: false
        property bool enabled: true
        property bool hardwareEnabled: true
        property bool linkConnected: true
        property bool statusAvailable: true
        property string connectionLabel: "Ethernet · test-lan"
        property string connectivityText: "Internet available"
        property string connectionIcon: "󰈀"
        property string connectionError: ""
        property QtObject networks: QtObject { property var values: [] }
        function connectionKind(name) { return kind }
        function iconForInterface(name) { return kind==="lan" ? "󰈀" : "󰤨" }
        function startScanning(owner) {}
        function stopScanning(owner) {}
        function setWifiEnabled(value) {}
    }
    QtObject {
        id: details
        property bool busy: false
        property string error: ""
        property var details: ({"GENERAL.TYPE":"ethernet","GENERAL.CONNECTION":"Home <b>LAN</b>","IP4.ADDRESS":"192.0.2.1/24","IP4.GATEWAY":"192.0.2.254","IP4.DNS":"192.0.2.53"})
        property int requests: 0
        function refresh() { requests++ }
    }
    QtObject {
        id: audio
        property bool available: true
        property bool inputAvailable: true
        property bool muted: false
        property bool inputMuted: false
        property real volume: .5
        property real inputVolume: .4
        readonly property int volumePercent: Math.round(audio.volume*100)
        readonly property int inputVolumePercent: Math.round(inputVolume*100)
        property var outputs: [{id:1,name:"Output one"},{id:2,name:"Output two"},{id:3,name:"Output three"}]
        property var inputs: [{id:4,name:"Microphone one"}]
        property var sink: outputs[0]
        property var source: inputs[0]
        property int toggles: 0
        property int wheels: 0
        function deviceLabel(device) { return device ? device.name : "" }
        function toggleMute() { toggles++; muted=!muted }
        function toggleInputMute() { inputMuted=!inputMuted }
        function setVolume(value) { audio.volume=value }
        function setInputVolume(value) { inputVolume=value }
        function increaseVolume() { audio.volume=Math.min(1,audio.volume+.05); wheels++ }
        function decreaseVolume() { audio.volume=Math.max(0,audio.volume-.05); wheels++ }
        function selectOutput(value) { sink=value }
        function selectInput(value) { source=value }
    }
    Services.NetworkDetails { id: reader }
    QtObject {
        id: backend
        property bool wifiHardwareEnabled: true
        property bool wifiEnabled: true
        property bool canCheckConnectivity: false
        property int connectivity: NetworkConnectivity.Full
        property QtObject devices: QtObject {
            property var values: [{name:"test-lan",type:DeviceType.Wired,connected:true},
                {name:"test-wifi",type:DeviceType.Wifi,connected:false},
                {name:"test-tunnel",type:DeviceType.Unknown,connected:false}]
        }
    }
    Component.onCompleted: {
        net.detailsPopup.detailsReader=details
        Services.NetworkService.backend=backend
        Services.SystemMonitor.sampler.stop()
        reader.command.command=["printf","GENERAL.TYPE:ethernet\nGENERAL.CONNECTION:Test: profile\nIP4.ADDRESS[1]:192.0.2.1/24\nIP4.DNS[1]:192.0.2.53\nIP4.DNS[2]:192.0.2.54\n"]
    }
    PanelWindow {
        id: window
        anchors.top: true
        implicitWidth: 500
        implicitHeight: 40
        exclusionMode: ExclusionMode.Ignore
        focusable: true
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        color: "transparent"
        RowLayout {
            anchors.centerIn: parent
            Widgets.NetworkSpeed { id: net; monitor: root.fixtureMonitor; networkService: network }
            Widgets.ResourceUsage { id: cpu; monitor: root.fixtureMonitor }
            Widgets.Audio { id: volume; audioService: audio }
            Rectangle {
                id: baseline
                implicitWidth: 70
                implicitHeight: 28
                color: "gray"
                MouseArea { anchors.fill: parent; onClicked: root.baselineCount++ }
            }
            Components.IconButton { id: ordinary; text:"Normal"; onClicked: root.singleCount++ }
            Components.IconButton { id: gesture; text:"Gesture"; doubleClickEnabled:true; onClicked: root.singleCount++; onDoubleClicked: root.doubleCount++ }
        }
    }
    IpcHandler {
        target: "widgetDetailsTest"
        function status(): string {
            const chart=root.find(cpu.detailsPopup.body,"cpuHistoryChart")
            return JSON.stringify({network:net.detailsPopup.visible,resources:cpu.detailsPopup.visible,audio:volume.detailsPopup.visible,
                networkLoaded:net.detailsPopup.body!==null,resourcesLoaded:cpu.detailsPopup.body!==null,audioLoaded:volume.detailsPopup.body!==null,
                netIcon:net.connectionIcon,netKind:net.connectionKind,netWidth:net.width,cpuWidth:cpu.width,volumeWidth:volume.width,
                padding:[net.horizontalPadding,cpu.horizontalPadding,volume.horizontalPadding,ordinary.horizontalPadding],
                segments:chart ? chart.segments : -1,muted:audio.muted,toggles:audio.toggles,wheels:audio.wheels,
                singles:root.singleCount,baseline:root.baselineCount,doubles:root.doubleCount,pending:volume.clickPending,
                doubleInterval:Qt.styleHints.mouseDoubleClickInterval,readerBusy:reader.busy,readerError:reader.error,readerDetails:reader.details,
                refreshes:details.requests,focus:Popups.PopupState.current ? Popups.PopupState.current.focusTargets().filter(item=>item.activeFocus).map(item=>item.objectName) : []})
        }
        function click(name: string, doubleClick: bool): bool {
            const item=name==="audio" ? volume : name==="network" ? net : name==="cpu" ? cpu : name==="ordinary" ? ordinary : name==="baseline" ? baseline : gesture
            return doubleClick ? events.mouseDoubleClickSequence(item,item.width/2,item.height/2,Qt.LeftButton,0,0)
                : events.mouseClick(item,item.width/2,item.height/2,Qt.LeftButton,0,0)
        }
        function close(): void { if (Popups.PopupState.current) Popups.PopupState.current.close(false) }
        function key(name: string): bool { return events.keyClick(name==="Escape" ? Qt.Key_Escape : name==="Tab" ? Qt.Key_Tab : Qt.Key_Return,0,0) }
        function focusAudio(): void { volume.forceActiveFocus() }
        function wheel(): bool { return events.mouseWheel(volume,volume.width/2,volume.height/2,Qt.NoButton,Qt.NoModifier,0,120,0) }
        function kind(value: string): void { network.kind=value }
        function rates(value: real): void { monitor.download=value;monitor.upload=value }
        function gap(): void { monitor.cpuHistory=monitor.cpuHistory.concat([{at:root.now+8000,value:60}]) }
        function uiClick(name: string): bool {
            const popup=Popups.PopupState.current, item=popup ? root.find(popup.body,name) : null
            if (!item || !item.enabled) return false
            item.clicked();return true
        }
        function read(mode: string): void {
            reader.active=false
            if (mode==="failure") reader.command.command=["false"]
            else if (mode==="timeout") reader.command.command=["sleep","8"]
            reader.interfaceName="test-lan"
            reader.active=true
        }
        function units(): int {
            let count=0
            function check(value) { if (!value) throw new Error("Widget details assertion "+count);count++ }
            const service=Services.NetworkService
            check(service.connectionKind("test-lan")==="lan")
            check(service.connectionKind("test-wifi")==="wifi")
            check(service.connectionKind("missing")==="network")
            const monitor=Services.SystemMonitor, now=Date.now()
            let history=[]
            for (let i=0;i<120;i++) history=monitor.appendHistory(history,i%100,now+i*2000)
            check(history.length===90)
            history=monitor.appendHistory(history,NaN,now+240000)
            check(history[history.length-1].value===null)
            check(monitor.appendHistory(history,50,now-10000).length===1)
            check(monitor.restoreHistory('not json').length===0)
            check(monitor.restoreHistory(JSON.stringify([{at:now,value:101}])).length===0)
            check(monitor.restoreHistory(JSON.stringify([{at:now-190000,value:50}])).length===0)
            check(monitor.restoreHistory(JSON.stringify([{at:now,value:40}])).length===1)
            const parsed=reader.parse("GENERAL.CONNECTION:Office: LAN\nIP4.DNS[1]:192.0.2.1\nIP4.DNS[2]:192.0.2.2\nIP4.GATEWAY:--\n")
            check(parsed["GENERAL.CONNECTION"]==="Office: LAN")
            check(parsed["IP4.DNS"]==="192.0.2.1, 192.0.2.2")
            check(!parsed["IP4.GATEWAY"])
            return count
        }
    }
}
