import QtQuick
import QtTest
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../modules/notifications" as Notifications
import "../components" as Components
import "../services" as Services

ShellRoot {
    id: root
    TestEvent { id: events }
    property string longTitle: "Long notification title — Tiếng Việt và nội dung cần đọc đầy đủ. ".repeat(4)
    property string longBody: Array.from({length:160},(_,i)=>"Line "+i+" — Tiếng Việt: nội dung thông báo dài cần đọc đầy đủ, không bị cắt. ").join("\n") + "\nEND OF NOTIFICATION ✓"
    property var note: ({id:901,appName:"Reading fixture",appIcon:"",summary:longTitle,body:longBody,
        urgency:1,transient:false,lastGeneration:false,tracked:true,actions:[{identifier:"default",text:"Open"}]})
    function find(node,name) {
        if (!node) return null
        if (node.objectName===name) return node
        if (node.contentItem) { const item=find(node.contentItem,name);if(item)return item }
        for (const child of (node.children||[])) { const item=find(child,name);if(item)return item }
        return null
    }
    PersistentProperties {
        id: memory
        reloadableId: "notification-reading-test"
        property string historyJson: "[]"
        property string detailsJson: "{}"
        property bool dnd: false
        property int generation: 0
        onLoaded: { Services.NotificationState.attachMemory(memory);generation++ }
    }
    QtObject {
        id: fake
        property var records: [{notification:root.note}]
        property int invoked: 0
        function invokeId(id,identifier) { invoked++;return true }
        function dismissId(id) { records=records.filter(record=>record.notification.id!==id) }
        function expireId(id) {}
        function suppressToasts(value) {}
    }
    Component.onCompleted: {
        Services.NotificationState.service=fake
        Qt.callLater(root.seed)
    }
    function seed() { if (!Services.NotificationState.history.length) Services.NotificationState.snapshot(note,false,true) }
    PanelWindow {
        id: bar
        anchors.top: true
        implicitWidth: 450
        implicitHeight: 40
        exclusionMode: ExclusionMode.Ignore
        focusable: false
        color: "transparent"
        Components.IconButton { id: anchor; x:380; text:"Bell"; onClicked: center.toggle() }
    }
    Notifications.NotificationCenter { id: center;anchorItem: anchor }
    Notifications.ToastCard {
        id: toast
        visible: false
        width: 380
        record: ({notification:root.note})
    }
    IpcHandler {
        target: "notificationReadingTest"
        function open(): void { center.open() }
        function focusRow(): void { center.focusRow(0) }
        function close(): void { center.close(false) }
        function key(name: string): bool {
            const keys={Down:Qt.Key_Down,PageDown:Qt.Key_PageDown,PageUp:Qt.Key_PageUp,Tab:Qt.Key_Tab,Escape:Qt.Key_Escape,Return:Qt.Key_Return}
            const surface=root.find(center.contentItem,"notificationFixtureSurface")
            if (center.reading) center.focusReader()
            else {
                const list=root.find(center.contentItem,"notificationHistoryList")
                if (center.listHadFocus && list.currentItem) list.currentItem.forceActiveFocus()
                else surface.forceActiveFocus()
            }
            return surface.fixtureEvents.keyClick(keys[name],0,0)
        }
        function clickPreview(): bool {
            const list=root.find(center.contentItem,"notificationHistoryList")
            const body=root.find(list.currentItem,"notificationPreviewBody")
            return events.mouseClick(body,20,10,Qt.LeftButton,0,0)
        }
        function wheel(): bool {
            const scroll=root.find(center.contentItem,"notificationReaderScroll")
            return events.mouseWheel(scroll,20,30,Qt.NoButton,Qt.NoModifier,0,-120,0)
        }
        function end(): void {
            const scroll=root.find(center.contentItem,"notificationReaderScroll")
            scroll.contentY=Math.max(0,scroll.contentHeight-scroll.height)
        }
        function invokeAction(): bool {
            const scroll=root.find(center.contentItem,"notificationReaderScroll")
            const action=root.find(scroll,"notificationAction_default")
            if (!action) return false
            action.clicked();return true
        }
        function removeReading(): void { Services.NotificationState.removeHistory(center.readingId) }
        function archive(): void { fake.records=[];Services.NotificationState.closed(901) }
        function budget(): bool {
            for (const id of [903,904]) Services.NotificationState.snapshot({id:id,appName:"Budget",appIcon:"",summary:"Budget "+id,body:"x".repeat(1100000),urgency:1,transient:false,lastGeneration:false},false,true)
            const state=Services.NotificationState
            return state.history.length===1 && state.history[0].id===904 && state.history[0].body.length===8192
                && state.detailFor(904).body.length===1100000 && !state.fullDetails["903"] && !state.fullDetails["901"]
        }
        function legacy(): bool {
            const state=Services.NotificationState
            const entry={id:905,appName:"Legacy",appIcon:"",summary:"Legacy full text",body:root.longBody,
                bodyTruncated:false,summaryTruncated:false,receivedAt:Date.now(),urgency:1,unread:false,live:false}
            memory.detailsJson="{}";memory.historyJson=JSON.stringify([entry]);state.attachMemory(memory)
            const migrated=state.entryFor(905).body.length===8192 && state.detailFor(905).body===root.longBody && state.detailFor(905).fullAvailable
            state.clearHistory()
            entry.id=906;entry.body="Old partial preview";entry.bodyTruncated=true
            memory.historyJson=JSON.stringify([entry]);state.attachMemory(memory)
            const honest=!state.detailFor(906).fullAvailable
            state.clearHistory()
            return migrated && honest
        }
        function clear(): bool { Services.NotificationState.clearHistory();return Object.keys(Services.NotificationState.fullDetails).length===0 }
        function status(): string {
            const list=root.find(center.contentItem,"notificationHistoryList")
            const item=list ? list.currentItem : null
            const scroll=root.find(center.contentItem,"notificationReaderScroll")
            const body=root.find(scroll,"notificationBody"),summary=root.find(scroll,"notificationSummary")
            const preview=root.find(item,"notificationPreviewBody")
            const full=Services.NotificationState.detailFor(901)
            return JSON.stringify({opened:center.visible,reading:center.reading,readingId:center.readingId,itemFocus:item ? item.activeFocus : false,listFocus:center.listHadFocus,generation:memory.generation,count:Services.NotificationState.history.length,
                backFocus:root.find(center.contentItem,"notificationReaderBack") ? root.find(center.contentItem,"notificationReaderBack").activeFocus : false,width:center.width,stored:Services.NotificationState.entryFor(901) ? Services.NotificationState.entryFor(901).body.length : 0,
                expected:root.longBody.length,fullStored:full ? full.body.length : 0,fullAvailable:full ? full.fullAvailable : false,
                bodyLength:body ? body.text.length : 0,bodyHeight:body ? body.implicitHeight : 0,
                fullSummary:summary ? summary.text===root.longTitle && summary.truncated===false : false,
                previewHeight:item ? item.height : 0,previewLines:preview ? preview.maximumLineCount : 0,
                scroll:scroll ? scroll.contentY : 0,readerHeight:scroll ? scroll.height : 0,
                bodyEnd:body ? body.mapToItem(scroll,0,body.height).y : 0,
                toastLimited:root.find(toast,"notificationSummary").maximumLineCount===2 && !toast.expandedContent,
                live:Services.NotificationState.liveNotification(901)!==null,invoked:fake.invoked})
        }
    }
}
