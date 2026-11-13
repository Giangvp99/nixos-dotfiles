    function find(node,name) {
        if(!node) return null
        if(node.objectName===name) return node
        if(node.contentItem) { const result=find(node.contentItem,name); if(result) return result }
        for(const child of (node.children||[])) { const result=find(child,name); if(result) return result }
        return null
    }
    PersistentProperties {
        id: testReloadMemory
        reloadableId: "keybind-test-reload"
        property int generation: 0
        onLoaded: generation++
    }
    TestEvent { id: testEvents }
    IpcHandler {
        target:"keybindTest"
        function status():string {
            const c=keybinds.content
            const surface=find(keybinds.panel,"keybindSurface")
            const list=find(keybinds.panel,"keybindList")
            return JSON.stringify({generation:testReloadMemory.generation,opened:keybinds.opened,loaded:c!==null,loading:c?c.catalog.loading:false,
                error:c?c.catalog.error:"",count:c?c.catalog.entries.length:0,results:c?c.results.length:0,
                query:c?c.searchControl.text:"",searchFocus:c?c.searchControl.activeFocus:false,
                selected:list?list.currentIndex:-1,listFocus:list?list.activeFocus:false,
                process:c?c.catalog.processRunning:false,dashboard:dashboard.opened,launcher:launcher.opened,
                surface:surface?[surface.x,surface.y,surface.width,surface.height]:[],window:[keybinds.panel.width,keybinds.panel.height]})
        }
        function command(program:string,path:string):void { keybinds.bindingCommand=path?[program,path]:[program] }
        function open():void { keybinds.open() }
        function close():void { keybinds.close() }
        function query(text:string):void { keybinds.content.searchControl.text=text }
        function refresh():void { keybinds.content.catalog.refresh() }
        function filter():void { find(keybinds.panel,"keybindWindowFilter").clicked() }
        function key(name:string):bool {
            return testEvents.keyClick(({Escape:Qt.Key_Escape,Tab:Qt.Key_Tab,Backtab:Qt.Key_Backtab,Down:Qt.Key_Down,Up:Qt.Key_Up,Return:Qt.Key_Return,End:Qt.Key_End,Home:Qt.Key_Home})[name],0,0)
        }
        function compact():void {
            keybinds.panel.anchors.right=false; keybinds.panel.anchors.bottom=false
            keybinds.panel.implicitWidth=380; keybinds.panel.implicitHeight=500
        }
        function missingScreen():void {
            keybindMemory.opened=true
            keybindMemory.screenName="missing-output-for-test"
            keybinds.restoreSession(keybindMemory)
            dashboardMemory.opened=true
            dashboardMemory.screenName="missing-output-for-test"
            dashboard.restoreSession(dashboardMemory)
        }
        function dashboardOpen():void { dashboard.open() }
        function dashboardHelp():void { find(dashboard.panel,"dashboardShortcuts").clicked() }
        function launcherOpen():void { launcher.open() }
        function parserTests():int {
            let count=0
            function check(value,message) { if(!value) throw new Error(message); count++ }
            const rows=Bindings.parse(JSON.stringify([
                {modmask:69,key:"Return",description:"Open terminal"},
                {modmask:0,key:"XF86AudioMute",description:"Mute output",locked:true,repeat:true},
                {modmask:4,key:"",keycode:38,release:true,submap:"resize"},
                {modmask:64,key:"H",description:"Previous app"},
                {modmask:64,key:"H",description:"Conflicting duplicate"},
                {modmask:0,key:"",catch_all:true},null,{modmask:-1,key:"bad"},{modmask:0,key:""}]))
            check(rows.length===6,"invalid rows skipped, duplicates retained")
            check(rows.some(row=>row.chord==="Super + Ctrl + Shift + Enter"),"modifier mask")
            check(rows.some(row=>row.chord==="Ctrl + Code 38"&&row.detail.indexOf("resize")>=0&&row.detail.indexOf("release")>=0),"keycode/submap/release")
            check(rows.some(row=>row.chord==="Any key"),"catch all")
            check(rows.some(row=>row.description==="No description provided"),"Lua opaque callbacks not guessed")
            check(Bindings.search(rows,"super enter",false).length===1,"all search terms")
            check(Bindings.search(rows,"xf86",false).length===1,"raw key searchable")
            check(Bindings.search(rows,"",true).length===1,"window category filter")
            let failed=false
            try { Bindings.parse('{}') } catch(error) { failed=true }
            check(failed,"non array rejected")
            return count
        }
    }
