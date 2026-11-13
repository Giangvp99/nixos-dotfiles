import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../components" as Components
import "../../config" as Config
import "../../services" as Services

DashboardCard {
    id: root
    title: "Quick notes"
    property var notes: Services.NotesService
    property var focusController: null
    property real editorHeight: 160
    signal focusRequested(var item)
    function focusTargets() { return [editor, save].filter(item => item.enabled && item.visible) }
    ScrollView {
        Layout.fillWidth: true
        Layout.preferredHeight: root.editorHeight
        clip: true
        ScrollBar.vertical: Components.StyledScrollBar { policy: ScrollBar.AsNeeded }
        ScrollBar.horizontal: Components.StyledScrollBar { policy: ScrollBar.AlwaysOff }
        TextArea {
            id: editor
            objectName: "quickNotesEditor"
            text: root.notes.text
            textFormat: TextEdit.PlainText
            placeholderText: "Write something to remember…"
            readOnly: !root.notes.ready
            wrapMode: TextEdit.Wrap
            selectByMouse: true
            color: Config.Theme.text
            placeholderTextColor: Config.Theme.subtext
            selectionColor: Config.Theme.controlSelected
            selectedTextColor: Config.Theme.onAccent
            font.family: Config.Theme.fontFamily
            font.pixelSize: Config.Theme.fontNormal
            padding: Config.Theme.controlPadding
            Accessible.name: "Quick notes"
            background: Components.Surface {
                color: Config.Theme.inputBackground
                border.width: 1
                border.color: editor.activeFocus ? Config.Theme.controlSelected : Config.Theme.border
            }
            onTextChanged: if (root.notes.ready && text !== root.notes.text) root.notes.update(text)
            onActiveFocusChanged: {
                if (activeFocus) root.focusRequested(this)
                else root.notes.save()
            }
            Keys.onTabPressed: if (root.focusController) root.focusController.cycleFocus(1)
            Keys.onBacktabPressed: if (root.focusController) root.focusController.cycleFocus(-1)
            Keys.onPressed: event => {
                if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_S) {
                    root.notes.save()
                    event.accepted = true
                }
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Components.StyledText {
            Layout.fillWidth: true
            text: root.notes.error || (!root.notes.ready ? "Loading…" : root.notes.writing ? "Saving…" : root.notes.dirty ? "Unsaved" : "Saved locally")
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            color: Config.Theme.subtext
            font.pixelSize: Config.Theme.fontSmall
        }
        Components.IconButton {
            id: save
            objectName: "quickNotesSave"
            text: root.notes.error ? "Retry" : "Save"
            enabled: !root.notes.writing && (root.notes.error.length > 0 || root.notes.dirty)
            focusController: root.focusController
            onClicked: root.notes.error ? root.notes.retry() : root.notes.save()
            onActiveFocusChanged: if (activeFocus) root.focusRequested(this)
        }
    }
    Component.onDestruction: root.notes.save()
}
