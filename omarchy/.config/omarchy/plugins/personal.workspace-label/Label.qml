import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons

// One dim label per display, on the layer just above the wallpaper and below
// every window. It never takes keyboard or pointer input.
Item {
    id: root
    property var shell: null

    function label(workspace) {
        if (!workspace) return ""
        var name = String(workspace.name || workspace.id || "")
        // Special (scratchpad) workspaces overlay another; keep that one's label.
        if (!name || name.indexOf("special:") === 0) return ""
        return "Workspace " + name.slice(0, 64)
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            readonly property var monitor: Hyprland.monitorFor(modelData)

            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "personal-workspace-label"
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            // Empty input region: clicks fall through to the desktop.
            mask: Region {}

            Text {
                anchors.centerIn: parent
                textFormat: Text.PlainText
                text: root.label(monitor ? monitor.activeWorkspace : null)
                color: "#3c3c3c"
                font.family: Style.fontFamily
                font.pixelSize: 44
                font.letterSpacing: 2
            }
        }
    }
}
