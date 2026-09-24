import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property string themeName: "Nord"
    property string keyboardPlatform: "Windows / Linux"
    property string keyboardLayout: "Full-size"
    signal themeChanged(string name)
    signal platformChanged(string platform)
    signal layoutChanged(string layout)
    spacing: 12
    Text { text: "Theme"; color: "#e2e8f0"; font.pixelSize: 18; font.bold: true }
    RowLayout {
        Repeater {
            model: ["Nord", "Catppuccin", "Tokyo Night", "Dracula"]
            delegate: Button { required property string modelData; text: modelData; highlighted: root.themeName === modelData; onClicked: root.themeChanged(modelData) }
        }
    }
    Text { text: "Keyboard platform"; color: "#e2e8f0"; font.pixelSize: 18; font.bold: true; Layout.topMargin: 14 }
    ComboBox {
        model: ["Windows / Linux", "Mac"]
        currentIndex: Math.max(0, model.indexOf(root.keyboardPlatform))
        onActivated: root.platformChanged(currentText)
    }
    Text { text: "Physical layout"; color: "#e2e8f0"; font.pixelSize: 18; font.bold: true; Layout.topMargin: 14 }
    ComboBox {
        model: ["QWERTY", "60%", "TKL", "Full-size"]
        currentIndex: Math.max(0, model.indexOf(root.keyboardLayout))
        onActivated: root.layoutChanged(currentText)
    }
}
