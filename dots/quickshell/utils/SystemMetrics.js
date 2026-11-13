.pragma library

function cpuCounters(text) {
    const line = text.split("\n").find(line => /^cpu\s/.test(line))
    if (!line) return null
    // guest/guest_nice are already included in user/nice. Do not count them twice.
    const values = line.trim().split(/\s+/).slice(1, 9).map(Number)
    if (values.length < 4 || values.some(n => !Number.isFinite(n) || n < 0)) return null
    return {total: values.reduce((sum, n) => sum + n, 0), idle: values[3] + (values[4] || 0)}
}
function cpuPercent(previous, current) {
    if (!previous || !current) return null
    const total = current.total - previous.total
    const idle = current.idle - previous.idle
    if (total <= 0 || idle < 0 || idle > total) return null
    return Math.round((total - idle) / total * 100)
}
function memory(text) {
    const values = {}
    for (const line of text.split("\n")) {
        const match = /^(MemTotal|MemAvailable):\s+(\d+)\s+kB/.exec(line)
        if (match) values[match[1]] = Number(match[2]) * 1024
    }
    const total = values.MemTotal, available = values.MemAvailable
    if (!Number.isFinite(total) || total <= 0 || !Number.isFinite(available)
        || available < 0 || available > total) return null
    return {total: total, used: total - available, percent: Math.round((total - available) / total * 100)}
}
function networkCounters(text, name) {
    if (!name || name === "lo") return null
    for (const line of text.split("\n")) {
        const separator = line.lastIndexOf(":")
        if (separator < 0 || line.slice(0, separator).trim() !== name) continue
        const fields = line.slice(separator + 1).trim().split(/\s+/)
        if (fields.length < 16) return null
        const rx = Number(fields[0]), tx = Number(fields[8])
        if (![rx, tx].every(n => Number.isSafeInteger(n) && n >= 0)) return null
        return {rx: rx, tx: tx, name: name}
    }
    return null
}
function networkRates(previous, current, elapsedMs, maximumGap) {
    if (!previous || !current || previous.name !== current.name || elapsedMs <= 0
        || elapsedMs > maximumGap || current.rx < previous.rx || current.tx < previous.tx) return null
    return {download: (current.rx - previous.rx) * 1000 / elapsedMs,
            upload: (current.tx - previous.tx) * 1000 / elapsedMs}
}
function defaultInterface(text) {
    let selected = "", metric = Infinity
    for (const line of text.trim().split("\n").slice(1)) {
        const fields = line.trim().split(/\s+/)
        if (fields.length < 8 || fields[1] !== "00000000" || fields[0] === "lo") continue
        const flags = parseInt(fields[3], 16), cost = Number(fields[6])
        if ((flags & 1) && Number.isFinite(cost) && cost < metric) { selected = fields[0]; metric = cost }
    }
    return selected
}
function rate(bytes) {
    if (!Number.isFinite(bytes) || bytes < 0) return "—"
    const units = ["B/s", "KiB/s", "MiB/s", "GiB/s", "TiB/s"]
    let unit = 0
    while (bytes >= 1024 && unit < units.length - 1) { bytes /= 1024; unit++ }
    return (unit > 0 && bytes < 10 ? bytes.toFixed(1) : Math.round(bytes)) + " " + units[unit]
}
function temperature(raw) {
    const value = Number(raw.trim()) / 1000
    return raw.trim().length && Number.isFinite(value) && value >= -40 && value <= 150 ? value : null
}
function sensorPath(path) {
    return /^\/sys\/class\/(hwmon\/hwmon\d+\/temp\d+_input|thermal\/thermal_zone\d+\/temp)$/.test(path)
}
function sensors(text) {
    const rows = text.trim().split("\n").map(line => {
        const fields = line.split("\t")
        return {driver: fields[0] || "Sensor", path: fields[1] || "", label: fields[2] || ""}
    }).filter(row => sensorPath(row.path))
    const cpu = rows.filter(row => /coretemp|k10temp|zenpower|cpu|x86_pkg_temp/i.test(row.driver))
    const packages = cpu.filter(row => /package|tctl|tdie|cpu/i.test(row.label))
    return (packages.length ? packages : (cpu.length ? cpu : rows)).slice(0, 32)
}

// Compact bar units are binary too; accessible descriptions retain full units.
function compactRate(bytes) {
    return rate(bytes).replace(" B/s", "B/s").replace(" KiB/s", "K/s")
        .replace(" MiB/s", "M/s").replace(" GiB/s", "G/s").replace(" TiB/s", "T/s")
}
