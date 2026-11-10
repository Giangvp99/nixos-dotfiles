import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../../config" as Config
import "../../../components" as Components

PopupWindow {
    id: root
    property Item anchorItem
    property Item initialFocusItem
    property int preferredWidth: 320
    property int preferredHeight: 300
    implicitWidth: Math.min(preferredWidth, screen ? Math.max(1, screen.width - Config.Theme.spaceMedium * 2) : preferredWidth)
    implicitHeight: Math.min(preferredHeight, screen ? Math.max(1, screen.height - (anchor.window ? anchor.window.height : 0) - Config.Theme.spaceMedium * 2) : preferredHeight)
    visible: false
    // Use the Hyprland grab alone: no xdg_popup input serial is required.
    grabFocus: false
    color: "transparent"
    anchor {
        window: root.anchorItem ? root.anchorItem.QsWindow.window : null
        edges: Edges.Top | Edges.Left
        gravity: Edges.Bottom | Edges.Right
        adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip | PopupAdjustment.Resize
        onAnchoring: {
            if (!root.anchorItem || !root.anchor.window) return
            const point = root.anchorItem.mapToItem(root.anchor.window.contentItem, root.anchorItem.width, 0)
            root.anchor.rect.x = Math.max(Config.Theme.spaceMedium, Math.round(point.x - root.width))
            root.anchor.rect.y = root.anchor.window.height + Config.Theme.spaceMedium
            root.anchor.rect.width = 1
            root.anchor.rect.height = 1
        }
    }
    Connections {
        target: root.anchor.window
        function onWidthChanged() { if (root.visible) root.anchor.updateAnchor() }
        function onHeightChanged() { if (root.visible) root.anchor.updateAnchor() }
    }


    Components.OverlayFocus { id: focusReturn; opened: root.visible; windowVisible: root.backingWindowVisible }
    Components.OverlayMotion { targetItem: root.contentItem; shown: root.backingWindowVisible && root.visible }
    function open(origin) { focusReturn.remember(origin || anchorItem); visible = true }
    function toggle() { if (visible) close(true); else open() }
    function close(restoreFocus) {
        visible = false
        focusReturn.finish(restoreFocus)
    }
    function focusContent() {
        if (visible && initialFocusItem) initialFocusItem.forceActiveFocus()
    }
    onVisibleChanged: {
        if (visible) {
            if (!focusReturn.origin) focusReturn.remember(anchorItem)
            PopupState.claim(root)
            Qt.callLater(root.focusContent)
        } else PopupState.release(root)
    }
    onBackingWindowVisibleChanged: {
        if (backingWindowVisible && visible) {
            grab.active = true
            Qt.callLater(root.focusContent)
        } else grab.active = false
    }
    Component.onDestruction: PopupState.release(root)

    HyprlandFocusGrab {
        id: grab
        // First acquire keyboard focus on the popup, then allow bar interaction.
        // Including the bar initially would let its existing focus win the grab.
        windows: active && root.anchorItem && root.anchorItem.QsWindow.window
            ? [root, root.anchorItem.QsWindow.window] : [root]
        onActiveChanged: if (active) Qt.callLater(root.focusContent)
        onCleared: if (root.visible) root.close(false)
    }
}
