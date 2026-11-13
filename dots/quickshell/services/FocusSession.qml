pragma Singleton
import QtQuick

QtObject {
    id: root
    property var memory: null
    property var notificationState: NotificationState
    property var modeService: ModeService
    property int expectedDndRevision: -1
    property bool restoring: false
    property string error: ""
    readonly property bool ready: memory !== null
    readonly property string status: memory ? memory.status : "idle"
    readonly property bool active: status === "running" || status === "paused"
    readonly property int remainingSeconds: memory ? memory.remainingSeconds : 1500
    readonly property int durationSeconds: memory ? memory.durationSeconds : 1500
    readonly property string modeId: memory ? memory.modeId : ""
    readonly property bool managesDnd: Boolean(memory && memory.managesDnd)
    readonly property bool timerRunning: clock.running
    readonly property string clockText: Math.floor(remainingSeconds/60) + ":" + String(remainingSeconds%60).padStart(2,"0")
    signal completed()

    function attachMemory(value) {
        restoring=true
        memory=value
        expectedDndRevision=notificationState.dndRevision
        if (memory.managesDnd && (!active || !notificationState.dnd)) memory.managesDnd=false
        restoring=false
        tick(Date.now())
    }
    function start(seconds, quiet, requestedMode) {
        if (!ready || active || !Number.isInteger(seconds) || seconds<1 || seconds>10800
            || ["","writing","code","relax"].indexOf(requestedMode)<0) return false
        error=""
        if (requestedMode && !modeService.activate(requestedMode)) { error="Could not request mode."; return false }
        memory.durationSeconds=seconds
        memory.remainingSeconds=seconds
        memory.modeId=requestedMode
        memory.deadline=Date.now()+seconds*1000
        memory.managesDnd=false
        if (quiet && notificationState.available && !notificationState.dnd) {
            notificationState.toggleDnd()
            if (notificationState.dnd) {
                expectedDndRevision=notificationState.dndRevision
                memory.managesDnd=true
            }
        }
        memory.status="running"
        return true
    }
    function restoreDnd() {
        if (!memory) return
        const owned=memory.managesDnd && notificationState.dnd && expectedDndRevision===notificationState.dndRevision
        memory.managesDnd=false
        if (owned) notificationState.toggleDnd()
    }
    function tick(now) {
        if (status!=="running") return
        memory.remainingSeconds=Math.max(0,Math.ceil((memory.deadline-now)/1000))
        if (!memory.remainingSeconds) {
            memory.status="completed"
            memory.deadline=0
            restoreDnd()
            completed()
        }
    }
    function pause() {
        if (status!=="running") return
        tick(Date.now())
        if (status!=="running") return
        memory.status="paused"
        memory.deadline=0
    }
    function resume() {
        if (status!=="paused") return
        memory.deadline=Date.now()+memory.remainingSeconds*1000
        memory.status="running"
    }
    function stop() {
        if (!active) return
        restoreDnd()
        memory.status="idle"
        memory.deadline=0
        memory.remainingSeconds=memory.durationSeconds
    }
    property Timer clock: Timer {
        interval: 1000
        repeat: true
        running: root.status==="running"
        onTriggered: root.tick(Date.now())
    }
    property Connections dndChanges: Connections {
        target: root.notificationState
        function onDndRevisionChanged() {
            if (!root.restoring && root.managesDnd && root.expectedDndRevision!==root.notificationState.dndRevision)
                root.memory.managesDnd=false
        }
    }
}
