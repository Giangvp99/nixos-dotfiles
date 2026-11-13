import QtQuick
import Quickshell

Scope {
    readonly property alias instances: windows.instances
    Variants {
        id: windows
        model: Quickshell.screens
        Bar {
            required property var modelData
            screen: modelData
        }
    }
}
