import QtQuick
import Quickshell.Io

QtObject {
    id: root
    property string interfaceName: ""
    property bool active: false
    property bool busy: false
    property bool pending: false
    property string requestedInterface: ""
    property int lastExitCode: -1
    property var details: ({})
    property string error: ""
    function parse(text) {
        const values={}
        for (const line of text.split("\n")) {
            const colon=line.indexOf(":")
            if (colon<0) continue
            const key=line.slice(0,colon).replace(/\[\d+\]$/,"")
            const value=line.slice(colon+1).trim()
            if (value && value!=="--") values[key]=values[key] ? values[key]+", "+value : value
        }
        return values
    }
    function refresh() {
        if (!active) return
        if (busy || command.running) { pending=true; return }
        details={}; error=""; pending=false
        if (!interfaceName) { error="No interface selected."; return }
        requestedInterface=interfaceName
        busy=true
        command.running=true
    }
    function finished() {
        if (!busy) return
        busy=false
        if (active && requestedInterface===interfaceName) {
            if (lastExitCode===0) details=parse(output.text)
            else error="Could not read connection details. Open Settings to inspect this interface."
        }
        if (pending && active) Qt.callLater(root.refresh)
    }
    onActiveChanged: {
        if (active) refresh()
        else { pending=false; command.running=false }
    }
    onInterfaceNameChanged: {
        details={}
        if (active) refresh()
    }
    property Process command: Process {
        command: ["nmcli","--terse","--escape","no","--fields",
            "GENERAL.DEVICE,GENERAL.TYPE,GENERAL.CONNECTION,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS",
            "device","show",root.requestedInterface]
        environment: ({LC_ALL:"C"})
        stdout: StdioCollector { id: output }
        stderr: StdioCollector {}
        onExited: exitCode => { root.lastExitCode=exitCode; Qt.callLater(root.finished) }
    }
    property Timer timeout: Timer {
        interval: 5000
        running: root.busy
        onTriggered: {
            root.busy=false; root.pending=false; root.command.running=false
            root.error="Connection details timed out. Retry or open Settings."
        }
    }
}
