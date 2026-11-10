pragma Singleton

import QtQuick
import Quickshell

QtObject {
    id: root

    function activate(modeId) {
        if (["writing", "code", "relax"].indexOf(modeId) < 0) return false
        Quickshell.execDetached(["hyprctl", "eval", "require(\"modes.core\").switch(" + JSON.stringify(modeId) + ")"])
        return true
    }

    function idFromWorkspace(name) {
        if (!name || !name.startsWith("mode-"))
            return ""

        const parts = name.split("-")

        if (parts.length < 3)
            return ""

        return parts[1]
    }

    function name(modeId) {
        switch (modeId) {
        case "writing":
            return "Writing"
        case "code":
            return "Code"
        case "relax":
            return "Relax"
        default:
            return ""
        }
    }

    function icon(modeId) {
        switch (modeId) {
        case "writing":
            return "󰈙"
        case "code":
            return ""
        case "relax":
            return ""
        default:
            return ""
        }
    }

    function laneFromWorkspace(name) {
        if (!name)
            return ""

        if (name.endsWith("-primary"))
            return "primary"

        if (name.endsWith("-secondary"))
            return "secondary"

        return ""
    }
}
