import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "../../../config" as Config
import "../../../components" as Components
import "../../../services" as Services

RowLayout {
    id: root

    spacing: 4

    Repeater {
        model:
            Services.HyprlandService.visibleToplevels

        delegate: Rectangle {
            id: windowItem

            required property var modelData

            /*
             * modelData bây giờ là HyprlandToplevel.
             */
            readonly property var toplevel:
                modelData

            readonly property var ipc:
                toplevel
                && toplevel.lastIpcObject
                ? toplevel.lastIpcObject
                : null

            readonly property var wayland:
                toplevel
                ? (
                    toplevel.wayland
                    || toplevel.handle
                )
                : null

            // -------------------------------------------------------------
            // Application identity
            // -------------------------------------------------------------

            readonly property string appId: {
                /*
                 * Ưu tiên class từ Hyprland IPC.
                 */
                if (
                    ipc
                    && typeof ipc.class === "string"
                    && ipc.class.length > 0
                ) {
                    return ipc.class
                }

                if (
                    ipc
                    && typeof ipc.initialClass === "string"
                    && ipc.initialClass.length > 0
                ) {
                    return ipc.initialClass
                }

                /*
                 * Sau cùng mới thử Wayland appId.
                 */
                if (
                    wayland
                    && typeof wayland.appId === "string"
                    && wayland.appId.length > 0
                ) {
                    return wayland.appId
                }

                return ""
            }

            // -------------------------------------------------------------
            // Window state
            // -------------------------------------------------------------

            readonly property string windowTitle:
                toplevel
                && typeof toplevel.title === "string"
                ? toplevel.title
                : ""

            readonly property bool active:
                toplevel
                ? Boolean(toplevel.activated)
                : false

            readonly property bool urgent:
                toplevel
                ? Boolean(toplevel.urgent)
                : false

            readonly property bool minimized:
                Services.HyprlandService
                .isMinimized(toplevel)

            /*
             * Không phụ thuộc appId để hiển thị.
             */
            visible:
                toplevel !== null

            implicitWidth: 28
            implicitHeight: 28

            color: "transparent"

            Components.AppIcon {
                id: appIcon

                anchors.centerIn: parent

                appId:
                    windowItem.appId

                iconSize: 18

                opacity:
                    windowItem.minimized
                    ? 0.4
                    : 1.0
            }

            Rectangle {
                anchors {
                    horizontalCenter:
                        parent.horizontalCenter

                    bottom:
                        parent.bottom

                    bottomMargin: 1
                }

                width:
                    windowItem.active
                    ? 14
                    : 4

                height: 2
                radius: 1

                visible:
                    windowItem.active

                color:
                    windowItem.active
                    ? Config.Theme.primary
                    : Config.Theme.subtext
            }


            Behavior on color {
                ColorAnimation {
                    duration:
                        Config.Animations.fast
                }
            }
            
        }
    }
}
