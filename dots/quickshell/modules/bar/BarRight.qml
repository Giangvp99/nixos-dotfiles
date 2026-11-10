import QtQuick
import QtQuick.Layouts

import "../../config" as Config
import "./widgets" as Widgets
import "../../services" as Services

RowLayout {
    
    id: root

    spacing: Config.Config.barSpacing

    Widgets.Wifi {}

    Widgets.Battery {}
    
    Widgets.Brightness {}

    Widgets.Audio { visible: Config.Config.showAudio && Services.AudioService.available }

    Widgets.Notifications {}

    Widgets.Date {}

    Widgets.Clock {
        visible: Config.Config.showClock
    }

    Widgets.Keyboard {}

    Widgets.PowerMenu {}
}
