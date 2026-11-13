import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import "../../config" as Config
import "../../components" as Components
import "../../services" as Services

Scope {
    id: root
    property bool opened: false
    property string shortcutAppId: "quickshell"
    property alias query: searchInput.text
    property int selectedIndex: 0
    readonly property alias returnFocusItem: focusReturn.origin
    Components.OverlayFocus { id: focusReturn; opened: root.opened; windowVisible: window.backingWindowVisible }
    readonly property var targetScreen: route.screen
    Components.OverlayScreen { id: route; active: root.opened; onRemoved: root.close(false) }
    signal opening()
    readonly property alias panel: window
    readonly property var results: opened ? Services.AppService.search(query) : []

    function open(origin, preferredScreen) {
        if (!opened) route.capture(origin, preferredScreen)
        opening()
        focusReturn.remember(origin)
        searchInput.clear()
        selectedIndex = 0
        opened = true
        Qt.callLater(focusSearch)
    }
    function focusSearch() { if (opened) searchInput.forceActiveFocus() }
    function close(restoreFocus = true) {
        opened = false
        focusReturn.finish(restoreFocus)
        searchInput.clear()
        selectedIndex = 0
    }
    function toggle() { if (opened) close(); else open() }
    function moveSelection(delta) {
        if (!results.length) { selectedIndex = 0; return }
        selectedIndex = (selectedIndex + delta + results.length) % results.length
        resultsView.positionViewAtIndex(selectedIndex, ListView.Contain)
    }
    function activateSelected() {
        if (selectedIndex < 0 || selectedIndex >= results.length) return
        const app = results[selectedIndex]
        close(false)
        Services.AppService.launch(app)
    }
    onResultsChanged: {
        selectedIndex = 0
        resultsView.contentY = 0
    }

    GlobalShortcut {
        appid: root.shortcutAppId
        name: "launcher"
        description: "Toggle application launcher"
        onPressed: root.toggle()
    }
    readonly property ScriptModel resultModel: ScriptModel { values: root.results }

    PanelWindow {
        id: window
        objectName: "applicationLauncher"
        screen: route.screen
        visible: root.opened && route.valid
        focusable: true
        aboveWindows: true
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; left: true; right: true; bottom: true }
        color: "transparent"
        onBackingWindowVisibleChanged: if (backingWindowVisible) Qt.callLater(root.focusSearch)

        Rectangle {
            anchors.fill: parent
            color: Config.Theme.overlay
            MouseArea { anchors.fill: parent; onClicked: root.close(false) }
        }
        Components.OverlayMotion {
            targetItem: launcherSurface
            shown: window.backingWindowVisible && root.opened
        }
        Components.Surface {
            id: launcherSurface
            Keys.onEscapePressed: root.close()
            objectName: "launcherSurface"
            panel: true
            radius: Config.Theme.radiusLarge
            width: Math.max(0, Math.min(Config.Config.launcherWidth, parent.width - Config.Theme.panelPadding * 2))
            height: Math.max(0, Math.min(Config.Config.launcherMaxHeight,
                content.implicitHeight + Config.Theme.panelPadding * 2,
                parent.height - Config.Theme.panelPadding * 2))
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.min(Math.max(Config.Theme.panelPadding, parent.height * 0.16),
                Math.max(Config.Theme.panelPadding, parent.height - height - Config.Theme.panelPadding))
            // Consume clicks on panel padding so they cannot reach the scrim.
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                id: content
                anchors.fill: parent
                anchors.margins: Config.Theme.panelPadding
                spacing: Config.Theme.spaceMedium

                Components.Surface {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Config.Config.launcherSearchHeight
                    Layout.minimumHeight: Config.Config.launcherSearchHeight
                    color: Config.Theme.inputBackground
                    radius: Config.Theme.radiusSmall
                    border.width: Config.Theme.focusBorderWidth
                    border.color: searchInput.activeFocus ? Config.Theme.primary : Config.Theme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Config.Theme.spaceLarge
                        anchors.rightMargin: Config.Theme.spaceLarge
                        spacing: Config.Theme.spaceMedium
                        Components.StyledText {
                            text: ""
                            font.family: Config.Theme.iconFontFamily
                            font.pixelSize: Config.Theme.controlIconSize
                            color: Config.Theme.subtext
                        }
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            TextInput {
                                id: searchInput
                                objectName: "launcherSearch"
                                anchors.fill: parent
                                color: Config.Theme.text
                                selectionColor: Config.Theme.primary
                                selectedTextColor: Config.Theme.onAccent
                                font.family: Config.Theme.fontFamily
                                font.pixelSize: Config.Theme.fontNormal
                                verticalAlignment: TextInput.AlignVCenter
                                clip: true
                                selectByMouse: true
                                Accessible.name: "Search applications"
                                Keys.onEscapePressed: root.close()
                                Keys.onDownPressed: root.moveSelection(1)
                                Keys.onUpPressed: root.moveSelection(-1)
                                Keys.onTabPressed: root.moveSelection(1)
                                Keys.onBacktabPressed: root.moveSelection(-1)
                                Keys.onReturnPressed: root.activateSelected()
                                Keys.onEnterPressed: root.activateSelected()
                            }
                            Components.StyledText {
                                anchors.fill: parent
                                visible: !searchInput.text.length
                                text: "Search applications…"
                                color: Config.Theme.subtext
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
                Components.StyledText {
                    Layout.fillWidth: true
                    text: root.query.trim().length ? root.results.length + " results" : "Applications"
                    font.pixelSize: Config.Theme.fontSmall
                    color: Config.Theme.subtext
                }
                ListView {
                    id: resultsView
                    objectName: "launcherResults"
                    visible: root.results.length > 0
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 0
                    Layout.preferredHeight: Math.min(contentHeight,
                        Config.Config.launcherVisibleRows * Config.Config.launcherRowHeight
                        + (Config.Config.launcherVisibleRows - 1) * spacing)
                    clip: true
                    spacing: Config.Theme.spaceSmall
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.resultModel
                    ScrollBar.vertical: Components.StyledScrollBar { policy: ScrollBar.AsNeeded }
                    delegate: LauncherItem {
                        required property var modelData
                        required property int index
                        width: resultsView.width
                        app: modelData
                        pinned: Services.AppService.isPinned(modelData)
                        selected: index === root.selectedIndex
                        onActivated: {
                            root.selectedIndex = index
                            root.activateSelected()
                        }
                    }
                }
                Components.StyledText {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Config.Config.launcherRowHeight
                    visible: root.results.length === 0
                    text: "No applications found"
                    horizontalAlignment: Text.AlignHCenter
                    color: Config.Theme.subtext
                    wrapMode: Text.Wrap
                }
                Components.StyledText {
                    Layout.fillWidth: true
                    text: "↑↓ Select  ·  Enter Open  ·  Esc Close"
                    font.pixelSize: Config.Theme.fontSmall
                    color: Config.Theme.subtext
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }
    }
}
