import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Item {
    id: root
    property var shortcuts: []
    property color accent: "#88c0d0"
    signal shortcutChosen(var item)
    GridLayout {
        anchors.fill: parent
        columns: width > 850 ? 2 : 1
        columnSpacing: 12
        rowSpacing: 10
        Repeater {
            model: root.shortcuts
            delegate: ShortcutCard {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 78
                shortcut: modelData
                accent: root.accent
                onChosen: function(item) { root.shortcutChosen(item) }
            }
        }
    }
}
