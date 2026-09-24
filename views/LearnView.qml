import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property string prompt: ""
    property string feedback: ""
    property var choices: []
    signal answered(var choice)
    ColumnLayout {
        anchors.fill: parent
        spacing: 14
        Text { text: root.prompt; color: "#e2e8f0"; font.pixelSize: 19; font.bold: true; wrapMode: Text.Wrap; Layout.fillWidth: true }
        Text { text: root.feedback; color: "#8190a3"; font.pixelSize: 12 }
        RowLayout {
            Layout.fillWidth: true
            Repeater {
                model: root.choices
                delegate: Button { required property var modelData; Layout.fillWidth: true; text: modelData.label; onClicked: root.answered(modelData) }
            }
        }
    }
}
