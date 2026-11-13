import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../components" as Components
import "../../config" as Config
import "../../services" as Services

Scope {
    id: root
    property var audioService: Services.AudioService
    property bool enabled: Config.Config.audioOsdEnabled
    property int timeout: Config.Config.audioOsdTimeout
    readonly property var targetScreen: route.screen
    Components.OverlayScreen { id: route; active: state.shown; onRemoved: state.hide() }
    readonly property alias feedback: state
    readonly property alias panel: window

    AudioFeedback {
        id: state
        audioService: root.audioService
        enabled: root.enabled
        timeout: root.timeout
        onPresented: route.capture(null, null)
    }
    PanelWindow {
        id: window
        screen: root.targetScreen
        visible: state.shown && root.targetScreen !== null
        implicitWidth: Math.max(0, Math.min(Config.Config.audioOsdWidth,
            screen ? screen.width - Config.Theme.panelPadding * 2 : Config.Config.audioOsdWidth))
        implicitHeight: 80
        anchors.bottom: true
        margins.bottom: Config.Config.audioOsdBottomMargin
        exclusionMode: ExclusionMode.Ignore
        focusable: false
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:audio-osd"
        mask: Region {}
        color: "transparent"
        Components.Surface {
            id: surface
            anchors.fill: parent
            panel: true
            radius: Config.Theme.radiusMedium
            Accessible.role: Accessible.StaticText
            Accessible.name: (state.channel === "input" ? "Microphone" : "Volume")
                + ": " + (state.muted ? "Muted, " : "") + state.percent + "%"
            RowLayout {
                anchors.fill: parent
                anchors.margins: Config.Theme.panelPadding
                spacing: Config.Theme.spaceLarge
                Components.StyledText {
                    text: state.channel === "input" ? (state.muted ? "󰍭" : "󰍬")
                        : (state.muted ? "󰖁" : (state.percent === 0 ? "󰕿" : "󰕾"))
                    font.family: Config.Theme.iconFontFamily
                    font.pixelSize: Config.Theme.launcherIconSize
                    color: state.muted ? Config.Theme.subtext : Config.Theme.primary
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Config.Theme.spaceSmall
                    RowLayout {
                        Layout.fillWidth: true
                        Components.StyledText {
                            Layout.fillWidth: true
                            text: state.channel === "input" ? "Microphone" : "Volume"
                            elide: Text.ElideRight
                        }
                        Components.StyledText {
                            text: state.muted ? "Muted" : state.percent + "%"
                            color: state.muted ? Config.Theme.subtext : Config.Theme.primary
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Config.Theme.spaceSmall
                        radius: height / 2
                        color: Config.Theme.surfaceHover
                        Rectangle {
                            width: parent.width * Math.min(1, state.percent / 100)
                            height: parent.height
                            radius: height / 2
                            color: state.muted ? Config.Theme.subtext : Config.Theme.primary
                        }
                    }
                    Components.StyledText {
                        Layout.fillWidth: true
                        text: state.deviceName
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        font.pixelSize: Config.Theme.fontSmall
                        color: Config.Theme.subtext
                    }
                }
            }
        }
        Components.OverlayMotion {
            targetItem: surface
            shown: window.backingWindowVisible && state.shown
        }
    }
}
