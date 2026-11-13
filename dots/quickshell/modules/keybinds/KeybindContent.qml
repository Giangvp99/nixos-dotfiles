pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../config" as Config
import "../../components" as Components
import "../../utils/Keybindings.js" as Bindings

ColumnLayout {
    id: root
    property var catalogCommand: ["hyprctl","-j","binds"]
    property string contextLabel: "Desktop"
    property bool windowsOnly: false
    readonly property alias catalog: catalog
    readonly property alias searchControl: search
    readonly property var results: Bindings.search(catalog.entries,search.text,windowsOnly)
    signal closeRequested()
    spacing: Config.Theme.spaceMedium
    BindingCatalog { id: catalog; command: root.catalogCommand }
    function cycleFocus(delta) {
        const targets=[search,windowFilter,refresh,closeButton,list].filter(item=>item.enabled && item.visible)
        const current=targets.findIndex(item=>item.activeFocus)
        targets[(current+delta+targets.length)%targets.length].forceActiveFocus()
    }
    function moveSelection(delta) {
        if(!list.count) return
        list.currentIndex=(list.currentIndex+delta+list.count)%list.count
        list.positionViewAtIndex(list.currentIndex,ListView.Contain)
    }
    function focusList() { if(list.count) list.forceActiveFocus() }
    onResultsChanged: { list.currentIndex=results.length?0:-1; list.contentY=0 }
    Keys.onEscapePressed: closeRequested()
    component SheetButton: Components.IconButton { focusController:root }
    RowLayout {
        Layout.fillWidth:true
        ColumnLayout {
            Layout.fillWidth:true
            spacing:Config.Theme.spaceTiny
            Components.StyledText { text:"Keyboard shortcuts"; font.pixelSize:Config.Theme.fontLarge }
            Components.StyledText {
                Layout.fillWidth:true
                text:root.contextLabel
                textFormat:Text.PlainText
                color:Config.Theme.subtext
                elide:Text.ElideRight
            }
        }
        SheetButton { id:closeButton; objectName:"keybindClose"; icon:"󰅖"; Accessible.name:"Close shortcuts"; onClicked:root.closeRequested() }
    }
    Components.Surface {
        Layout.fillWidth:true
        Layout.preferredHeight:Config.Config.launcherSearchHeight
        Layout.minimumHeight:Config.Config.launcherSearchHeight
        color:Config.Theme.inputBackground
        radius:Config.Theme.radiusSmall
        border.width:Config.Theme.focusBorderWidth
        border.color:search.activeFocus?Config.Theme.primary:Config.Theme.border
        TextInput {
            id:search
            objectName:"keybindSearch"
            anchors.fill:parent
            anchors.margins:Config.Theme.controlPadding
            color:Config.Theme.text
            selectionColor:Config.Theme.primary
            selectedTextColor:Config.Theme.onAccent
            font.family:Config.Theme.fontFamily
            font.pixelSize:Config.Theme.fontNormal
            verticalAlignment:TextInput.AlignVCenter
            selectByMouse:true
            clip:true
            Accessible.name:"Search shortcuts by key or description"
            Keys.onTabPressed:root.cycleFocus(1)
            Keys.onBacktabPressed:root.cycleFocus(-1)
            Keys.onDownPressed:root.focusList()
            Keys.onReturnPressed:root.focusList()
            Keys.onEnterPressed:root.focusList()
            Components.StyledText {
                anchors.fill:parent
                visible:!search.text.length
                text:"Search keys or descriptions…"
                color:Config.Theme.subtext
                verticalAlignment:Text.AlignVCenter
            }
        }
    }
    RowLayout {
        Layout.fillWidth:true
        SheetButton {
            id:windowFilter
            objectName:"keybindWindowFilter"
            text:"Mode & windows"
            active:root.windowsOnly
            onClicked:root.windowsOnly=!root.windowsOnly
        }
        Item { Layout.fillWidth:true }
        SheetButton { id:refresh; objectName:"keybindRefresh"; text:"Refresh"; enabled:!catalog.loading; onClicked:catalog.refresh() }
    }
    Components.StyledText {
        Layout.fillWidth:true
        text:catalog.loading?"Reading active bindings…":(catalog.error || (root.results.length+" shortcuts · read only"))
        color:catalog.error?Config.Theme.warning:Config.Theme.subtext
        textFormat:Text.PlainText
        wrapMode:Text.Wrap
        font.pixelSize:Config.Theme.fontSmall
    }
    ListView {
        id:list
        objectName:"keybindList"
        Layout.fillWidth:true
        Layout.fillHeight:true
        enabled:count>0
        clip:true
        spacing:Config.Theme.spaceSmall
        boundsBehavior:Flickable.StopAtBounds
        keyNavigationEnabled:false
        model:ScriptModel { values:root.results }
        Keys.onUpPressed:root.moveSelection(-1)
        Keys.onDownPressed:root.moveSelection(1)
        Keys.onPressed: event => {
            if (event.key===Qt.Key_Home) { currentIndex=0; positionViewAtBeginning(); event.accepted=true }
            else if (event.key===Qt.Key_End) { currentIndex=count-1; positionViewAtEnd(); event.accepted=true }
        }
        Keys.onTabPressed:root.cycleFocus(1)
        Keys.onBacktabPressed:root.cycleFocus(-1)
        Keys.onReturnPressed: event=>event.accepted=true
        Keys.onEnterPressed: event=>event.accepted=true
        ScrollBar.vertical:Components.StyledScrollBar { policy:ScrollBar.AsNeeded }
        delegate:Components.Surface {
            id:row
            required property var modelData
            required property int index
            width:list.width
            height:cells.implicitHeight+Config.Theme.controlPadding*2
            color:list.currentIndex===index?Config.Theme.surfaceHover:Config.Theme.surface
            border.width:list.activeFocus&&list.currentIndex===index?Config.Theme.focusBorderWidth:0
            border.color:Config.Theme.primary
            Accessible.role:Accessible.StaticText
            Accessible.name:modelData.chord+": "+modelData.description+". "+modelData.detail
            MouseArea { anchors.fill:parent; onClicked: { list.currentIndex=row.index; list.forceActiveFocus() } }
            GridLayout {
                id:cells
                anchors.left:parent.left
                anchors.right:parent.right
                anchors.top:parent.top
                anchors.margins:Config.Theme.controlPadding
                columns:row.width<480?1:2
                columnSpacing:Config.Theme.spaceLarge
                rowSpacing:Config.Theme.spaceSmall
                Components.StyledText {
                    Layout.preferredWidth:cells.columns===2?220:-1
                    Layout.fillWidth:cells.columns===1
                    text:row.modelData.chord
                    textFormat:Text.PlainText
                    color:Config.Theme.primary
                    wrapMode:Text.Wrap
                }
                ColumnLayout {
                    Layout.fillWidth:true
                    spacing:Config.Theme.spaceTiny
                    Components.StyledText { Layout.fillWidth:true; text:row.modelData.description; textFormat:Text.PlainText; wrapMode:Text.Wrap }
                    Components.StyledText { Layout.fillWidth:true; text:row.modelData.detail; textFormat:Text.PlainText; color:Config.Theme.subtext; font.pixelSize:Config.Theme.fontSmall; wrapMode:Text.Wrap }
                }
            }
        }
        Components.StyledText {
            anchors.centerIn:parent
            width:parent.width
            visible:!catalog.loading&&!catalog.error&&!list.count
            text:catalog.entries.length?"No matching shortcuts":"No active shortcuts reported"
            horizontalAlignment:Text.AlignHCenter
            color:Config.Theme.subtext
            wrapMode:Text.Wrap
        }
    }
}
