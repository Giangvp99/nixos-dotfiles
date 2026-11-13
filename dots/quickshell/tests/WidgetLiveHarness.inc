    PersistentProperties {
        id: widgetLiveMemory
        reloadableId: "widget-live-generation"
        property int generation: 0
        onLoaded: generation++
    }
    function widgetFind(node,name) {
        if (!node) return null
        if (node.objectName===name) return node
        if (node.contentItem) { const item=widgetFind(node.contentItem,name); if (item) return item }
        for (const child of (node.children||[])) { const item=widgetFind(child,name); if (item) return item }
        return null
    }
    IpcHandler {
        target: "widgetLiveTest"
        function open(name: string): void {
            const bar=bars.instances.find(bar=>bar.screen && bar.screen.name==="Virtual-1")
            widgetFind(bar,name).clicked()
        }
        function close(): void { if (BarPopups.PopupState.current) BarPopups.PopupState.current.close(false) }
        function status(): string {
            const popup=BarPopups.PopupState.current, m=Services.SystemMonitor
            const controls=popup && popup.focusTargets ? popup.focusTargets() : []
            return JSON.stringify({generation:widgetLiveMemory.generation,cpu:m.cpuHistory,memory:m.memoryHistory,
                popup:popup ? popup.title : "",loaded:popup ? popup.body!==null : false,
                fits:controls.every(item=>{const p=item.mapToItem(popup.contentItem,0,0);return p.x>=0 && p.y>=0 && p.x+item.width<=popup.width+1 && p.y+item.height<=popup.height+1}),
                readDone:popup && popup.detailsReader ? !popup.detailsReader.busy : true,
                readError:popup && popup.detailsReader ? popup.detailsReader.error : "",
                interfaceName:m.networkInterface,kind:Services.NetworkService.connectionKind(m.networkInterface),
                audio:{volume:Services.AudioService.volume,muted:Services.AudioService.muted},wifi:Services.NetworkService.enabled})
        }
    }
