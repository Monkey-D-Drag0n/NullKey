import QtQuick

Rectangle {
    id: root
    property string label: ""
    property bool selected: false
    property color accent: "#88c0d0"
    property string uiFontFamily: "Sans Serif"
    property int uiFontSize: 12
    signal chosen(string label)
    implicitWidth: labelText.implicitWidth + 24
    height: 32
    radius: 9
    color: selected ? "#263542" : mouse.containsMouse ? "#202834" : "#171e28"
    border.width: 1
    border.color: selected ? "#405464" : "#293442"
    Text { id: labelText; anchors.centerIn: parent; text: root.label; color: root.selected ? root.accent : "#aab5c4"; font.family: root.uiFontFamily; font.pixelSize: root.uiFontSize - 1; font.weight: root.selected ? Font.DemiBold : Font.Normal }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.chosen(root.label) }
    Behavior on color { ColorAnimation { duration: 120 } }
}
