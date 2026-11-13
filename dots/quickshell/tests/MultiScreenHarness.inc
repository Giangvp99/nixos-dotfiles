    function findScreenItem(node,name) {
        if(!node) return null
        if(node.objectName===name) return node
        if(node.contentItem) { const result=findScreenItem(node.contentItem,name); if(result) return result }
        for(const child of (node.children||[])) { const result=findScreenItem(child,name); if(result) return result }
        return null
    }
    function testBar(name) { return bars.instances.find(bar=>bar.screen&&bar.screen.name===name)||null }
    PersistentProperties {
        id: screenTestMemory
        reloadableId:"screen-test-generation"
        property int generation:0
        onLoaded:generation++
    }
    QtObject {
        id: testAudio
        property bool available:true
        property QtObject sink:QtObject {}
        property var source:null
        property int volumePercent:40
        property bool muted:false
        property bool inputAvailable:false
        property int inputVolumePercent:0
        property bool inputMuted:false
        function deviceLabel(node) { return "Screen test audio" }
    }
    IpcHandler {
        target:"screenTest"
        function status():string {
            function overlay(owner,surfaceName) {
                const panel=owner.panel
                const surface=surfaceName?findScreenItem(panel,surfaceName):null
                return {opened:owner.opened,screen:owner.targetScreen?owner.targetScreen.name:"",
                    panelScreen:panel.screen?panel.screen.name:"",size:[panel.width,panel.height],
                    surface:surface?[surface.x,surface.y,surface.width,surface.height]:[]}
            }
            const popup=BarPopups.PopupState.current
            return JSON.stringify({workspaces:Services.HyprlandService.workspaces.values.map(ws=>({name:ws.name,monitor:ws.monitor?ws.monitor.name:""})),
                minimized:Services.HyprlandService.minimizedWorkspace?Services.HyprlandService.minimizedWorkspace.name:"",
                clients:Hyprland.toplevels.values.map(item=>({address:item.address,workspace:item.workspace?item.workspace.name:"",ipc:item.lastIpcObject?{workspace:item.lastIpcObject.workspace,tags:item.lastIpcObject.tags,monitor:item.lastIpcObject.monitor}:null})),
                generation:screenTestMemory.generation,focused:Services.ScreenService.focusedScreen?Services.ScreenService.focusedScreen.name:"",
                bars:bars.instances.map(bar=>{
                    const apps=findScreenItem(bar,"barRunningApps")
                    const mode=findScreenItem(bar,"barModeIndicator")
                    return {screen:bar.screen?bar.screen.name:"",workspace:bar.workspace?bar.workspace.name:"",
                        mode:mode?mode.modeId:"",width:bar.width,apps:apps?apps.model.values.map(window=>window.address):[]}
                }),dashboard:overlay(dashboard,"dashboardSurface"),launcher:overlay(launcher,"launcherSurface"),
                keybinds:overlay(keybinds,"keybindSurface"),
                popup:popup?{visible:popup.visible,screen:popup.screen?popup.screen.name:"",anchor:popup.anchorScreen?popup.anchorScreen.name:"",size:[popup.width,popup.height]}:null,
                centers:Services.NotificationState.centers.map(center=>({screen:center.anchorScreen?center.anchorScreen.name:"",visible:center.visible})),
                centerOpen:Services.NotificationState.centerOpen,
                osd:{shown:audioOsd.feedback.shown,screen:audioOsd.targetScreen?audioOsd.targetScreen.name:"",visible:audioOsd.panel.visible}})
        }
        function open(which:string):void {
            if(which==="dashboard") dashboard.open()
            else if(which==="launcher") launcher.open()
            else if(which==="keybinds") keybinds.open()
        }
        function closeAll():void {
            dashboard.close(false);launcher.close(false);keybinds.close(false)
            if(BarPopups.PopupState.current) BarPopups.PopupState.current.close(false)
            audioOsd.feedback.hide()
        }
        function dashboardFromBar(screen:string):void { findScreenItem(testBar(screen),"Dashboard").clicked() }
        function date(screen:string):void { findScreenItem(testBar(screen),"barDate").clicked() }
        function center(screen:string):void {
            const target=Services.NotificationState.centerForScreen(Services.ScreenService.screens.find(item=>item.name===screen))
            if(target) target.open()
        }
        function help():void { findScreenItem(dashboard.panel,"dashboardShortcuts").clicked() }
        function launcherFromDashboard():void { findScreenItem(dashboard.panel,"dashboardAllApps").clicked() }
        function osd(value:int):void {
            audioOsd.audioService=testAudio
            audioOsd.timeout=6000
            Qt.callLater(function(){testAudio.volumePercent=value})
        }
    }
