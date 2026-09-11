import QtQuick
import QtQuick.Layouts

import Quickshell

import "../../../config" as Config
import "../../../components" as Components

PopupWindow {
    id: root

    property Item anchorItem

    readonly property int popupWidth: 330
    readonly property int popupHeight: 330

    /*
     * Tháng JS:
     * January = 0
     * December = 11
     */
    property int displayYear: currentDate.getFullYear()
    property int displayMonth: currentDate.getMonth()

    readonly property date currentDate:
        clock.date

    readonly property int todayYear:
        currentDate.getFullYear()

    readonly property int todayMonth:
        currentDate.getMonth()

    readonly property int todayDay:
        currentDate.getDate()

    width:
        popupWidth

    height:
        popupHeight

    visible: false
    grabFocus: true

    color:
        "transparent"

    SystemClock {
        id: clock

        precision:
            SystemClock.Minutes
    }

    anchor {
        item:
            root.anchorItem

        edges:
            Edges.Bottom
            | Edges.Right

        gravity:
            Edges.Bottom
            | Edges.Left

        margins.bottom: 8

        adjustment:
            PopupAdjustment.Slide
            | PopupAdjustment.Flip
    }

    /*
     * Mỗi lần mở popup:
     * quay về tháng hiện tại.
     */
    onVisibleChanged: {
        if (!visible)
            return

        displayYear =
            currentDate.getFullYear()

        displayMonth =
            currentDate.getMonth()
    }

    Rectangle {
        anchors.fill: parent

        color:
            Config.Theme.background

        radius:
            Config.Theme.radiusMedium

        border.width: 1
        border.color:
            Config.Theme.surface

        ColumnLayout {
            anchors {
                fill: parent
                margins: 14
            }

            spacing: 8

            /*
             * Header
             *
             * <    September 2026    >
             */
            RowLayout {
                Layout.fillWidth: true

                CalendarNavigationButton {
                    text: "‹"

                    onClicked:
                        root.previousMonth()
                }

                Components.StyledText {
                    Layout.fillWidth: true

                    text:
                        root.monthTitle()

                    horizontalAlignment:
                        Text.AlignHCenter

                    font.bold: true

                    font.pixelSize:
                        Config.Theme.fontLarge
                }

                CalendarNavigationButton {
                    text: "›"

                    onClicked:
                        root.nextMonth()
                }
            }

            Rectangle {
                Layout.fillWidth: true

                implicitHeight: 1

                color:
                    Config.Theme.surface
            }

            /*
             * Week headers
             */
            GridLayout {
                Layout.fillWidth: true

                columns: 7
                columnSpacing: 0
                rowSpacing: 0

                Repeater {
                    model: [
                        "Mon",
                        "Tue",
                        "Wed",
                        "Thu",
                        "Fri",
                        "Sat",
                        "Sun"
                    ]

                    delegate: Item {
                        required property string modelData

                        Layout.fillWidth: true
                        implicitHeight: 28

                        Components.StyledText {
                            anchors.centerIn: parent

                            text:
                                modelData

                            color:
                                Config.Theme.subtext

                            font.pixelSize:
                                Config.Theme.fontSmall

                            font.bold: true
                        }
                    }
                }
            }

            /*
             * Calendar body.
             *
             * Luôn dùng 42 cell:
             * 7 ngày × 6 tuần.
             */
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true

                columns: 7

                columnSpacing: 2
                rowSpacing: 2

                Repeater {
                    model: 42

                    delegate: Rectangle {
                        id: dayCell

                        required property int index

                        readonly property var dayInfo:
                            root.dateForCell(index)

                        readonly property bool currentMonth:
                            dayInfo.month
                            === root.displayMonth

                        readonly property bool today:
                            dayInfo.year
                                === root.todayYear
                            && dayInfo.month
                                === root.todayMonth
                            && dayInfo.day
                                === root.todayDay

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        radius:
                            Config.Theme.radiusSmall

                        color:
                            today
                            ? Config.Theme.primary
                            : "transparent"

                        Components.StyledText {
                            anchors.centerIn: parent

                            text:
                                dayCell.dayInfo.day

                            color: {
                                if (dayCell.today)
                                    return Config.Theme.background

                                if (!dayCell.currentMonth)
                                    return Config.Theme.subtext

                                return Config.Theme.text
                            }

                            opacity:
                                dayCell.currentMonth
                                ? 1.0
                                : 0.45

                            font.bold:
                                dayCell.today
                        }
                    }
                }
            }

            /*
             * Footer
             */
            Components.StyledText {
                Layout.fillWidth: true

                text:
                    Qt.formatDateTime(
                        root.currentDate,
                        "dddd, dd MMMM yyyy"
                    )

                horizontalAlignment:
                    Text.AlignHCenter

                color:
                    Config.Theme.subtext

                font.pixelSize:
                    Config.Theme.fontSmall
            }
        }
    }

    /*
     * Button nội bộ dùng riêng cho navigation.
     */
    component CalendarNavigationButton: Rectangle {
        id: navigationButton

        property string text: ""

        signal clicked()

        implicitWidth: 30
        implicitHeight: 30

        radius:
            Config.Theme.radiusSmall

        color:
            navMouse.containsMouse
            ? Config.Theme.surfaceHover
            : Config.Theme.surface

        Components.StyledText {
            anchors.centerIn: parent

            text:
                navigationButton.text

            font.pixelSize:
                Config.Theme.fontLarge
        }

        MouseArea {
            id: navMouse

            anchors.fill: parent

            hoverEnabled: true

            cursorShape:
                Qt.PointingHandCursor

            onClicked:
                navigationButton.clicked()
        }
    }

    function previousMonth() {
        if (displayMonth === 0) {
            displayMonth = 11
            displayYear--
            return
        }

        displayMonth--
    }

    function nextMonth() {
        if (displayMonth === 11) {
            displayMonth = 0
            displayYear++
            return
        }

        displayMonth++
    }

    function monthTitle() {
        const date =
            new Date(
                displayYear,
                displayMonth,
                1
            )

        return Qt.formatDate(
            date,
            "MMMM yyyy"
        )
    }

    /*
     * JS Sunday = 0.
     *
     * Ta đổi sang:
     *
     * Monday    = 0
     * ...
     * Sunday    = 6
     */
    function firstDayOffset() {
        const first =
            new Date(
                displayYear,
                displayMonth,
                1
            )

        return (
            first.getDay()
            + 6
        ) % 7
    }

    /*
     * index 0..41
     *
     * JS Date tự xử lý ngày âm hoặc vượt tháng:
     *
     * new Date(2026, 8, 0)
     * → ngày cuối August
     */
    function dateForCell(index) {
        const day =
            index
            - firstDayOffset()
            + 1

        const date =
            new Date(
                displayYear,
                displayMonth,
                day
            )

        return {
            year:
                date.getFullYear(),

            month:
                date.getMonth(),

            day:
                date.getDate()
        }
    }
}
