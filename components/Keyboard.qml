import QtQuick

Item {
    id: root
    property var pressedKeys: []
    property string keyboardPlatform: "Windows / Linux"
    property string keyboardLayout: "Full-size"
    property real keyboardScale: 1.2
    property string uiFontFamily: "Sans Serif"
    property bool animationsEnabled: true
    property color accent: "#88c0d0"
    property color keyColor: "#1b2430"
    property color borderColor: "#394656"
    property color textColor: "#bac6d5"
    signal keyToggled(string code)
    property var keys: [
        {x:0,y:0,w:1.15,l:"Esc",c:"ESC"},{x:1.45,y:0,w:.72,l:"F1",c:"F1"},{x:2.25,y:0,w:.72,l:"F2",c:"F2"},{x:3.05,y:0,w:.72,l:"F3",c:"F3"},{x:3.85,y:0,w:.72,l:"F4",c:"F4"},{x:5.0,y:0,w:.72,l:"F5",c:"F5"},{x:5.8,y:0,w:.72,l:"F6",c:"F6"},{x:6.6,y:0,w:.72,l:"F7",c:"F7"},{x:7.4,y:0,w:.72,l:"F8",c:"F8"},{x:8.55,y:0,w:.72,l:"F9",c:"F9"},{x:9.35,y:0,w:.72,l:"F10",c:"F10"},{x:10.15,y:0,w:.72,l:"F11",c:"F11"},{x:10.95,y:0,w:.72,l:"F12",c:"F12"},{x:12.25,y:0,w:.7,l:"Prt",c:"PRINT"},{x:13.05,y:0,w:.7,l:"Scr",c:"SCROLL"},{x:13.85,y:0,w:.7,l:"Pau",c:"PAUSE"},{x:15.2,y:0,w:.72,l:"Ins",c:"INSERT"},{x:16,y:0,w:.72,l:"Home",c:"HOME"},{x:16.8,y:0,w:.72,l:"PgUp",c:"PAGEUP"},{x:18,y:0,w:.72,l:"Num",c:"NUMLOCK"},{x:18.8,y:0,w:.72,l:"/",c:"NUMDIV"},{x:19.6,y:0,w:.72,l:"*",c:"NUMMULT"},{x:20.4,y:0,w:.72,l:"−",c:"NUMSUB"},
        {x:0,y:.9,w:.9,l:"~",c:"BACKTICK"},{x:.95,y:.9,w:.9,l:"1",c:"1"},{x:1.9,y:.9,w:.9,l:"2",c:"2"},{x:2.85,y:.9,w:.9,l:"3",c:"3"},{x:3.8,y:.9,w:.9,l:"4",c:"4"},{x:4.75,y:.9,w:.9,l:"5",c:"5"},{x:5.7,y:.9,w:.9,l:"6",c:"6"},{x:6.65,y:.9,w:.9,l:"7",c:"7"},{x:7.6,y:.9,w:.9,l:"8",c:"8"},{x:8.55,y:.9,w:.9,l:"9",c:"9"},{x:9.5,y:.9,w:.9,l:"0",c:"0"},{x:10.45,y:.9,w:.9,l:"−",c:"MINUS"},{x:11.4,y:.9,w:.9,l:"=",c:"EQUAL"},{x:12.35,y:.9,w:1.85,l:"Backspace",c:"BACKSPACE"},{x:15.2,y:.9,w:.72,l:"Del",c:"DELETE"},{x:16,y:.9,w:.72,l:"End",c:"END"},{x:16.8,y:.9,w:.72,l:"PgDn",c:"PAGEDOWN"},{x:18,y:.9,w:.72,l:"7",c:"NUM7"},{x:18.8,y:.9,w:.72,l:"8",c:"NUM8"},{x:19.6,y:.9,w:.72,l:"9",c:"NUM9"},{x:20.4,y:.9,w:.72,l:"+",c:"NUMADD"},
        {x:0,y:1.8,w:1.38,l:"Tab",c:"TAB"},{x:1.43,y:1.8,w:.9,l:"Q",c:"Q"},{x:2.38,y:1.8,w:.9,l:"W",c:"W"},{x:3.33,y:1.8,w:.9,l:"E",c:"E"},{x:4.28,y:1.8,w:.9,l:"R",c:"R"},{x:5.23,y:1.8,w:.9,l:"T",c:"T"},{x:6.18,y:1.8,w:.9,l:"Y",c:"Y"},{x:7.13,y:1.8,w:.9,l:"U",c:"U"},{x:8.08,y:1.8,w:.9,l:"I",c:"I"},{x:9.03,y:1.8,w:.9,l:"O",c:"O"},{x:9.98,y:1.8,w:.9,l:"P",c:"P"},{x:10.93,y:1.8,w:.9,l:"[",c:"LBRACKET"},{x:11.88,y:1.8,w:.9,l:"]",c:"RBRACKET"},{x:12.83,y:1.8,w:1.37,l:"\\",c:"BACKSLASH"},{x:18,y:1.8,w:.72,l:"4",c:"NUM4"},{x:18.8,y:1.8,w:.72,l:"5",c:"NUM5"},{x:19.6,y:1.8,w:.72,l:"6",c:"NUM6"},
        {x:0,y:2.7,w:1.65,l:"Caps",c:"CAPS"},{x:1.7,y:2.7,w:.9,l:"A",c:"A"},{x:2.65,y:2.7,w:.9,l:"S",c:"S"},{x:3.6,y:2.7,w:.9,l:"D",c:"D"},{x:4.55,y:2.7,w:.9,l:"F",c:"F"},{x:5.5,y:2.7,w:.9,l:"G",c:"G"},{x:6.45,y:2.7,w:.9,l:"H",c:"H"},{x:7.4,y:2.7,w:.9,l:"J",c:"J"},{x:8.35,y:2.7,w:.9,l:"K",c:"K"},{x:9.3,y:2.7,w:.9,l:"L",c:"L"},{x:10.25,y:2.7,w:.9,l:";",c:"SEMICOLON"},{x:11.2,y:2.7,w:.9,l:"'",c:"QUOTE"},{x:12.15,y:2.7,w:2.05,l:"Enter",c:"ENTER"},{x:18,y:2.7,w:.72,l:"1",c:"NUM1"},{x:18.8,y:2.7,w:.72,l:"2",c:"NUM2"},{x:19.6,y:2.7,w:.72,l:"3",c:"NUM3"},{x:20.4,y:2.7,w:.72,l:"↵",c:"NUMENTER"},
        {x:0,y:3.6,w:2.1,l:"Shift",c:"SHIFT"},{x:2.15,y:3.6,w:.9,l:"Z",c:"Z"},{x:3.1,y:3.6,w:.9,l:"X",c:"X"},{x:4.05,y:3.6,w:.9,l:"C",c:"C"},{x:5,y:3.6,w:.9,l:"V",c:"V"},{x:5.95,y:3.6,w:.9,l:"B",c:"B"},{x:6.9,y:3.6,w:.9,l:"N",c:"N"},{x:7.85,y:3.6,w:.9,l:"M",c:"M"},{x:8.8,y:3.6,w:.9,l:",",c:"COMMA"},{x:9.75,y:3.6,w:.9,l:".",c:"PERIOD"},{x:10.7,y:3.6,w:.9,l:"/",c:"SLASH"},{x:11.65,y:3.6,w:2.55,l:"Shift",c:"SHIFT"},{x:16,y:3.6,w:.72,l:"↑",c:"UP"},{x:18,y:3.6,w:.72,l:"0",c:"NUM0"},{x:18.8,y:3.6,w:1.52,l:".",c:"NUMDECIMAL"},
        {x:0,y:4.5,w:1.15,l:"Ctrl",c:"CTRL"},{x:1.2,y:4.5,w:1.05,l:"⊞",c:"SUPER"},{x:2.3,y:4.5,w:1.05,l:"Alt",c:"ALT"},{x:3.4,y:4.5,w:5.0,l:"Space",c:"SPACE"},{x:8.5,y:4.5,w:1.05,l:"Alt",c:"ALT"},{x:9.6,y:4.5,w:1.05,l:"⊞",c:"SUPER"},{x:10.7,y:4.5,w:1.05,l:"Menu",c:"MENU"},{x:11.8,y:4.5,w:1.2,l:"Ctrl",c:"CTRL"},{x:15.2,y:4.5,w:.72,l:"←",c:"LEFT"},{x:16,y:4.5,w:.72,l:"↓",c:"DOWN"},{x:16.8,y:4.5,w:.72,l:"→",c:"RIGHT"}
    ]
    readonly property real boardColumns: keyboardLayout === "60%" ? 14.2 : keyboardLayout === "65%" ? 17.6 : keyboardLayout === "75%" ? 17.2 : keyboardLayout === "TKL" ? 17.6 : 21.2
    readonly property real fitUnit: Math.min((width - 8) / boardColumns, (height - 8) / 5.4)
    property real unit: Math.max(8, fitUnit * Math.min(1, keyboardScale / 1.5))
    function keyX(key) {
        if (keyboardPlatform === "Mac" && key.y === 4.5) {
            if (key.x === 1.2) return 1.2
            if (key.x === 2.3) return 2.3
            if (key.x === 8.5) return 9.3
            if (key.x === 9.6) return 10.4
            if (key.x === 11.8) return 11.5
        }
        if (keyboardLayout === "75%" && key.y === 0 && key.x >= 1.45 && key.x < 12.25) return key.x - 0.12
        if (keyboardLayout === "75%" && key.x >= 15.2 && key.x < 18) return key.x - 0.45
        return key.x
    }
    function keyCode(key) {
        if (keyboardPlatform === "Mac" && key.y === 4.5) {
            if (key.x === 1.2) return "ALT"
            if (key.x === 2.3) return "SUPER"
            if (key.x === 8.5) return "SUPER"
            if (key.x === 9.6) return "ALT"
        }
        return key.c
    }
    function keyLabel(key) {
        if (keyboardPlatform === "Mac" && key.y === 4.5) {
            if (key.x === 1.2 || key.x === 9.6) return "⌥"
            if (key.x === 2.3 || key.x === 8.5) return "⌘"
            if (key.x === 3.4) return "Space"
        }
        return key.c === "SUPER" && keyboardPlatform === "Mac" ? "⌘" : key.c === "ALT" && keyboardPlatform === "Mac" ? "⌥" : key.l
    }
    Rectangle { anchors.fill: board; anchors.margins: -10; radius: 18; color: "#141b25"; border.width: 1; border.color: "#263240" }
    Item {
        id: board
        width: root.unit * root.boardColumns
        height: root.unit * 5.4
        anchors.centerIn: parent
        Repeater {
            model: root.keys.filter(function(key) {
                if (root.keyboardLayout === "TKL" && key.x >= 18) return false
                if (root.keyboardLayout === "60%" && (key.x >= 14.5 || (key.y === 0 && key.x > 1.4))) return false
                if (root.keyboardLayout === "65%" && (key.x >= 18 || (key.y === 0 && (key.x >= 12.25 || key.x >= 15.2)) || (key.y === .9 && key.x === 16))) return false
                if (root.keyboardLayout === "75%" && key.x >= 18) return false
                if (root.keyboardPlatform === "Mac" && key.y === 4.5 && key.x === 10.7) return false
                return true
            })
            delegate: KeyCap {
                required property var modelData
                x: root.keyX(modelData) * root.unit
                y: modelData.y * root.unit
                label: root.keyLabel(modelData)
                code: root.keyCode(modelData)
                keyWidth: root.keyboardPlatform === "Mac" && modelData.y === 4.5 && modelData.x === 3.4 ? 5.8 : modelData.w
                unit: root.unit
                accent: root.accent
                readableName: root.keyboardPlatform === "Mac" && root.keyCode(modelData) === "SUPER" ? "Command" : root.keyboardPlatform === "Mac" && root.keyCode(modelData) === "ALT" ? "Option" : ""
                uiFontFamily: root.uiFontFamily
                animationsEnabled: root.animationsEnabled
                keyColor: root.keyColor
                borderColor: root.borderColor
                textColor: root.textColor
                active: root.pressedKeys.indexOf(modelData.c) >= 0 || root.pressedKeys.indexOf(modelData.l) >= 0
                onClicked: function(code) { root.keyToggled(code) }
            }
        }
    }
    Behavior on unit { enabled: root.animationsEnabled; NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
}
