import QtQuick
import QtQuick.Controls

ComboBox {
    id: control
    property color accent: "#88c0d0"
    property color surfaceColor: "#171e28"
    property color borderColor: "#303b49"
    property color textColor: "#dce4ed"
    property string uiFontFamily: "Sans Serif"
    property int uiFontSize: 13
    implicitHeight: 36
    font.family: uiFontFamily
    font.pixelSize: uiFontSize
    hoverEnabled: true

    contentItem: Text {
        leftPadding: 12
        rightPadding: 30
        text: control.displayText
        font: control.font
        color: control.textColor
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    indicator: Text {
        x: control.width - width - 11
        y: (control.height - height) / 2
        text: control.popup.visible ? "⌃" : "⌄"
        color: control.popup.visible || control.hovered ? control.accent : "#8793a3"
        font.family: control.uiFontFamily
        font.pixelSize: control.uiFontSize + 2
        Behavior on color { ColorAnimation { duration: 120 } }
    }
    background: Rectangle {
        radius: 9
        color: control.down ? Qt.darker(control.surfaceColor, 1.12) : control.hovered ? Qt.lighter(control.surfaceColor, 1.08) : control.surfaceColor
        border.width: 1
        border.color: control.popup.visible ? control.accent : control.hovered ? Qt.lighter(control.borderColor, 1.2) : control.borderColor
        Behavior on color { ColorAnimation { duration: 130 } }
        Behavior on border.color { ColorAnimation { duration: 130 } }
    }
    delegate: ItemDelegate {
        required property int index
        width: control.popup.width - 10
        height: 34
        highlighted: control.highlightedIndex === index
        property bool selectedItem: control.currentIndex === index
        hoverEnabled: true
        contentItem: Text {
            text: control.textAt(index)
            font.family: control.uiFontFamily
            font.pixelSize: control.uiFontSize
            color: parent.highlighted || parent.selectedItem ? control.accent : control.textColor
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            leftPadding: 9
        }
        background: Rectangle {
            radius: 6
            color: parent.highlighted ? "#283542" : parent.selectedItem ? "#202b35" : "transparent"
            Behavior on color { ColorAnimation { duration: 100 } }
        }
    }
    popup: Popup {
        y: control.height + 5
        width: control.width
        implicitHeight: Math.min(listView.contentHeight + 10, 260)
        padding: 5
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle {
            radius: 11
            color: control.surfaceColor
            border.width: 1
            border.color: control.borderColor
        }
        contentItem: ListView {
            id: listView
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        }
        enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 110 } }
        exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 90 } }
    }
}
