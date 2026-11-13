    TestEvent { id: testKeys }
    property var narrowContent: null
    Component { id: narrowComponent; DashboardModule.DashboardContent {} }
    PersistentProperties {
        id: testState
        reloadableId: "focus-notes-test"
        property bool dnd: false
        property int revision: 0
        property int generation: 0
        onDndChanged: revision++
        onLoaded: generation++
    }
    QtObject {
        id: fakeNotifications
        property bool available: true
        readonly property bool dnd: testState.dnd
        readonly property int dndRevision: testState.revision
        function toggleDnd() { testState.dnd = !testState.dnd }
    }
    QtObject {
        id: fakeMode
        property string lastMode: ""
        function activate(mode) { lastMode=mode; return true }
    }
    Component.onCompleted: {
        Services.FocusSession.notificationState = fakeNotifications
        Services.FocusSession.modeService = fakeMode
    }
    IpcHandler {
        target: "focusNotesTest"
        function focusControl(name: string): bool {
            const item=dashboard.content.focusTargets().find(item => item.objectName===name)
            if (!item) return false
            item.forceActiveFocus()
            dashboard.content.focusRequested(item)
            return item.activeFocus
        }
        function key(name: string): bool {
            if (name === "Return") return testKeys.keyClick(Qt.Key_Return,0,0)
            if (name === "Tab") return testKeys.keyClick(Qt.Key_Tab,0,0)
            if (name === "Save") return testKeys.keyClick(Qt.Key_S,Qt.ControlModifier,0)
            return false
        }
        function uiText(value: string): void {
            const editor=dashboard.content.focusTargets().find(item => item.objectName==="quickNotesEditor")
            editor.text=value
            editor.cursorPosition=editor.length
        }
        function uiLayout(): string {
            const content=narrowContent || dashboard.content, targets=content.focusTargets()
            return JSON.stringify({width:content.width,
                fits:targets.every(item => {
                    const point=item.mapToItem(content,0,0)
                    return point.x>=-1 && point.x+item.width<=content.width+1
                }), focus:dashboard.content.focusTargets().filter(item => item.activeFocus).map(item => item.objectName)})
        }
        function automaticSave(): void { Services.NotesService.save() }
        function narrow(): bool {
            narrowContent=narrowComponent.createObject(dashboard.content,{width:340,height:600,page:3})
            return narrowContent.focusTargets().some(item => item.objectName==="quickNotesEditor")
        }
        function status(): string {
            const f=Services.FocusSession, n=Services.NotesService
            return JSON.stringify({ready:f.ready && n.ready, status:f.status, remaining:f.remainingSeconds,
                timer:f.timerRunning, owned:f.managesDnd, dnd:fakeNotifications.dnd,
                text:n.text, dirty:n.dirty, writing:n.writing, error:n.error, path:n.storagePath,
                generation:testState.generation, mode:fakeMode.lastMode})
        }
        function start(seconds: int, quiet: bool, mode: string): bool { return Services.FocusSession.start(seconds,quiet,mode) }
        function pause(): void { Services.FocusSession.pause() }
        function resume(): void { Services.FocusSession.resume() }
        function stop(): void { Services.FocusSession.stop() }
        function toggle(): void { fakeNotifications.toggleDnd() }
        function expire(): void { Services.FocusSession.tick(Date.now()+20000000) }
        function edit(value: string): void { Services.NotesService.update(value) }
        function save(): void { Services.NotesService.retry() }
    }
