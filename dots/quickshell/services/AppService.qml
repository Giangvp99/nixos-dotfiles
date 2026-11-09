pragma Singleton

import QtQuick
import Quickshell

QtObject {
    id: root

    readonly property var applications:
        DesktopEntries.applications

    function search(query) {
        const normalized =
            query.trim().toLowerCase()

        const apps =
            applications.values

        if (normalized.length === 0)
            return apps.slice(0, 8)

        const results = []

        for (let i = 0; i < apps.length; ++i) {
            const app = apps[i]

            const name =
                (app.name || "").toLowerCase()

            const genericName =
                (app.genericName || "").toLowerCase()

            const keywords =
                (app.keywords || [])
                    .join(" ")
                    .toLowerCase()

            if (
                name.includes(normalized)
                || genericName.includes(normalized)
                || keywords.includes(normalized)
            ) {
                results.push(app)
            }

            if (results.length >= 8)
                break
        }

        return results
    }

    function launch(app) {
        if (!app)
            return

        app.execute()
    }
}
