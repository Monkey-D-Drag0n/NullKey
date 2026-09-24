import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property var shortcut: ({keys:[],description:"",target:""})
    property bool favorite: false
    property bool active: false
    property color accent: "#88c0d0"
    property color surfaceColor: "#171e28"
    property color hoverColor: "#1c2632"
    property color borderColor: "#293442"
    property color textColor: "#e2e8f0"
    property color mutedColor: "#75869a"
    property string uiFontFamily: "Sans Serif"
    property int uiFontSize: 13
    property bool animationsEnabled: true
    signal chosen(var item)
    signal favoriteToggled(var item)
    radius: 10
    color: active ? Qt.darker(root.accent, 3.1) : mouse.containsMouse ? root.hoverColor : root.surfaceColor
    border.width: 1
    border.color: active ? Qt.darker(root.accent, 1.4) : mouse.containsMouse ? Qt.lighter(root.borderColor, 1.25) : root.borderColor
    RowLayout {
        id: cardContent
        z: 1
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 10
        spacing: 10
        Row {
            Layout.preferredWidth: 190
            Layout.alignment: Qt.AlignVCenter
            spacing: 5
            Repeater {
                model: root.shortcut.keys
                delegate: Rectangle {
                    required property string modelData
                    implicitWidth: keyText.implicitWidth + 16
                    height: 26
                    radius: 6
                    color: root.active ? Qt.darker(root.accent, 2.2) : Qt.darker(root.accent, 3.0)
                    border.width: 1
                    border.color: root.borderColor
                    Text { id: keyText; anchors.centerIn: parent; text: modelData; color: root.textColor; font.family: root.uiFontFamily; font.pixelSize: root.uiFontSize - 2; font.bold: true }
                }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            Text { text: root.shortcut.description || ""; color: root.textColor; font.family: root.uiFontFamily; font.pixelSize: root.uiFontSize; font.weight: Font.Medium; elide: Text.ElideRight; Layout.fillWidth: true }
            Text {
                text: (root.shortcut.environment && root.shortcut.environment !== root.shortcut.target ? root.shortcut.environment + "  ·  " : "") + (root.shortcut.target || "") + "  ·  " + (root.shortcut.category || "")
                color: root.mutedColor
                font.family: root.uiFontFamily
                font.pixelSize: root.uiFontSize - 3
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
        ToolButton {
            text: root.favorite ? "★" : "☆"
            display: AbstractButton.TextOnly
            onClicked: root.favoriteToggled(root.shortcut)
            contentItem: Text { text: parent.text; color: root.favorite ? root.accent : "#8291a4"; font.family: root.uiFontFamily; font.pixelSize: 19; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            background: Rectangle { radius: 7; color: parent.hovered ? "#263341" : "transparent" }
        }
    }
    MouseArea { id: mouse; anchors.fill: parent; z: 0; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.chosen(root.shortcut) }
    Behavior on color { enabled: root.animationsEnabled; ColorAnimation { duration: 120 } }
}
