import QtQuick
import QtQuick.Layouts

import "../../config" as Config
import "./widgets" as Widgets

RowLayout {
    
    id: root

    spacing: Config.Config.barSpacing

    Widgets.Audio {}

    Widgets.Clock {
        visible: Config.Config.showClock
    }
}
