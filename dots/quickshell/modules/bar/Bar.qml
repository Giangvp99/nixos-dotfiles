import QtQuick
import Quickshell

import "../../config" as Config

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight:
        Config.Config.barHeight
        + Config.Config.barOuterMargin * 2

    color: "transparent"

    Rectangle {
        id: background

        anchors.fill: parent
        anchors.margins: Config.Config.barOuterMargin

        radius: Config.Theme.radiusMedium
        color: Config.Theme.background

        BarLeft {
            anchors {
                left: parent.left
                leftMargin: Config.Config.barHorizontalPadding

                verticalCenter: parent.verticalCenter
            }
        }

        BarCenter {
            anchors.centerIn: parent
        }

        BarRight {
            anchors {
                right: parent.right
                rightMargin: Config.Config.barHorizontalPadding

                verticalCenter: parent.verticalCenter
            }
        }
    }
}
