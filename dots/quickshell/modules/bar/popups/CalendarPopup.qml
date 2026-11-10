import QtQuick
import Quickshell
import "../../../config" as Config
import "../../../components" as Components

BarPopup {
    id: root
    readonly property int popupWidth: 330
    readonly property int popupHeight: 330
    property alias displayYear: calendar.displayYear
    property alias displayMonth: calendar.displayMonth
    readonly property date currentDate: clock.date
    readonly property int todayYear: calendar.todayYear
    readonly property int todayMonth: calendar.todayMonth
    readonly property int todayDay: calendar.todayDay
    preferredWidth: popupWidth
    preferredHeight: popupHeight
    initialFocusItem: calendar.firstControl
    function previousMonth() { calendar.previousMonth() }
    function nextMonth() { calendar.nextMonth() }
    function monthTitle() { return calendar.monthTitle() }
    function firstDayOffset() { return calendar.firstDayOffset() }
    function dateForCell(index) { return calendar.dateForCell(index) }
    SystemClock { id: clock; precision: SystemClock.Minutes }
    Connections {
        target: root
        function onVisibleChanged() { if (root.visible) calendar.reset() }
    }
    Components.Surface {
        panel: true
        anchors.fill: parent
        Keys.onEscapePressed: root.close(true)
        Components.MonthCalendar {
            id: calendar
            anchors.fill: parent
            anchors.margins: Config.Theme.popupPadding
            now: clock.date
            wrapFocus: true
        }
    }
}
