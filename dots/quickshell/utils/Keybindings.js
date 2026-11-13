function keyName(key) {
    const aliases = {RETURN:"Enter",SPACE:"Space",SLASH:"/",ESCAPE:"Escape",PRINT:"Print",
        XF86AUDIORAISEVOLUME:"Volume Up",XF86AUDIOLOWERVOLUME:"Volume Down",XF86AUDIOMUTE:"Mute",
        XF86AUDIOMICMUTE:"Mic Mute",XF86MONBRIGHTNESSUP:"Brightness Up",XF86MONBRIGHTNESSDOWN:"Brightness Down",
        XF86AUDIONEXT:"Media Next",XF86AUDIOPREV:"Media Previous",XF86AUDIOPLAY:"Media Play",XF86AUDIOPAUSE:"Media Pause"}
    return aliases[key.toUpperCase()] || (key.length === 1 ? key.toUpperCase() : key)
}
function category(key, description) {
    if (/^XF86/i.test(key)) return "Media"
    if (/print/i.test(key)) return "Capture"
    if (/mode|workspace|monitor|window|focus|move app|previous app|next app|minimize|pseudo/i.test(description)) return "Windows"
    if (/open|launcher|float terminal/i.test(description)) return "Applications"
    return "Other"
}
function parse(text) {
    const input = JSON.parse(text)
    if (!Array.isArray(input)) throw new Error("Expected binding array")
    const modifiers = [[64,"Super"],[4,"Ctrl"],[8,"Alt"],[1,"Shift"],[2,"Caps"],[16,"Mod2"],[32,"Mod3"],[128,"Mod5"]]
    const rows = []
    input.forEach((binding, index) => {
        if (!binding || typeof binding !== "object" || !Number.isInteger(binding.modmask)
            || binding.modmask < 0 || binding.modmask > 255) return
        const rawKey = typeof binding.key === "string" ? binding.key.trim() : ""
        const key = rawKey ? keyName(rawKey) : (binding.catch_all ? "Any key"
            : (Number.isInteger(binding.keycode) && binding.keycode > 0 ? "Code " + binding.keycode : ""))
        if (!key) return
        const description = typeof binding.description === "string" && binding.description.trim()
            ? binding.description.trim() : "No description provided"
        const chord = modifiers.filter(entry => binding.modmask & entry[0]).map(entry => entry[1]).concat([key]).join(" + ")
        const flags = []
        if (binding.repeat) flags.push("Repeat")
        if (binding.release) flags.push("On release")
        if (binding.longPress) flags.push("Long press")
        if (binding.locked) flags.push("Works when locked")
        if (binding.mouse) flags.push("Mouse binding")
        const group = category(rawKey, description)
        const submap = typeof binding.submap === "string" ? binding.submap : ""
        rows.push({id:index,chord:chord,description:description,group:group,
            detail:[group,submap ? "Submap: " + submap : "",flags.join(" · ")].filter(value=>value.length).join(" · "),
            search:[chord,rawKey,description,group,submap,flags.join(" ")].join(" ").toLowerCase()})
    })
    return rows.sort((a,b)=>a.group.localeCompare(b.group)||a.chord.localeCompare(b.chord)||a.id-b.id)
}
function search(rows, query, windowsOnly) {
    const terms = query.trim().toLowerCase().split(/\s+/).filter(value=>value.length)
    return rows.filter(row=>(!windowsOnly || row.group==="Windows") && terms.every(term=>row.search.indexOf(term)>=0))
}
