import QtQuick

import Quickshell
import Quickshell.Widgets

import "../config" as Config

Item {
    id: root

    property string appId: ""
    property int iconSize: 18

    readonly property var desktopEntry:
        resolveDesktopEntry(appId)

    readonly property string iconName: {
        if (!desktopEntry)
            return ""

        if (
            typeof desktopEntry.icon !== "string"
            || desktopEntry.icon.length === 0
        )
            return ""

        return desktopEntry.icon
    }

    readonly property string iconSource: {
        if (iconName.length === 0)
            return ""

        return Quickshell.iconPath(
            iconName,
            true
        )
    }

    readonly property bool hasIcon:
        iconSource.length > 0

    implicitWidth: iconSize
    implicitHeight: iconSize

    IconImage {
        anchors.centerIn: parent

        visible:
            root.hasIcon

        implicitSize:
            root.iconSize

        source:
            root.iconSource

        mipmap: true
    }

    /*
     * Fallback chỉ dùng khi thực sự không tìm được desktop icon.
     */
    Text {
        anchors.centerIn: parent

        visible:
            !root.hasIcon

        text: "󰆍"

        color:
            Config.Theme.subtext

        font.family:
            Config.Theme.fontFamily

        font.pixelSize:
            root.iconSize
    }

    function normalize(value) {
        if (!value)
            return ""

        return value
            .toString()
            .toLowerCase()
            .replace(".desktop", "")
            .trim()
    }

    function resolveDesktopEntry(id) {
        if (!id || id.length === 0)
            return null

        /*
         * 1. Quickshell heuristic lookup.
         */
        let entry =
            DesktopEntries.heuristicLookup(id)

        if (entry)
            return entry

        /*
         * 2. Exact lookup.
         */
        entry =
            DesktopEntries.byId(id)

        if (entry)
            return entry

        entry =
            DesktopEntries.byId(id + ".desktop")

        if (entry)
            return entry

        /*
         * 3. Scan desktop entries.
         *
         * Matching theo:
         * - desktop entry id
         * - StartupWMClass/startupClass
         * - executable
         *
         * Điều này xử lý tốt Dolphin, Brave, Kitty,
         * Electron apps và các desktop file có ID khác window class.
         */
        const wanted =
            normalize(id)

        const apps =
            DesktopEntries.applications.values

        for (let i = 0; i < apps.length; ++i) {
            const candidate =
                apps[i]

            if (!candidate)
                continue

            const candidateId =
                normalize(candidate.id)

            const startupClass =
                normalize(candidate.startupClass)

            if (
                candidateId === wanted
                || startupClass === wanted
            ) {
                return candidate
            }

            /*
             * com.brave.Browser <-> brave-browser,
             * org.kde.dolphin <-> dolphin, v.v.
             */
            if (
                candidateId.endsWith("." + wanted)
                || wanted.endsWith("." + candidateId)
            ) {
                return candidate
            }

            /*
             * Một số package có ID dạng com.vendor.App
             * nhưng Hyprland class chỉ là App/app-name.
             */
            const idParts =
                candidateId.split(".")

            if (
                idParts.length > 1
                && idParts[idParts.length - 1] === wanted
            ) {
                return candidate
            }
        }

        return null
    }
}
