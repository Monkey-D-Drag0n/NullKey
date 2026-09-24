import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    property string label: ""
    property string code: ""
    property real keyWidth: 1
    property real unit: 30
    property bool active: false
    property color accent: "#88c0d0"
    property color keyColor: "#1b2430"
    property color borderColor: "#394656"
    property color textColor: "#bac6d5"
    property string readableName: ""
    property string uiFontFamily: "Sans Serif"
    property bool animationsEnabled: true
    readonly property var readableNames: ({
        "SUPER":"Super / Windows key", "CTRL":"Control", "SHIFT":"Shift", "ALT":"Alt / Option",
        "ESC":"Escape", "SPACE":"Space", "ENTER":"Enter / Return", "BACKSPACE":"Backspace",
        "TAB":"Tab", "UP":"Up arrow", "DOWN":"Down arrow", "LEFT":"Left arrow", "RIGHT":"Right arrow",
        "DELETE":"Delete", "HOME":"Home", "END":"End", "PAGEUP":"Page Up", "PAGEDOWN":"Page Down", "CAPS":"Caps Lock"
    })
    signal clicked(string code)
    width: keyWidth * unit
    height: unit * 0.76
    radius: Math.max(4, unit * 0.12)
    color: active ? root.accent : mouse.containsMouse ? Qt.lighter(root.keyColor, 1.24) : root.keyColor
    border.width: Math.max(1, unit * 0.025)
    border.color: active ? accent : mouse.containsMouse ? Qt.lighter(root.borderColor, 1.5) : root.borderColor
    scale: mouse.containsMouse ? 1.025 : 1
    Text {
        anchors.centerIn: parent
        width: parent.width - 4
        text: root.label
        color: root.active ? "#101820" : root.textColor
        font.family: root.uiFontFamily
        font.pixelSize: Math.max(8, root.unit * (root.label.length > 5 ? 0.22 : 0.28))
        font.bold: root.active
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked(root.code)
    }
    ToolTip.visible: mouse.containsMouse
    ToolTip.delay: 350
    ToolTip.text: root.readableName || root.readableNames[root.code] || root.label
    Behavior on color { enabled: root.animationsEnabled; ColorAnimation { duration: 100 } }
    Behavior on border.color { enabled: root.animationsEnabled; ColorAnimation { duration: 100 } }
    Behavior on scale { enabled: root.animationsEnabled; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
}
