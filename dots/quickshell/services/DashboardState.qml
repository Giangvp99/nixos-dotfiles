pragma Singleton
import QtQuick

QtObject {
    property var controller: null
    readonly property bool opened: controller ? controller.opened : false
    function toggle(origin) { if (controller) controller.toggle(origin) }
    function close() { if (controller) controller.close(false) }
}
