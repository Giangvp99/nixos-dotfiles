import QtQuick
import QtTest
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Networking
import "../modules/dashboard" as Dashboard
import "../modules/bar/popups" as Popups
import "../services" as Services

ShellRoot {
    id: root
    property bool mockMode: false
    property int assertions: 0
    property int settingsRequests: 0
    TestEvent { id: events }
    function check(value, message) { if (!value) throw new Error(message); assertions++ }
    function find(node, name) {
        if(!node) return null
        if(node.objectName===name) return node
        if(node.contentItem) { const result=find(node.contentItem,name); if(result) return result }
        for(const child of (node.children||[])) { const result=find(child,name); if(result) return result }
        return null
    }
    component Network: QtObject {
        property string name: "Saved network"
        property bool connected: false
        property bool known: true
        property bool stateChanging: false
        property int security: WifiSecurityType.Wpa2Psk
        property real signalStrength: 0.85
        property int attempts: 0
        signal connectionFailed(int reason)
        function connect() { attempts++; stateChanging=true }
        function disconnect() { connected=false }
    }
    Network { id: saved }
    Network { id: open; name: "Cafe <b>plain text</b>"; known:false; security:WifiSecurityType.Open }
    Network { id: locked; name:"Protected network"; known:false }
    Network { id: busy; name:"Connecting network"; stateChanging:true }
    QtObject {
        id: adapter
        property int type: DeviceType.Wifi
        property string name: "test-wifi"
        property bool connected: false
        property bool scannerEnabled: false
        property ScriptModel networks: ScriptModel { values:[saved,open,locked,busy] }
    }
    QtObject {
        id: replacement
        property int type: DeviceType.Wifi
        property string name: "replacement-wifi"
        property bool connected: false
        property bool scannerEnabled: false
        property ScriptModel networks: ScriptModel { values:[] }
    }
    QtObject {
        id: wired
        property int type: DeviceType.Wired
        property string name: "test-ethernet"
        property bool connected: true
    }
    QtObject {
        id: backend
        property QtObject devices: QtObject { property var values:[adapter,wired] }
        property bool wifiEnabled: true
        property bool wifiHardwareEnabled: true
        property bool canCheckConnectivity: false
        property int connectivity: NetworkConnectivity.Unknown
    }
    PanelWindow {
        id: window
        implicitWidth: 420
        implicitHeight: 850
        focusable: true
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        Loader {
            id: loader
            width: parent.width
            active: true
            sourceComponent: Dashboard.NetworkCard {
                settingsAvailable:true
                onSettingsRequested: root.settingsRequests++
            }
        }
    }
    Popups.WifiPopup { id: popup; anchorItem:loader.item }
    Dashboard.Dashboard { id: dashboard }
    QtObject {
        id: notifications
        property bool available: true
        property bool dnd: false
        property int unreadCount: 0
        function toggleDnd() { dnd=!dnd }
    }
    IpcHandler {
        target:"networkTest"
        function status(): string {
            const s=Services.NetworkService
            return JSON.stringify({loaded:loader.item!==null,available:s.available,enabled:s.enabled,
                scanning:adapter.scannerEnabled,owners:s.scanOwners,networks:s.networks.values.length,
                label:s.connectionLabel,detail:s.connectivityText,assertions:root.assertions,
                focus:loader.item?loader.item.focusTargets().filter(item=>item.activeFocus).map(item=>item.objectName):[],
                width:loader.item?loader.item.width:0})
        }
        function mocks(): void { Services.NetworkService.backend=backend; root.mockMode=true }
        function serviceTests(): int {
            root.check(root.mockMode,"mock backend required")
            const s=Services.NetworkService
            root.check(s.connectionLabel==="Ethernet · test-ethernet" && s.connectivityText==="Link connected","no false internet inference")
            s.startScanning("one"); s.startScanning("one"); s.startScanning("two")
            root.check(adapter.scannerEnabled && s.scanOwners.length===2,"idempotent scan ownership")
            s.stopScanning("one"); root.check(adapter.scannerEnabled,"other owner keeps scanning")
            backend.wifiEnabled=false; root.check(!adapter.scannerEnabled,"radio off stops scan")
            backend.wifiEnabled=true; root.check(adapter.scannerEnabled,"radio on resumes requested scan")
            backend.devices.values=[replacement,wired]
            root.check(!adapter.scannerEnabled && replacement.scannerEnabled,"scan follows replacement adapter")
            backend.devices.values=[wired]
            root.check(!replacement.scannerEnabled && !s.available,"unplug stops scan")
            backend.devices.values=[adapter,wired]
            root.check(adapter.scannerEnabled,"reattach resumes requested scan")
            s.stopScanning("two"); root.check(!adapter.scannerEnabled,"last owner stops scan")
            s.connectNetwork(locked); s.connectNetwork(busy); s.connectNetwork(null)
            root.check(locked.attempts===0 && busy.attempts===0,"protected unsaved/busy networks rejected")
            s.connectNetwork(saved); s.connectNetwork(saved)
            root.check(saved.attempts===1,"saved network connects; no duplicate while busy")
            saved.connectionFailed(0)
            root.check(s.connectionError.length>0,"failure exposed")
            saved.stateChanging=false; saved.connected=true
            root.check(s.connectionError==="","success clears error")
            s.connectNetwork(saved); root.check(saved.attempts===1,"already connected ignored")
            s.disconnect(); root.check(!saved.connected,"disconnect current network")
            s.connectNetwork(open); root.check(open.attempts===1,"open network connects")
            open.stateChanging=false
            backend.wifiHardwareEnabled=false
            s.setWifiEnabled(false); root.check(backend.wifiEnabled,"hardware blocked prevents action")
            backend.wifiHardwareEnabled=true
            const stale=saved
            adapter.networks.values=[open,locked,busy]
            s.connectNetwork(stale); root.check(saved.attempts===1,"stale network rejected")
            adapter.networks.values=[saved,open,locked,busy]
            return root.assertions
        }
        function click(name:string):void { root.find(loader.item,name).clicked() }
        function focus(name:string):void { root.find(loader.item,name).forceActiveFocus() }
        function key(name:string):bool {
            return events.keyClick(({Return:Qt.Key_Return,Escape:Qt.Key_Escape,Tab:Qt.Key_Tab,Backtab:Qt.Key_Backtab})[name],0,0)
        }
        function uiCheck(stage:string):int {
            root.check(root.mockMode,"mock backend required")
            if(stage==="expanded") {
                root.check(adapter.scannerEnabled,"expanded starts scanner")
                root.check(root.find(loader.item,"dashboardNetwork_0").enabled,"saved row enabled")
                root.check(!root.find(loader.item,"dashboardNetwork_2").enabled,"credential row disabled")
                root.check(!root.find(loader.item,"dashboardNetwork_3").enabled,"busy row disabled")
            }
            if(stage==="selection") root.check(saved.attempts===2,"Enter connects saved row")
            if(stage==="escape") root.check(!adapter.scannerEnabled && root.find(loader.item,"dashboardNetworks").activeFocus,"Escape closes detail and restores focus")
            if(stage==="settings") root.check(root.settingsRequests===1,"settings action routed")
            if(stage==="off") root.check(!backend.wifiEnabled && !adapter.scannerEnabled,"toggle switches off and releases scanner")
            if(stage==="lost") root.check(!Services.NetworkService.available && !adapter.scannerEnabled,"missing adapter state")
            return root.assertions
        }
        function clearBusy():void { saved.stateChanging=false }
        function loseAdapter():void { backend.devices.values=[wired] }
        function restoreAdapter():void { backend.devices.values=[adapter,wired] }
        function resize(width:int):void { window.implicitWidth=width }
        function unload():void { loader.active=false }
        function load():void { loader.active=true }
        function fullOpen():void { window.visible=false; dashboard.open() }
        function fullMocks():void { dashboard.content.notificationState=notifications }
        function fullClick(name:string):void { root.find(dashboard.panel,name).clicked() }
        function fullFocus(name:string):void { root.find(dashboard.panel,name).forceActiveFocus() }
        function fullStatus():string {
            return JSON.stringify({opened:dashboard.opened,loaded:dashboard.content!==null,
                owners:Services.NetworkService.scanOwners,
                focus:dashboard.content?dashboard.content.focusTargets().filter(item=>item.activeFocus).map(item=>item.objectName):[]})
        }
        function fullCheck():int {
            root.check(dashboard.content!==null,"full dashboard loaded")
            root.check(notifications.dnd && root.find(dashboard.panel,"dashboardDnd").active,"DND shared toggle state")
            root.check(dashboard.content.focusTargets().some(item=>item.objectName==="dashboardNetwork_0"),"network rows integrated into focus order")
            return root.assertions
        }
        function popupOpen():void { popup.open() }
        function popupClose():void { popup.close(false) }
        function popupCheck():int {
            root.check(popup.visible && Services.NetworkService.scanOwners.some(owner=>owner.startsWith("wifi-popup:")),"popup registers scanner owner")
            return root.assertions
        }
    }
}
