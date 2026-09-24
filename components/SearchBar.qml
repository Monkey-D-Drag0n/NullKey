import QtQuick
import QtQuick.Controls

TextField {
    id: root
    property color accent: "#88c0d0"
    property color surfaceColor: "#171e28"
    property color borderColor: "#293442"
    property string uiFontFamily: "Sans Serif"
    property int uiFontSize: 13
    placeholderText: "Search shortcuts…"
    color: "#e2e8f0"
    font.family: uiFontFamily
    font.pixelSize: uiFontSize
    placeholderTextColor: "#8190a3"
    selectByMouse: true
    leftPadding: 14
    background: Rectangle {
        radius: 10
        color: root.surfaceColor
        border.width: 1
        border.color: root.activeFocus ? root.accent : root.borderColor
    }
}
