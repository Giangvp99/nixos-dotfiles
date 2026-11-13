pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root
    readonly property string storagePath: Quickshell.statePath("quick-notes/note.txt")
    readonly property string directory: storagePath.slice(0,storagePath.lastIndexOf("/"))
    property var memory: null
    property string text: ""
    property string savedText: ""
    property string pendingText: ""
    property string error: ""
    property bool ready: false
    property bool writing: false
    property bool directoryReady: false
    readonly property bool dirty: ready && text!==savedText
    function syncMemory() {
        if (!memory || !ready) return
        memory.hasDraft=true
        memory.draft=text
        memory.dirty=dirty
    }
    function attachMemory(value) {
        memory=value
        if (value.hasDraft && value.dirty) {
            text=value.draft
            if (ready && dirty) debounce.restart()
        } else if (ready) text=savedText
        syncMemory()
    }
    function loaded(value) {
        savedText=value
        if (memory && memory.hasDraft && memory.dirty) text=memory.draft
        else text=value
        ready=true
        error=""
        syncMemory()
        if (dirty) debounce.restart()
    }
    function update(value) {
        if (!ready || text===value) return
        text=value
        syncMemory()
        debounce.restart()
    }
    function save() {
        debounce.stop()
        if (!ready || !dirty || writing) return
        if (error && directoryReady) { retry(); return }
        writing=true
        pendingText=text
        if (directoryReady) file.setText(pendingText)
        else createDirectory.running=true
    }
    function retry() {
        if (!ready) file.reload()
        else if (error && dirty && !writing) {
            if (!directoryReady) { save(); return }
            writing=true
            pendingText=text
            // Reopen to discard FileView's cached buffer after a failed write.
            file.reload()
        } else save()
    }
    // FileView finalizes a read after its signal handler returns; defer the next write.
    function writePending() { file.setText(pendingText) }
    property Timer debounce: Timer { interval:800; onTriggered:root.save() }
    property Process createDirectory: Process {
        command:["mkdir","-p","-m","700",root.directory]
        onExited: exitCode => {
            if (exitCode===0) { root.directoryReady=true; file.setText(root.pendingText) }
            else { root.writing=false; root.error="Could not create notes folder. Retry to save your draft." }
        }
    }
    property FileView file: FileView {
        path:root.storagePath
        preload:true
        atomicWrites:true
        printErrors:false
        onLoaded: {
            if (!root.ready) { root.directoryReady=true; root.loaded(text()) }
            else if (root.writing) {
                if (text() === root.pendingText) {
                    root.savedText=root.pendingText
                    root.writing=false
                    root.error=""
                    root.syncMemory()
                    if (root.dirty) debounce.restart()
                } else Qt.callLater(root.writePending)
            }
        }
        onLoadFailed: error => {
            if (path !== root.storagePath) return
            if (root.writing) {
                root.writing=false
                root.error="Could not reload notes for Retry. Your draft is kept."
            } else if (error===FileViewError.FileNotFound) root.loaded("")
            else root.error="Could not read notes. Retry before editing."
        }
        onSaved: {
            root.savedText=root.pendingText
            root.writing=false
            root.error=""
            root.syncMemory()
            if (root.dirty) debounce.restart()
        }
        onSaveFailed: {
            root.writing=false
            root.error="Could not save notes. Your draft is kept; Retry."
            root.syncMemory()
        }
    }
}
