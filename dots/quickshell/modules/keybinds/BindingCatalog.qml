import QtQuick
import Quickshell.Io
import Quickshell.Hyprland
import "../../utils/Keybindings.js" as Bindings

QtObject {
    id: root
    property var command: ["hyprctl", "-j", "binds"]
    property var entries: []
    property string error: ""
    property bool loading: false
    property bool accepting: false
    property bool refreshAgain: false
    readonly property bool processRunning: reader.running
    function refresh() {
        if (reader.running) { refreshAgain=true; return }
        entries=[]
        error=""
        loading=true
        accepting=true
        deadline.restart()
        reader.running=true
    }
    function cancel() {
        accepting=false
        refreshAgain=false
        deadline.stop()
        reader.running=false
        loading=false
    }
    Component.onCompleted: refresh()
    Component.onDestruction: cancel()
    property Timer deadline: Timer {
        interval: 4000
        onTriggered: {
            root.accepting=false
            root.refreshAgain=false
            root.reader.running=false
            root.loading=false
            root.error="Reading shortcuts timed out. Try Refresh."
        }
    }
    property Process reader: Process {
        command: root.command
        stdout: StdioCollector { id: output }
        stderr: StdioCollector {}
        onExited: exitCode => {
            if (!root.accepting) return
            root.deadline.stop()
            root.accepting=false
            root.loading=false
            if (exitCode !== 0) root.error="Could not read active shortcuts. Try Refresh."
            else {
                try { root.entries=Bindings.parse(output.text) }
                catch (error) { root.error="The compositor returned invalid shortcut data. Try Refresh." }
            }
            if (root.refreshAgain) { root.refreshAgain=false; Qt.callLater(root.refresh) }
        }
    }
    property Connections compositor: Connections {
        target: Hyprland
        function onRawEvent(event) { if (event.name==="configreloaded") root.refresh() }
    }
}
