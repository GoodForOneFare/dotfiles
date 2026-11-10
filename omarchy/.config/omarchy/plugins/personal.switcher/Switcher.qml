import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Commons
import "../../../../../../usr/share/omarchy/shell/plugins/menu" as Stock
import "Model.js" as Model

// Reuse the stock theme-aware menu surface, without modifying its source.
Stock.Menu {
    id: picker
    ShellIpc {
        target: "personal.switcher"
        function state(): string { return picker.state() }
    }
    // The stock surface lives in a separate PanelWindow: key releases do
    // not bubble back to this root Item. Forward its focused input's events
    // directly to our release handler, retaining the stock press handler.
    property bool releaseHandlerInstalled: false
    Item {
        id: releaseHandler
        Keys.onReleased: function(event) {
            if (picker.opened && !event.isAutoRepeat
                    && (event.key === Qt.Key_Meta || event.key === Qt.Key_Super_L
                        || event.key === Qt.Key_Super_R)) {
                event.accepted = true
                picker.open('{"action":"commit"}')
            }
        }
    }

    function installReleaseHandler(object) {
        if (!object) return false
        if (object.keyHandler !== undefined && object.keyHandler) {
            object.Keys.forwardTo = [releaseHandler, object.keyHandler]
            releaseHandlerInstalled = true
            return true
        }
        if (object.contentItem && installReleaseHandler(object.contentItem)) return true
        var children = object.data || object.children || []
        for (var i = 0; i < children.length; i++) {
            if (installReleaseHandler(children[i])) return true
        }
        return false
    }

    property var clients: []
    property var allClients: []
    property var filterApp: null
    property bool loading: false
    property bool releasePending: false
    property var queuedSteps: []

    // Native compositor shortcuts preserve press/release ordering, without
    // spawning a shell or an IPC client for every Tab press.
    GlobalShortcut {
        appid: "personal-switcher"; name: "next"; description: "Next window"
        onPressed: picker.open('{"action":"next"}')
    }
    GlobalShortcut {
        appid: "personal-switcher"; name: "previous"; description: "Previous window"
        onPressed: picker.open('{"action":"previous"}')
    }
    GlobalShortcut {
        appid: "personal-switcher"; name: "instances"; description: "Next same-app window"
        onPressed: picker.open('{"action":"instances"}')
    }
    GlobalShortcut {
        appid: "personal-switcher"; name: "commit"; description: "Select highlighted window"
        onPressed: picker.open('{"action":"commit"}')
        onReleased: picker.open('{"action":"commit"}')
    }

    function applyDmenuSelection(value) {
        var match = / · #(\d+)$/.exec(value)
        if (!match) return
        selectedIndex = Number(match[1]) - 1
        if (selectedIndex >= 0 && selectedIndex < clients.length) commit()
    }

    function state() {
        return JSON.stringify({opened: opened, loading: loading, index: selectedIndex,
                               selected: clients.length ? clients[selectedIndex].address : "",
                               app: clients.length ? clients[selectedIndex].class : "",
                               count: clients.length, allCount: allClients.length, filterApp: filterApp,
                               releaseHandlerInstalled: releaseHandlerInstalled})
    }

    function move(step, sameApp) {
        if (!clients.length) return
        var highlighted = clients[selectedIndex]
        var app = sameApp ? highlighted.class : null
        if (filterText) setFilter("")
        if (app !== filterApp) {
            var view = Model.scope(allClients, highlighted.address, app)
            filterApp = app
            clients = view.items
            dmenuOptions = Model.options(clients)
            dmenuPrompt = app === null ? "Switch window" : "Switch app windows"
            rebuildDisplay()
            selectedIndex = view.index
        }
        selectedIndex = Model.next(clients, selectedIndex, step, false)
        cursorActive = true
        disarmPointer()
        revealCursor()
    }

    function commit() {
        if (!opened || !clients.length) return
        var address = clients[selectedIndex].address
        cancel()
        // Argument array and JSON-quoted address: titles never become commands.
        Quickshell.execDetached(["python3", Quickshell.env("HOME") + "/.local/bin/window-picker",
                                "focus", address])
    }

    function open(payloadJson) {
        var payload
        try { payload = JSON.parse(payloadJson || "{}") } catch (e) { return }
        var action = payload.action || "next"
        if (action === "commit") {
            if (loading) releasePending = true
            else commit()
            return
        }
        if (action === "cancel") {
            releasePending = false
            queuedSteps = []
            loading = false
            query.running = false
            cancel()
            return
        }
        var step = action === "previous" ? -1 : 1
        var sameApp = action === "instances"
        if (opened) {
            move(step, sameApp)
        } else if (loading) {
            queuedSteps = queuedSteps.concat([{step: step, sameApp: sameApp}])
        } else {
            loading = true
            releasePending = false
            queuedSteps = [{step: step, sameApp: sameApp}]
            query.running = true
        }
    }

    Process {
        id: query
        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!picker.loading) return
                var data
                try { data = JSON.parse(text) } catch (e) { data = [] }
                picker.allClients = Model.windows(Array.isArray(data) ? data : [])
                picker.clients = picker.allClients
                picker.filterApp = null
                picker.loading = false
                if (!picker.clients.length) return
                picker.openDmenu({mode: "select", prompt: "Switch window",
                                  options: Model.options(picker.clients), width: 760, maxHeight: 650})
                picker.installReleaseHandler(picker)
                var steps = picker.queuedSteps
                picker.queuedSteps = []
                for (var i = 0; i < steps.length; i++)
                    picker.move(steps[i].step, steps[i].sameApp)
                if (picker.releasePending) picker.commit()
            }
        }
        onExited: function(code, status) {
            if (code !== 0) {
                picker.loading = false
                picker.releasePending = false
                picker.queuedSteps = []
            }
        }
    }
}
