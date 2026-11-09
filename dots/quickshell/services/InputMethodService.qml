pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string statePath:
        Quickshell.env(
            "XDG_RUNTIME_DIR"
        )
        + "/fcitx5-language"

    readonly property FileView stateFile:
        FileView {
            path:
                root.statePath

            watchChanges:
                true

            onFileChanged:
                reload()
        }

    readonly property string language: {
        if (!stateFile.loaded)
            return "--"

        const value =
            stateFile.text().trim()

        switch (value) {
        case "en":
        case "vi":
            return value

        default:
            return "--"
        }
    }
}
