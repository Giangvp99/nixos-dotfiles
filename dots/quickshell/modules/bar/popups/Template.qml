import QtQuick
import Quickshell

PopupWindow {
    id: root

    property Item anchorItem

    anchor.item:
        anchorItem

    visible: false

    grabFocus: true
}
