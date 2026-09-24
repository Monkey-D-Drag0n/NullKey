import QtQuick
import "../components"

Item {
    id: root
    property var pressedKeys: []
    property string keyboardPlatform: "Windows / Linux"
    property string keyboardLayout: "Full-size"
    property color accent: "#88c0d0"
    signal keyToggled(string code)
    Keyboard {
        anchors.fill: parent
        pressedKeys: root.pressedKeys
        keyboardPlatform: root.keyboardPlatform
        keyboardLayout: root.keyboardLayout
        accent: root.accent
        onKeyToggled: function(code) { root.keyToggled(code) }
    }
}
