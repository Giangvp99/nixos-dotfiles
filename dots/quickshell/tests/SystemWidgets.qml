// Used by run-system-widgets.py in a disposable copy, never as the live shell.
import QtQuick
import QtTest
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../modules/bar" as Bar
import "../modules/bar/popups" as Popups
import "../services" as Services
import "../utils/SystemMetrics.js" as Metrics
import "../config" as Config

ShellRoot {
    id: root
    TestEvent { id: events }
    property int assertions: 0
    function check(value, message) { if (!value) throw new Error(message); assertions++ }
    function find(node, name) {
        if (!node) return null
        if (node.objectName === name) return node
        if (node.contentItem) { const found = find(node.contentItem, name); if (found) return found }
        for (const child of (node.children || [])) { const found = find(child, name); if (found) return found }
        return null
    }
    QtObject {
        id: battery
        property bool ready: true
        property int type: UPowerDeviceType.Battery
        property bool isPresent: true
        property real percentage: 0.78
        property int state: UPowerDeviceState.Charging
        property real timeToEmpty: 0
        property real timeToFull: 3600
    }
    QtObject {
        id: power
        property var displayDevice: battery
        property bool batteryPower: false
        readonly property bool onBattery: batteryPower
    }
    Bar.Bar { id: bar; anchors.right: false; implicitWidth: 1600 }
    Popups.CalendarPopup { id: metricsPopup; preferredWidth: 150; anchorItem: root.find(bar.contentItem,"resourceUsage") }
    Component.onCompleted: {
        Services.SystemMonitor.sampler.stop()
        Services.SystemMonitor.temperatureSampler.stop()
        Services.BatteryService.backend = power
    }
    IpcHandler {
        target: "systemWidgetsTest"
        function unitTests(): string {
            const a = Metrics.cpuCounters("cpu  100 20 30 400 50 5 5 10 80 10\n")
            root.check(a.total === 620 && a.idle === 450, "guest time counted twice")
            root.check(Metrics.cpuPercent(null, a) === null, "CPU needs baseline")
            root.check(Metrics.cpuPercent(a, {total:820,idle:550}) === 50, "CPU delta")
            root.check(Metrics.cpuPercent(a, {total:1,idle:1}) === null, "CPU reset")
            root.check(Metrics.cpuPercent(a, a) === null, "zero CPU delta")
            root.check(Metrics.cpuCounters("cpu nan 1 2 3") === null, "CPU malformed")
            const m = Metrics.memory("MemTotal: 1000 kB\nMemAvailable: 250 kB\nMemFree: 5 kB")
            root.check(m.percent === 75 && m.total === 1024000 && m.used === 768000, "RAM available")
            root.check(Metrics.memory("MemTotal: 1000 kB") === null, "missing RAM available")
            root.check(Metrics.memory("MemTotal: 10 kB\nMemAvailable: 11 kB") === null, "RAM range")
            const line = "  test0: 1000 0 0 0 0 0 0 0 2000 0 0 0 0 0 0 0\n"
            const n = Metrics.networkCounters(line, "test0")
            root.check(n.rx === 1000 && n.tx === 2000, "network columns")
            root.check(Metrics.networkCounters(line, "missing") === null, "interface missing")
            root.check(Metrics.networkCounters(line.replace("test0:", "lo:"), "lo") === null, "loopback")
            root.check(Metrics.networkRates(null,n,2000,10000) === null, "network baseline")
            const rates = Metrics.networkRates(n,{name:"test0",rx:3048,tx:6096},2000,10000)
            root.check(rates.download === 1024 && rates.upload === 2048, "elapsed network time")
            root.check(Metrics.networkRates(n,{name:"other",rx:3048,tx:6096},2000,10000) === null, "interface switch")
            root.check(Metrics.networkRates(n,{name:"test0",rx:1,tx:1},2000,10000) === null, "counter reset")
            root.check(Metrics.networkRates(n,n,-100,10000) === null, "clock adjustment")
            root.check(Metrics.networkRates(n,n,12000,10000) === null, "resume gap")
            root.check(Metrics.rate(0) === "0 B/s" && Metrics.rate(1024) === "1.0 KiB/s", "rate units")
            root.check(Metrics.rate(1048576) === "1.0 MiB/s" && Metrics.rate(NaN) === "—", "rate unavailable")
            root.check(Metrics.compactRate(1024) === "1.0K/s" && Metrics.compactRate(1048576) === "1.0M/s", "compact binary rates")
            const route = "Iface Destination Gateway Flags RefCnt Use Metric Mask\neth0 00000000 1 0003 0 0 100 0\nwlan0 00000000 1 0003 0 0 600 0\n"
            root.check(Metrics.defaultInterface(route) === "eth0", "default route metric")
            root.check(Metrics.temperature("45000\n") === 45 && Metrics.temperature("0") === 0, "temperature units")
            root.check(Metrics.temperature("") === null && Metrics.temperature("-128000") === null, "invalid temperature")
            const sensors = Metrics.sensors("nvme\t/sys/class/hwmon/hwmon0/temp1_input\tComposite\ncoretemp\t/sys/class/hwmon/hwmon1/temp1_input\tPackage id 0\ncoretemp\t/sys/class/hwmon/hwmon1/temp2_input\tCore 0\n")
            root.check(sensors.length === 1 && sensors[0].driver === "coretemp", "CPU/package priority")
            root.check(!Metrics.sensorPath("/tmp/untrusted") && !Metrics.sensorPath("/sys/class/hwmon/../secret"), "sensor path allowlist")
            return "PASS " + root.assertions + " metric parser assertions"
        }
        function openMetricsPopup(): void { metricsPopup.open() }
        function shrinkRate(): void { Services.SystemMonitor.download=0;Services.SystemMonitor.upload=0 }
        function popupAnchor(): string {
            const item=metricsPopup.anchorItem
            const point=item.mapToItem(bar.contentItem,item.width,0)
            return JSON.stringify({visible:metricsPopup.visible,x:metricsPopup.anchor.rect.x,expected:Math.max(8,Math.round(point.x-metricsPopup.width))})
        }
        function closeMetricsPopup(): void { metricsPopup.close(false) }
        function widgetState(): string {
            const widgets=["networkSpeed","resourceUsage","temperatureStatus","batteryStatus"].map(name=>{
                const item=root.find(bar.contentItem,name)
                return {name:name,text:item.text,visible:item.visible,width:item.width,x:item.mapToItem(bar.contentItem,0,0).x,foreground:String(item.foreground),icon:item.icon}
            })
            return JSON.stringify({widgets:widgets,cpuIcon:root.find(bar.contentItem,"cpuSymbol").text,ramIcon:root.find(bar.contentItem,"ramSymbol").text,warning:String(Config.Theme.warning),critical:String(Config.Theme.urgent),normal:String(Config.Theme.controlForeground)})
        }
        function availability(name: string): void {
            const monitor=Services.SystemMonitor
            monitor.networkAvailable=false;monitor.cpuAvailable=false;monitor.memory=null;monitor.temperatures=[]
            battery.isPresent=false
            if(name==="memory")monitor.memory=Metrics.memory("MemTotal: 1000 kB\nMemAvailable: 250 kB")
            if(name==="cpu"){monitor.cpuAvailable=true;monitor.cpuPercent=0}
            if(name==="idleNetwork"){monitor.networkAvailable=true;monitor.download=0;monitor.upload=0}
        }
        function metrics(): void {
            const monitor = Services.SystemMonitor
            monitor.previousCpu = null
            monitor.acceptCpu("cpu 100 0 0 100 0 0 0 0")
            monitor.acceptCpu("cpu 195 0 0 105 0 0 0 0")
            monitor.memory = Metrics.memory("MemTotal: 1000 kB\nMemAvailable: 80 kB")
            monitor.previousNetwork = null
            monitor.acceptNetwork("test0: 1000 0 0 0 0 0 0 0 2000 0 0 0 0 0 0 0",1000)
            monitor.acceptNetwork("test0: 2098152 0 0 0 0 0 0 0 1050576 0 0 0 0 0 0 0",3000)
        }
        function powerCase(name: string): void {
            battery.ready = true; battery.isPresent = true; battery.type = UPowerDeviceType.Battery
            battery.percentage = 0.78; power.batteryPower = false; battery.state = UPowerDeviceState.Charging
            switch(name) {
            case "full": battery.percentage=1; battery.state=UPowerDeviceState.FullyCharged; break
            case "paused": battery.state=UPowerDeviceState.PendingCharge; break
            case "low": battery.percentage=0.1; power.batteryPower=true; battery.state=UPowerDeviceState.Discharging; break
            case "critical": battery.percentage=0.04; power.batteryPower=true; battery.state=UPowerDeviceState.Discharging; break
            case "tiny": battery.percentage=0.005; power.batteryPower=true; battery.state=UPowerDeviceState.Discharging; break
            case "acDrain": battery.percentage=0.1; battery.state=UPowerDeviceState.Discharging; break
            case "unknown": battery.state=UPowerDeviceState.Unknown; break
            case "absent": battery.isPresent=false; break
            case "mouse": battery.type=UPowerDeviceType.Mouse; break
            case "unready": battery.ready=false; break
            case "invalid": battery.percentage=NaN; break
            }
        }
        function resize(width: int): void { bar.implicitWidth = width }
        function wheelMetrics(): bool {
            const view=root.find(bar.contentItem,"barMetricsViewport")
            view.contentX=0
            const item=root.find(bar.contentItem,"networkSpeed")
            return events.mouseWheel(item,item.width/2,item.height/2,Qt.NoButton,Qt.NoModifier,0,-120,0)
        }
        function wheelAudio(): string {
            const view=root.find(bar.contentItem,"barMetricsViewport")
            view.contentX=Math.max(0,view.contentWidth-view.width)
            let audio=null
            function search(node){if(node.wheelEvents!==undefined)audio=node;for(const child of (node.children||[]))search(child)}
            search(bar.contentItem)
            const before=view.contentX
            const delivered=audio && events.mouseWheel(audio,audio.width/2,audio.height/2,Qt.NoButton,Qt.NoModifier,0,120,0)
            return JSON.stringify({delivered:delivered,count:audio?audio.wheelEvents:0,before:before,after:view.contentX})
        }
        function scrollEnd(): void {
            const view=root.find(bar.contentItem,"barMetricsViewport")
            view.contentX=Math.max(0,view.contentWidth-view.width)
        }
        function rescan(): void { Services.SystemMonitor.discovery.running=true }
        function reloadSensors(): void {
            const views=Services.SystemMonitor.sensorViews
            for(let i=0;i<views.count;i++)views.objectAt(i).reload()
        }
        function state(): string {
            const m=Services.SystemMonitor, b=Services.BatteryService
            const essential=["barNotifications","barDate","barClock","barKeyboard","barPowerMenu"].map(name=>{
                const item=root.find(bar.contentItem,name), point=item.mapToItem(bar.contentItem,0,0)
                return {name:name,x:point.x,width:item.width,visible:item.visible}
            })
            const view=root.find(bar.contentItem,"barMetricsViewport")
            return JSON.stringify({cpu:m.cpuPercent,cpuAvailable:m.cpuAvailable,memory:m.memoryPercent,
                network:m.networkAvailable,download:m.download,upload:m.upload,temperature:m.temperature,
                temperatureAvailable:m.temperatureAvailable,temperatures:m.temperatures,sensors:m.sensors,
                battery:{available:b.available,known:b.percentageKnown,percent:b.percent,charging:b.charging,
                    plugged:b.pluggedIn,onBattery:b.onBattery,status:b.statusText,low:b.low,critical:b.critical},
                barWidth:bar.width,rightInset:Config.Config.barOuterMargin+Config.Config.barHorizontalPadding,essential:essential,keyboardLanguage:Services.InputMethodService.language,viewport:[view.width,view.contentWidth,view.contentX]})
        }
    }
}
