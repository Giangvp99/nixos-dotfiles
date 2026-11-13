pragma Singleton
import QtQuick
import QtQml.Models
import Quickshell.Io
import "../config" as Config
import "../utils/SystemMetrics.js" as Metrics

QtObject {
    id: root
    readonly property int historyLimit: 90
    readonly property int historyWindowMs: Math.max(1000, Config.Config.metricsInterval) * historyLimit
    property var cpuHistory: []
    property var memoryHistory: []
    property var historyMemory: null
    onCpuHistoryChanged: if (historyMemory) historyMemory.cpuJson=JSON.stringify(cpuHistory)
    onMemoryHistoryChanged: if (historyMemory) historyMemory.memoryJson=JSON.stringify(memoryHistory)
    function restoreHistory(value) {
        try {
            const data=JSON.parse(value), now=Date.now()
            return Array.isArray(data) ? data.filter(point => point && Number.isFinite(point.at)
                && point.at<=now && point.at>=now-historyWindowMs
                && (point.value===null || (Number.isFinite(point.value) && point.value>=0 && point.value<=100)))
                .sort((a,b)=>a.at-b.at).slice(-historyLimit) : []
        } catch (_) { return [] }
    }
    function attachHistory(memory) {
        const cpu=restoreHistory(memory.cpuJson), ram=restoreHistory(memory.memoryJson)
        historyMemory=memory
        if (cpu.length) cpuHistory=cpu
        if (ram.length) memoryHistory=ram
    }
    function appendHistory(series, value, now) {
        if (!Number.isFinite(value) || value<0 || value>100) value=null
        return series.filter(point=>point.at<now && point.at>=now-historyWindowMs)
            .concat([{at:now,value:value}]).slice(-historyLimit)
    }
    function acceptMemory(text) {
        memory=Metrics.memory(text)
        memoryHistory=appendHistory(memoryHistory,memory ? memory.percent : null,Date.now())
    }
    property bool cpuAvailable: false
    property int cpuPercent: 0
    property var memory: null
    readonly property bool memoryAvailable: memory !== null
    readonly property int memoryPercent: memory ? memory.percent : 0
    property bool networkAvailable: false
    property real download: 0
    property real upload: 0
    property string routeInterface: ""
    readonly property string managedInterface: NetworkService.connectedDevice
        && NetworkService.connectedDevice.name !== "lo" ? NetworkService.connectedDevice.name : ""
    readonly property string networkInterface: Config.Config.networkRateInterface
        || routeInterface || managedInterface
    property var previousCpu: null
    property var previousNetwork: null
    property real previousNetworkTime: 0
    property var sensorRecords: []
    readonly property var sensors: Config.Config.temperatureSensorPaths.length
        ? Config.Config.temperatureSensorPaths.filter(Metrics.sensorPath).slice(0, 32).map(path => ({path:path,driver:"Custom",label:""}))
        : sensorRecords
    property var temperatures: []
    onSensorsChanged: temperatures = []
    readonly property bool temperatureAvailable: temperatures.length > 0
    readonly property real temperature: temperatureAvailable ? Math.max(...temperatures) : 0
    readonly property string temperatureSources: sensors.map(sensor => sensor.driver + (sensor.label ? " · " + sensor.label : "")).join(", ")

    onNetworkInterfaceChanged: { previousNetwork = null; networkAvailable = false }
    function acceptCpu(text) {
        const current = Metrics.cpuCounters(text)
        const value = Metrics.cpuPercent(previousCpu, current)
        previousCpu = current
        cpuAvailable = value !== null
        cpuPercent = value === null ? 0 : value
        cpuHistory=appendHistory(cpuHistory,value,Date.now())
    }
    function acceptNetwork(text, now) {
        const current = Metrics.networkCounters(text, networkInterface)
        const rates = Metrics.networkRates(previousNetwork, current, now - previousNetworkTime,
            Math.max(1000, Config.Config.metricsInterval) * 5)
        previousNetwork = current
        previousNetworkTime = now
        networkAvailable = rates !== null
        download = rates ? rates.download : 0
        upload = rates ? rates.upload : 0
    }
    function sample() {
        if (Config.Config.showResourceUsage) { cpuFile.reload(); memoryFile.reload() }
        if (Config.Config.showNetworkSpeed) {
            if (!Config.Config.networkRateInterface) routeFile.reload()
            networkFile.reload()
        }
    }
    function refreshTemperatures() {
        let values = []
        for (let i = 0; i < sensorViews.count; ++i) {
            const file = sensorViews.objectAt(i)
            if (file && file.valid) values.push(file.celsius)
        }
        temperatures = values
    }
    readonly property FileView cpuFile: FileView {
        path: "/proc/stat"; preload: Config.Config.showResourceUsage; printErrors: false
        onLoaded: root.acceptCpu(text())
        onLoadFailed: {
            root.previousCpu=null; root.cpuAvailable=false
            root.cpuHistory=root.appendHistory(root.cpuHistory,null,Date.now())
        }
    }
    readonly property FileView memoryFile: FileView {
        path: "/proc/meminfo"; preload: Config.Config.showResourceUsage; printErrors: false
        onLoaded: root.acceptMemory(text())
        onLoadFailed: {
            root.memory=null
            root.memoryHistory=root.appendHistory(root.memoryHistory,null,Date.now())
        }
    }
    readonly property FileView routeFile: FileView {
        path: "/proc/net/route"; preload: Config.Config.showNetworkSpeed; printErrors: false
        onLoaded: root.routeInterface = Metrics.defaultInterface(text())
        onLoadFailed: root.routeInterface = ""
    }
    readonly property FileView networkFile: FileView {
        path: "/proc/net/dev"; preload: Config.Config.showNetworkSpeed; printErrors: false
        onLoaded: root.acceptNetwork(text(), Date.now())
        onLoadFailed: { root.previousNetwork = null; root.networkAvailable = false }
    }
    readonly property Timer sampler: Timer {
        interval: Math.max(1000, Config.Config.metricsInterval)
        repeat: true
        running: Config.Config.showResourceUsage || Config.Config.showNetworkSpeed
        onTriggered: root.sample()
    }
    readonly property Instantiator sensorViews: Instantiator {
        model: Config.Config.showTemperature ? root.sensors : []
        onObjectAdded: Qt.callLater(root.refreshTemperatures)
        onObjectRemoved: Qt.callLater(root.refreshTemperatures)
        delegate: FileView {
            required property var modelData
            property bool valid: false
            property real celsius: 0
            path: modelData.path
            preload: true
            printErrors: false
            onLoaded: {
                const value = Metrics.temperature(text())
                valid = value !== null
                celsius = value === null ? 0 : value
                root.refreshTemperatures()
            }
            onLoadFailed: { valid = false; root.refreshTemperatures() }
        }
    }
    readonly property Timer temperatureSampler: Timer {
        interval: Math.max(2000, Config.Config.temperatureInterval)
        repeat: true
        running: Config.Config.showTemperature && sensorViews.count > 0
        onTriggered: {
            for (let i = 0; i < sensorViews.count; ++i) {
                const file = sensorViews.objectAt(i)
                if (file) file.reload()
            }
        }
    }
    readonly property Process discovery: Process {
        // Literal script; no configured value is interpolated into shell code.
        command: ["sh", "-c", `
for base in /sys/class/hwmon/hwmon*; do
    [ -d "$base" ] || continue
    name=Sensor; IFS= read -r name < "$base/name"
    for path in "$base"/temp*_input; do
        [ -r "$path" ] || continue
        label=; labelpath="\${path%_input}_label"
        if [ -r "$labelpath" ]; then IFS= read -r label < "$labelpath"; fi
        printf '%s\\t%s\\t%s\\n' "$name" "$path" "$label"
    done
done
for base in /sys/class/thermal/thermal_zone*; do
    [ -r "$base/temp" ] || continue
    name=Sensor; IFS= read -r name < "$base/type"
    printf '%s\\t%s\\t\\n' "$name" "$base/temp"
done`]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = Metrics.sensors(text)
                if (JSON.stringify(found) !== JSON.stringify(root.sensorRecords)) root.sensorRecords = found
            }
        }
    }
    readonly property Timer discoverySampler: Timer {
        interval: 60000
        repeat: true
        running: Config.Config.showTemperature && !Config.Config.temperatureSensorPaths.length
        onTriggered: if (!discovery.running) discovery.running = true
    }
    Component.onCompleted: {
        if (Config.Config.showTemperature && !Config.Config.temperatureSensorPaths.length) discovery.running = true
    }
}
