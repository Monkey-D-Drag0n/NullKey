import QtQuick
import QtQuick.Controls

Slider {
    id: control
    property color accent: "#88c0d0"
    implicitHeight: 26
    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        width: control.availableWidth
        height: 4
        radius: 2
        color: "#303a47"
        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            radius: 2
            color: control.accent
        }
    }
    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + (control.availableHeight - height) / 2
        width: 15
        height: 15
        radius: 8
        color: control.pressed ? "#ffffff" : control.accent
        border.width: 2
        border.color: "#151b23"
        Behavior on scale { NumberAnimation { duration: 100 } }
        scale: control.pressed ? 1.08 : 1
    }
}
