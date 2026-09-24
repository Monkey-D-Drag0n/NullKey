import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property string themeName: ""
    property var palette: ({})
    property bool selected: false
    property string uiFontFamily: "Sans Serif"
    signal chosen(string name)
    implicitWidth: 125
    implicitHeight: 66

    Rectangle {
        anchors.fill: parent
        radius: 9
        color: root.palette.surface || "#171e28"
        border.width: 1
        border.color: root.selected ? (root.palette.accent || "#88c0d0") : root.palette.border || "#293442"
        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Text { text: root.themeName; color: root.palette.text || "#e2e8f0"; font.family: root.uiFontFamily; font.pixelSize: 12; font.weight: root.selected ? Font.DemiBold : Font.Medium; elide: Text.ElideRight; Layout.fillWidth: true }
                Row {
                    spacing: 4
                    Repeater {
                        model: [root.palette.background || "#101820", root.palette.key || "#1b2430", root.palette.accent || "#88c0d0"]
                        delegate: Rectangle { required property color modelData; width: 14; height: 5; radius: 3; color: modelData }
                    }
                }
            }
            Rectangle { visible: root.selected; width: 6; height: 6; radius: 3; color: root.palette.accent || "#88c0d0" }
        }
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.chosen(root.themeName)
    }
    ToolTip.visible: hoverArea.containsMouse
    ToolTip.text: root.themeName
    ToolTip.delay: 450
    MouseArea { id: hoverArea; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
}
