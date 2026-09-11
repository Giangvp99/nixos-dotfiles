import QtQuick
import QtQuick.Layouts

import "../config" as Config

Rectangle {
    id: root

    property string icon: ""
    property string text: ""

    property color foreground:
        Config.Theme.text

    property color iconColor:
        foreground

    property color background:
        Config.Theme.surface

    property int horizontalPadding: 10
    property int spacing: 6

    property int iconSize:
        Config.Theme.fontLarge

    property int textSize:
        Config.Theme.fontNormal

    implicitWidth:
        content.implicitWidth
        + horizontalPadding * 2

    implicitHeight: 28

    radius:
        Config.Theme.radiusSmall

    color:
        background

    RowLayout {
        id: content

        anchors.centerIn: parent

        spacing:
            root.spacing

        Text {
            visible:
                root.icon.length > 0

            text:
                root.icon

            color:
                root.iconColor

            font.family:
                Config.Theme.fontFamily

            font.pixelSize:
                root.iconSize

            verticalAlignment:
                Text.AlignVCenter
        }

        Text {
            visible:
                root.text.length > 0

            text:
                root.text

            color:
                root.foreground

            font.family:
                Config.Theme.fontFamily

            font.pixelSize:
                root.textSize

            verticalAlignment:
                Text.AlignVCenter
        }
    }
}
