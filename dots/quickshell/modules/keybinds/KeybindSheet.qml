pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../../components" as Components
import "../../config" as Config
import "../../services" as Services

Scope {
    id:root
    property bool opened:false
    property var bindingCommand:["hyprctl","-j","binds"]
    property string shortcutAppId:"quickshell"
    property var sessionMemory:null
    readonly property alias panel:window
    readonly property alias content:loader.item
    readonly property alias returnFocusItem:focusReturn.origin
    readonly property var targetScreen: route.screen
    Components.OverlayScreen { id: route; active: root.opened; onRemoved: root.close(false) }
    signal opening()
    onOpenedChanged:if(sessionMemory) { sessionMemory.opened=opened; sessionMemory.screenName=route.screenName }
    function restoreSession(memory) {
        const wasOpen=memory.opened
        sessionMemory=memory
        if (wasOpen) Qt.callLater(function() {
            const preferred=Services.ScreenService.screens.find(screen => screen.name === memory.screenName)
            if (memory.screenName && !preferred) { memory.opened=false; return }
            root.open(null, preferred)
        })
    }
    function open(origin, preferredScreen) { if (!opened) route.capture(origin, preferredScreen); opening(); focusReturn.remember(origin); opened=true; Qt.callLater(root.focusSearch) }
    function close(restore=true) { opened=false; focusReturn.finish(restore) }
    function toggle() { if(opened) close(); else open() }
    function focusSearch() { if(opened&&loader.item) loader.item.searchControl.forceActiveFocus() }
    Components.OverlayFocus { id:focusReturn; opened:root.opened; windowVisible:window.backingWindowVisible }
    GlobalShortcut {
        appid:root.shortcutAppId
        name:"keybinds"
        description:"Show keyboard shortcuts"
        onPressed:root.toggle()
    }
    IpcHandler {
        target:"keybinds"
        function open():void { root.open() }
        function close():void { root.close() }
        function toggle():void { root.toggle() }
        function status():string {
            return JSON.stringify({opened:root.opened,loaded:loader.item!==null,
                loading:loader.item?loader.item.catalog.loading:false,
                count:loader.item?loader.item.catalog.entries.length:0,error:loader.item?loader.item.catalog.error:""})
        }
    }
    PanelWindow {
        id:window
        screen:route.screen
        visible:root.opened && route.valid
        focusable:true
        aboveWindows:true
        exclusionMode:ExclusionMode.Ignore
        anchors { top:true;bottom:true;left:true;right:true }
        color:"transparent"
        onBackingWindowVisibleChanged:if(backingWindowVisible) Qt.callLater(root.focusSearch)
        Rectangle { anchors.fill:parent; color:Config.Theme.overlay; MouseArea { anchors.fill:parent; onClicked:root.close(false) } }
        Components.Surface {
            id:surface
            objectName:"keybindSurface"
            panel:true
            radius:Config.Theme.radiusLarge
            anchors.centerIn:parent
            width:Math.max(0,Math.min(Config.Config.keybindWidth,parent.width-Config.Theme.panelPadding*2))
            height:Math.max(0,Math.min(Config.Config.keybindHeight,parent.height-Config.Theme.panelPadding*2))
            MouseArea { anchors.fill:parent }
            Loader {
                id:loader
                anchors.fill:parent
                anchors.margins:Config.Theme.panelPadding
                active:root.opened
                onLoaded:Qt.callLater(root.focusSearch)
                sourceComponent:KeybindContent {
                    catalogCommand:root.bindingCommand
                    contextLabel: {
                        const ws=Services.ScreenService.workspaceFor(window.screen)
                        const name=ws?ws.name:""
                        const mode=Services.ModeService.idFromWorkspace(name)
                        return (Services.ModeService.name(mode)||"Desktop")+(name?" · "+name:"")
                    }
                    onCloseRequested:root.close()
                }
            }
        }
        Components.OverlayMotion { targetItem:surface; shown:window.backingWindowVisible&&root.opened }
    }
}
