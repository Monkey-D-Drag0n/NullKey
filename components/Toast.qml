import QtQuick

Rectangle {
    id: root
    property string message: ""
    property bool shown: false
    signal expired()
    visible: opacity > 0
    opacity: shown ? 1 : 0
    implicitWidth: toastText.implicitWidth + 28
    implicitHeight: 42
    radius: 12
    color: "#263542"
    border.width: 1
    border.color: "#405464"
    Text { id: toastText; anchors.centerIn: parent; text: root.message; color: "#e2e8f0"; font.pixelSize: 12 }
    Timer { id: timeout; interval: 2200; onTriggered: { root.shown = false; root.expired() } }
    function show(text) { message = text; shown = true; timeout.restart() }
    Behavior on opacity { NumberAnimation { duration: 140 } }
}
