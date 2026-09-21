import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

import "../../config" as Config
import "../../services" as Services

Scope {
    id: root

    property bool opened: false
    property string query: searchInput.text
    property int selectedIndex: 0

    readonly property var results:
        Services.AppService.search(query)

    function open() {
        searchInput.clear()
        selectedIndex = 0
        opened = true

        Qt.callLater(() => {
            searchInput.forceActiveFocus()
        })
    }

    function close() {
        opened = false
        searchInput.clear()
        selectedIndex = 0
    }

    function toggle() {
        if (opened)
            close()
        else
            open()
    }

    function moveSelection(delta) {
        if (results.length === 0) {
            selectedIndex = 0
            return
        }

        selectedIndex =
            (selectedIndex + delta + results.length)
            % results.length

        resultsView.positionViewAtIndex(
            selectedIndex,
            ListView.Contain
        )
    }

    function activateSelected() {
        if (
            selectedIndex < 0
            || selectedIndex >= results.length
        ) {
            return
        }

        const app =
            results[selectedIndex]

        close()

        Services.AppService.launch(app)
    }

    GlobalShortcut {
        name: "launcher"
        description: "Toggle application launcher"

        onPressed:
            root.toggle()
    }

    readonly property ScriptModel resultModel:
        ScriptModel {
            values:
                root.results
        }

    PanelWindow {
        id: window

        visible:
            root.opened

        focusable: true

        aboveWindows: true

        exclusionMode:
            ExclusionMode.Ignore

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        color:
            "transparent"

        Rectangle {
            anchors.fill: parent

            color:
                "#66000000"

            MouseArea {
                anchors.fill: parent

                onClicked:
                    root.close()
            }
        }

        Rectangle {
            id: launcherSurface

            width: 560

            height:
                Math.min(
                    520,
                    content.implicitHeight + 32
                )

            anchors {
                horizontalCenter:
                    parent.horizontalCenter

                top:
                    parent.top

                topMargin:
                    Math.max(
                        100,
                        parent.height * 0.16
                    )
            }

            radius:
                Config.Theme.radiusLarge

            color:
                Config.Theme.background

            border.width: 1

            border.color:
                Config.Theme.surface

            MouseArea {
                anchors.fill: parent

                /*
                 * Ngăn click trong launcher
                 * truyền xuống overlay phía sau.
                 */
                onClicked: mouse => {
                    mouse.accepted = true
                }
            }

            ColumnLayout {
                id: content

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top

                    margins: 16
                }

                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46

                    radius:
                        Config.Theme.radiusMedium

                    color:
                        Config.Theme.surface

                    RowLayout {
                        anchors.fill: parent

                        anchors.leftMargin: 14
                        anchors.rightMargin: 14

                        spacing: 10

                        Text {
                            text: ""

                            color:
                                Config.Theme.subtext

                            font.family:
                                Config.Theme.fontFamily

                            font.pixelSize:
                                Config.Theme.fontLarge
                        }

                        Item {
    Layout.fillWidth: true
    Layout.fillHeight: true

    TextInput {
        id: searchInput

        anchors.fill: parent

        verticalAlignment:
            TextInput.AlignVCenter

        color:
            Config.Theme.text

        font.family:
            Config.Theme.fontFamily

        font.pixelSize:
            Config.Theme.fontNormal

        clip: true
        selectByMouse: true

        onTextEdited: {
            root.selectedIndex = 0
        }

        Keys.onEscapePressed:
            root.close()

        Keys.onDownPressed:
            root.moveSelection(1)

        Keys.onUpPressed:
            root.moveSelection(-1)

        Keys.onReturnPressed:
            root.activateSelected()

        Keys.onEnterPressed:
            root.activateSelected()
    }

    Text {
        anchors.fill: parent

        visible:
            searchInput.text.length === 0

        text:
            "Search applications..."

        verticalAlignment:
            Text.AlignVCenter

        color:
            Config.Theme.subtext

        font.family:
            Config.Theme.fontFamily

        font.pixelSize:
            Config.Theme.fontNormal
    }
}

                    }
                }

                ListView {
                    id: resultsView

                    Layout.fillWidth: true

                    Layout.preferredHeight:
                        Math.min(
                            contentHeight,
                            8 * 52
                        )

                    clip: true

                    spacing: 2

                    model:
                        root.resultModel

                    delegate:
                        LauncherItem {
                            required property var modelData
                            required property int index

                            width:
                                resultsView.width

                            app:
                                modelData

                            selected:
                                index === root.selectedIndex

                            onActivated: {
                                root.selectedIndex = index

                                const selectedApp =
                                    modelData

                                root.close()

                                Services.AppService.launch(
                                    selectedApp
                                )
                            }
                        }
                }

                Text {
                    Layout.fillWidth: true

                    visible:
                        root.results.length === 0

                    text:
                        "No applications found"

                    horizontalAlignment:
                        Text.AlignHCenter

                    color:
                        Config.Theme.subtext

                    font.family:
                        Config.Theme.fontFamily

                    font.pixelSize:
                        Config.Theme.fontNormal

                    Layout.topMargin: 20
                    Layout.bottomMargin: 20
                }
            }
        }
    }
}
