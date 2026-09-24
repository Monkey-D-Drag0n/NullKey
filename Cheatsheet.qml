import QtQuick

// Public component entry point for embedding the explorer in another QML shell.
Item {
    id: root
    property string environment: "Hyprland"
    property string target: "Hyprland"
    property var shortcuts: []
}
