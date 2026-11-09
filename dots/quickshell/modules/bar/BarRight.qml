import QtQuick
import QtQuick.Layouts

import "../../config" as Config
import "./widgets" as Widgets

RowLayout {
    
    id: root

    spacing: Config.Config.barSpacing

    Widgets.Wifi {}

    Widgets.Battery {}
    
    Widgets.Brightness {}

    Widgets.Audio {}

    Widgets.Date {}

    Widgets.Clock {
        visible: Config.Config.showClock
    }

    Widgets.Keyboard {}

    Widgets.PowerMenu {}
}
