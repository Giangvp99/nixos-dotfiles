    TestEvent { id: layoutKeys }
    property var smallContent: null
    Component { id: smallComponent; DashboardModule.DashboardContent {} }
    function layoutFind(node, name) {
        if (!node) return null
        if (node.objectName === name) return node
        if (node.contentItem) { const item=layoutFind(node.contentItem,name); if (item) return item }
        for (const child of (node.children || [])) { const item=layoutFind(child,name); if (item) return item }
        return null
    }
    QtObject {
        id: layoutAudio
        property var outputs: [0,1,2,3,4].map(index=>({id:index,identifier:index,identity:"Audio device " + index}))
        property var inputs: outputs
        property var sink: outputs[0]
        property var source: outputs[0]
        property bool available: true
        property bool inputAvailable: true
        property bool muted: false
        property bool inputMuted: false
        property real volume: .5
        property real inputVolume: .5
        property int volumePercent: 50
        property int inputVolumePercent: 50
        function deviceLabel(device) { return device ? device.identity : "" }
        function toggleMute() { muted=!muted }
        function toggleInputMute() { inputMuted=!inputMuted }
        function setVolume(value) { volume=value }
        function setInputVolume(value) { inputVolume=value }
        function selectOutput(device) { sink=device }
        function selectInput(device) { source=device }
    }
    QtObject { id: device0; property int identifier: 0; property string identity: "Speaker / player A" }
    QtObject { id: device1; property int identifier: 1; property string identity: "Headset / player B" }
    QtObject { id: device2; property int identifier: 2; property string identity: "Monitor / player C" }
    QtObject { id: device3; property int identifier: 3; property string identity: "Studio / player D" }
    QtObject { id: device4; property int identifier: 4; property string identity: "Wireless / player E" }
    QtObject {
        id: layoutNetwork
        property bool available: true
        property bool enabled: true
        property bool hardwareEnabled: true
        property bool linkConnected: true
        property string connectionIcon: "󰤨"
        property string connectionLabel: "Home wireless"
        property string connectivityText: "Connected · Internet access"
        property string connectionError: ""
        property bool scanning: false
        property int selected: -1
        property QtObject networks: QtObject { property var values: [network0,network1,network2,network3,network4] }
        function startScanning(owner) { scanning=true }
        function stopScanning(owner) { scanning=false }
        function setWifiEnabled(value) { enabled=value }
        function canConnect(network) { return true }
        function networkStatus(network) { return network.connected ? "Connected" : "Available" }
        function connectNetwork(network) { selected=network.identifier }
    }
    component TestNetwork: QtObject {
        property int identifier: 0
        property string name: "Home network " + identifier
        property bool stateChanging: false
        property bool connected: false
        property real signalStrength: .8
    }
    TestNetwork { id: network0; identifier: 0; connected: true }
    TestNetwork { id: network1; identifier: 1 }
    TestNetwork { id: network2; identifier: 2 }
    TestNetwork { id: network3; identifier: 3 }
    TestNetwork { id: network4; identifier: 4 }
    QtObject {
        id: layoutMedia
        property bool available: true
        property var players: [device0,device1,device2,device3,device4]
        property var activePlayer: device0
        property string artwork: ""
        property string trackTitle: "A quiet afternoon"
        property string trackArtist: "Dashboard layout fixture"
        readonly property string playerName: activePlayer.identity
        property bool canToggle: true
        property bool canPrevious: true
        property bool canNext: true
        property bool isPlaying: true
        function label(player) { return player.identity }
        function selectPlayer(player) { activePlayer=player }
        function previous() {}
        function next() {}
        function togglePlaying() { isPlaying=!isPlaying }
    }
    PersistentProperties {
        id: layoutMemory
        reloadableId: "dashboard-layout-test"
        property int generation: 0
        onLoaded: generation++
    }
    IpcHandler {
        target: "layoutTest"
        function inject(): void {
            const c=dashboard.content
            c.audioService=layoutAudio
            c.networkService=layoutNetwork
            c.mediaService=layoutMedia
        }
        function resize(width: int, height: int): void {
            if (smallContent) smallContent.destroy()
            smallContent=smallComponent.createObject(dashboard.content, {width:width,height:height,
                audioService:layoutAudio,networkService:layoutNetwork,mediaService:layoutMedia})
        }
        function selectPage(page: int): void { (smallContent || dashboard.content).selectPage(page) }
        function expand(name: string): bool {
            const item=layoutFind(smallContent || dashboard.content,name)
            if (!item || !item.visible || !item.enabled) return false
            item.clicked()
            return true
        }
        function nextChoices(name: string): bool {
            const card=layoutFind(smallContent || dashboard.content,name)
            function findPager(node) {
                if (!node) return null
                if (node.objectName==="choicePager" && node.visible) return node
                for (const child of (node.children || [])) { const found=findPager(child); if (found) return found }
                return null
            }
            const pager=findPager(card)
            if (!pager) return false
            pager.page=(pager.page+1)%pager.pageCount
            return true
        }
        function focus(name: string): bool {
            const target=(smallContent || dashboard.content).focusTargets().find(item=>item.objectName===name)
            if (!target) return false
            target.forceActiveFocus()
            return target.activeFocus
        }
        function key(name: string): bool {
            return layoutKeys.keyClick(name==="Return" ? Qt.Key_Return : name==="Tab" ? Qt.Key_Tab : Qt.Key_Backtab,0,0)
        }
        function status(): string {
            const c=smallContent || dashboard.content
            if (!c) return JSON.stringify({loaded:false,generation:layoutMemory.generation})
            const targets=c.focusTargets(), cards=[]
            function visit(node) {
                if (!node || !node.visible) return
                if (["dashboardFocus","dashboardCalendarCard","dashboardAudio","dashboardNetworkCard","dashboardNotes","dashboardMedia","dashboardMediaEmpty"].indexOf(node.objectName)>=0) {
                    const p=node.mapToItem(c,0,0)
                    cards.push({name:node.objectName,x:p.x,y:p.y,w:node.width,h:node.height,natural:node.implicitHeight})
                }
                for (const child of (node.children || [])) visit(child)
            }
            visit(c)
            return JSON.stringify({loaded:true,generation:layoutMemory.generation,overview:c.overview,page:c.page,
                width:c.width,height:c.height,cards:cards,scroll:layoutFind(dashboard.panel,"dashboardScroll")!==null,
                fits:targets.every(item=>{const p=item.mapToItem(c,0,0);return p.x>=-1 && p.y>=-1 && p.x+item.width<=c.width+1 && p.y+item.height<=c.height+1}),
                targets:targets.map(item=>item.objectName),focus:targets.filter(item=>item.activeFocus).map(item=>item.objectName),
                scanning:layoutNetwork.scanning,selectedNetwork:layoutNetwork.selected,selectedOutput:layoutAudio.sink.identifier,
                selectedPlayer:layoutMedia.activePlayer.identifier})
        }
    }
