// Temporary native toplevels only. No file is accepted or written.
import QtQuick
import QtQuick.Window
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root
    Window {
        id: main
        visible: true
        width: 700
        height: 440
        title: "Dialog fixture parent"
        color: "#282a36"
        Text { anchors.centerIn: parent; text: "Temporary dialog test — no files are saved"; color:"#f8f8f2" }
    }
    Window {
        id: popup
        visible: false
        transientParent: main
        flags: Qt.Dialog
        modality: Qt.WindowModal
        width: 1900
        height: 1400
        color: "#282a36"
        Text { anchors.centerIn: parent; text: popup.title; color:"#f8f8f2"; font.pixelSize:22 }
    }
    Window {
        id: regularWindow
        visible: false
        title: "Save As"
        width: 700
        height: 440
        color: "#282a36"
        Text { anchors.centerIn: parent; text: "Normal window with a dialog-like title"; color:"#f8f8f2" }
    }
    FileDialog {
        id: filePicker
        parentWindow: main
        title: "Save As"
        fileMode: FileDialog.SaveFile
        options: FileDialog.DontUseNativeDialog
        currentFolder: "file:///tmp"
    }
    IpcHandler {
        target: "dialogTest"
        function open(title: string): void {
            popup.title=title
            popup.width=title==="Are you sure?" ? 330 : 1900
            popup.height=title==="Are you sure?" ? 180 : 1400
            popup.visible=true
        }
        function regular(): void { regularWindow.visible=true }
        function picker(): void { filePicker.open() }
        function close(): void { popup.visible=false;regularWindow.visible=false;filePicker.close() }
        function grow(): void { popup.width=2500;popup.height=1800 }
        function status(): string { return JSON.stringify({modal:popup.visible,regular:regularWindow.visible,picker:filePicker.visible}) }
    }
}
