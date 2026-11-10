.pragma library

function normalize(value) {
    return (value || "").toString().trim().toLowerCase().replace(/\s+/g, " ");
}

function normalizeId(value) {
    return normalize(value).replace(/\.desktop$/, "");
}

// Precompute only when the desktop catalog changes, rather than on each key.
function indexApplications(apps) {
    return apps.filter(app => app && app.name).map(app => ({
        app: app,
        id: normalizeId(app.id),
        name: normalize(app.name),
        generic: normalize(app.genericName),
        keywords: normalize((app.keywords || []).join(" "))
    }));
}

function nameScore(name, query) {
    if (name === query) return 0;
    if (name.startsWith(query)) return 1;
    if (name.split(/\s+/).some(word => word.startsWith(query))) return 2;
    if (name.includes(query)) return 3;
    return -1;
}

function search(index, query, pinnedIds, limit) {
    const wanted = normalize(query);
    const pins = pinnedIds.map(normalizeId);
    const matches = [];
    for (const entry of index) {
        let score = 0;
        if (wanted.length > 0) {
            score = nameScore(entry.name, wanted);
            if (score < 0 && entry.generic.includes(wanted)) score = 4;
            if (score < 0 && entry.keywords.includes(wanted)) score = 5;
            if (score < 0 && entry.id.includes(wanted)) score = 6;
            if (score < 0) continue;
        }
        matches.push({entry: entry, score: score, pin: pins.indexOf(entry.id)});
    }
    matches.sort((a, b) => {
        if (!wanted.length) {
            const ap = a.pin < 0 ? pins.length : a.pin;
            const bp = b.pin < 0 ? pins.length : b.pin;
            if (ap !== bp) return ap - bp;
        }
        if (a.score !== b.score) return a.score - b.score;
        const byName = a.entry.name.localeCompare(b.entry.name);
        return byName || a.entry.id.localeCompare(b.entry.id);
    });
    return matches.slice(0, Math.max(0, limit)).map(match => match.entry.app);
}
