pragma Singleton
import QtQuick
import Quickshell
import "../config" as Config
import "../utils/AppSearch.js" as AppSearch

QtObject {
    id: root
    readonly property var applications: DesktopEntries.applications
    readonly property var indexedApplications: AppSearch.indexApplications(applications.values)

    function search(query) {
        return AppSearch.search(indexedApplications, query,
            Config.Config.launcherPinnedApps, Config.Config.launcherResultLimit)
    }

    function isPinned(app) {
        return app && Config.Config.launcherPinnedApps.some(
            id => AppSearch.normalizeId(id) === AppSearch.normalizeId(app.id))
    }

    function byId(id) {
        const wanted = AppSearch.normalizeId(id)
        const entry = indexedApplications.find(entry => entry.id === wanted)
        return entry ? entry.app : null
    }

    function launch(app) { if (app) app.execute() }
}
