import QtQuick
import "../config" as Config

Canvas {
    id: root
    property var series: []
    property int windowMs: 180000
    property int maximumGap: 6000
    property color lineColor: Config.Theme.primary
    property int segments: 0
    implicitHeight: 90
    onSeriesChanged: if (visible) requestPaint()
    onVisibleChanged: if (visible) requestPaint()
    onWidthChanged: if (visible) requestPaint()
    onHeightChanged: if (visible) requestPaint()
    onAvailableChanged: if (available && visible) requestPaint()
    onPaint: {
        const ctx=getContext("2d")
        ctx.reset()
        ctx.clearRect(0,0,width,height)
        ctx.strokeStyle=Config.Theme.border
        ctx.lineWidth=1
        for (const fraction of [0, .5, 1]) {
            const y=2+(height-4)*fraction
            ctx.beginPath(); ctx.moveTo(0,y); ctx.lineTo(width,y); ctx.stroke()
        }
        segments=0
        if (!series.length) return
        const end=series[series.length-1].at, start=end-windowMs
        let previous=null
        ctx.strokeStyle=lineColor
        ctx.lineWidth=2
        ctx.lineJoin="round"
        ctx.beginPath()
        for (const point of series) {
            if (point.at<start) continue
            if (point.value===null || !Number.isFinite(point.value)) { previous=null; continue }
            const x=(point.at-start)/windowMs*width, y=2+(100-point.value)/100*(height-4)
            if (!previous || point.at-previous.at>maximumGap) { ctx.moveTo(x,y); segments++ }
            else ctx.lineTo(x,y)
            previous=point
        }
        ctx.stroke()
        if (previous) {
            const x=(previous.at-start)/windowMs*width, y=2+(100-previous.value)/100*(height-4)
            ctx.beginPath(); ctx.arc(Math.min(width-2,x),y,2,0,Math.PI*2); ctx.fillStyle=lineColor; ctx.fill()
        }
    }
}
