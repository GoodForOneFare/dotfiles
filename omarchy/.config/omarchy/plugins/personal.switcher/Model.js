// Plain JavaScript so navigation can be regression-tested outside QML.
function plain(value) {
    return String(value || "").replace(/[<>]/g, function(c) { return c === "<" ? "＜" : "＞"; })
        .replace(/\s+/g, " ").slice(0, 512);
}
function windows(clients) {
    return clients.filter(function(w) {
        return w.mapped && w.acceptsInput !== false && w.class !== "org.omarchy.screensaver"
            && /^0x[0-9a-f]+$/i.test(w.address || "");
    }).slice(0, 500).sort(function(a, b) {
        return (a.focusHistoryID >= 0 ? a.focusHistoryID : 9999)
            - (b.focusHistoryID >= 0 ? b.focusHistoryID : 9999);
    });
}
function next(items, index, step, sameApp) {
    if (!items.length) return 0;
    var app = items[index].class;
    for (var n = 1; n <= items.length; n++) {
        var candidate = (index + step * n + items.length * n) % items.length;
        if (!sameApp || items[candidate].class === app) return candidate;
    }
    return index;
}
function scope(items, address, app) {
    var visible = app === null ? items : items.filter(function(w) { return w.class === app; });
    var index = visible.findIndex(function(w) { return w.address === address; });
    return {items: visible, index: index < 0 ? 0 : index};
}
function options(items) {
    var names = {"com.mitchellh.ghostty": "Ghostty", "google-chrome": "Chrome", "slack": "Slack"};
    return items.map(function(w, i) {
        return "\uf2d0\t" + plain(names[w.class] || w.class || "Window") + "\t"
            + plain(w.title || "Untitled") + " — workspace "
            + plain((w.workspace || {}).name || "?") + " · #" + (i + 1);
    });
}
