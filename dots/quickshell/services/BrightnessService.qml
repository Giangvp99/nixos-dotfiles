pragma Singleton

import QtQuick
import Quickshell.Io

QtObject {
    id: root

    readonly property string backlightPath:
        "/sys/class/backlight/intel_backlight"

    /*
     * QtObject không chứa child object trực tiếp được,
     * vì vậy FileView phải được khai báo thành property.
     */
    readonly property FileView brightnessFile: FileView {
        path:
            root.backlightPath
            + "/brightness"

        watchChanges: true

        onFileChanged:
            reload()
    }

    readonly property FileView maxBrightnessFile: FileView {
        path:
            root.backlightPath
            + "/max_brightness"
    }

    readonly property int brightness:
        readInteger(brightnessFile)

    readonly property int maxBrightness:
        readInteger(maxBrightnessFile)

    readonly property bool available:
        brightnessFile.loaded
        && maxBrightnessFile.loaded
        && maxBrightness > 0

    readonly property real normalized:
        available
        ? brightness / maxBrightness
        : 0.0

    readonly property int percent:
        available
        ? Math.round(normalized * 100)
        : 0

    function readInteger(file) {
        if (!file || !file.loaded)
            return 0

        const value =
            parseInt(
                file.text().trim()
            )

        return Number.isNaN(value)
            ? 0
            : value
    }
}
