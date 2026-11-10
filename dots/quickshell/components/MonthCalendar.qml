import QtQuick
import QtQuick.Layouts
import "../config" as Config

Item {
    id: root
    property date now: new Date()
    property bool showFooter: true
    property bool wrapFocus: false
    property var focusHandler: null
    property int displayYear: now.getFullYear()
    property int displayMonth: now.getMonth()
    readonly property int todayYear: now.getFullYear()
    readonly property int todayMonth: now.getMonth()
    readonly property int todayDay: now.getDate()
    readonly property alias firstControl: previousButton
    readonly property alias lastControl: nextButton
    implicitWidth: 306
    implicitHeight: 306
    function reset() { displayYear = now.getFullYear(); displayMonth = now.getMonth() }
    function cycleFocus() { (previousButton.activeFocus ? nextButton : previousButton).forceActiveFocus() }
    Keys.onLeftPressed: previousMonth()
    Keys.onRightPressed: nextMonth()
    Keys.onTabPressed: event => { if (focusHandler) focusHandler.cycleFocus(1); else if (wrapFocus) cycleFocus(); else event.accepted = false }
    Keys.onBacktabPressed: event => { if (focusHandler) focusHandler.cycleFocus(-1); else if (wrapFocus) cycleFocus(); else event.accepted = false }

    ColumnLayout {
        anchors {
            fill: parent
            margins: 0
        }

        spacing: Config.Theme.spaceMedium

        /*
         * Header
         *
         * <    September 2026    >
         */
        RowLayout {
            Layout.fillWidth: true

            CalendarNavigationButton {
                id: previousButton
                Accessible.name: "Previous month"
                text: "‹"

                onClicked:
                    root.previousMonth()
            }

            StyledText {
                Layout.fillWidth: true

                text:
                    root.monthTitle()

                horizontalAlignment:
                    Text.AlignHCenter

                font.weight: Config.Theme.emphasisFontWeight

                font.pixelSize:
                    Config.Theme.fontLarge
            }

            CalendarNavigationButton {
                id: nextButton
                Accessible.name: "Next month"
                text: "›"

                onClicked:
                    root.nextMonth()
            }
        }

        Rectangle {
            Layout.fillWidth: true

            implicitHeight: Config.Theme.separatorWidth

            color:
                Config.Theme.border
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

                    StyledText {
                        anchors.centerIn: parent

                        text:
                            modelData

                        color:
                            Config.Theme.subtext

                        font.pixelSize:
                            Config.Theme.fontSmall

                        font.weight: Config.Theme.emphasisFontWeight
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

                    StyledText {
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
        StyledText {
            Layout.fillWidth: true

            text:
                Qt.formatDateTime(
                    root.now,
                    "dddd, dd MMMM yyyy"
                )

            visible: root.showFooter
            horizontalAlignment:
                Text.AlignHCenter

            color:
                Config.Theme.subtext

            font.pixelSize:
                Config.Theme.fontSmall
        }
    }


    component CalendarNavigationButton: IconButton {
        Keys.forwardTo: [root]
        implicitWidth: Config.Theme.popupHeaderHeight
        implicitHeight: Config.Theme.popupHeaderHeight
        horizontalPadding: 0
        textSize: Config.Theme.fontLarge
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
