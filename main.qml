import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtCore
import "components"
import "services" as Services
import "themes/themes.js" as ThemeData
import "data/catalog.js" as Catalog

ApplicationWindow {
    id: app
    visible: true
    width: 1440
    height: 920
    minimumWidth: 760
    minimumHeight: 580
    title: "MacKey"
    color: "#10131a"

    property string activeView: "Explore"
    property string activeEnvironment: "Omarchy"
    property string activeTarget: "All"
    property string activeCategory: "All"
    property string keyboardPlatform: "Windows / Linux"
    property string keyboardLayout: "Full Size"
    property string themeName: "Nord"
    property string accentName: "Theme default"
    property string uiFontFamily: "Sans Serif"
    property int uiFontSize: 13
    property int keyboardScale: 140
    property bool animationsEnabled: true
    property bool physicalVisualizationEnabled: true
    property string query: ""
    readonly property var favorites: favoriteStore.items
    readonly property var recent: recentStore.items
    property var selectedShortcut: null
    property var selectedKeys: []
    property var physicalKeys: []
    property var manualKeys: []
    readonly property var visualKeys: physicalVisualizationEnabled && physicalKeys.length ? physicalKeys : manualKeys.length ? manualKeys : selectedKeys
    property int learningIndex: 0
    property int learnScore: 0
    property string learnMessage: "Press the shortcut on your keyboard or choose an answer."
    readonly property var themePalette: ThemeData.palettes[themeName] || ThemeData.palettes.Nord
    readonly property var accentChoices: ({"Theme default":themePalette.accent, "Ice":"#88c0d0", "Violet":"#b4a1ff", "Rose":"#e7a0b4", "Mint":"#98d7ba"})
    property color accent: accentChoices[accentName] || themePalette.accent
    property color appBackground: themePalette.background
    property color sideBackground: themePalette.sidebar
    property color panelColor: themePalette.surface

    readonly property var environments: Catalog.environments
    readonly property var applications: Catalog.applications
    readonly property var keyboardLayouts: ["QWERTY", "60%", "65%", "75%", "TKL", "Full Size"]
    readonly property var installedFonts: Qt.fontFamilies().sort()
    readonly property var availableFonts: ["Sans Serif"].concat(installedFonts)
    readonly property var themeNames: ["Nord", "Catppuccin", "Tokyo Night", "Dracula"]
    readonly property var allShortcuts: shortcutStore.items
    readonly property var learningShortcuts: allShortcuts.filter(function(item) { return item.environment === activeEnvironment })
    readonly property var learningQuestions: learningShortcuts.map(function(item) {
        return {
            prompt: "Which keys perform this action: " + (item.description || item.action || item.name) + "?",
            keys: item.keys,
            choices: learningShortcuts.map(function(choice) {
                return {keys: choice.keys, label: choice.keys.join(" + ").replace(/SUPER/g, keyboardPlatform === "Mac" ? "⌘" : "Super").replace(/CTRL/g, "Ctrl").replace(/SHIFT/g, "Shift").replace(/ALT/g, keyboardPlatform === "Mac" ? "⌥" : "Alt").replace(/ENTER/g, "Enter")}
            })
        }
    })
    readonly property var currentQuestion: learningQuestions.length ? learningQuestions[learningIndex % learningQuestions.length] : null

    Services.ShortcutStore { id: shortcutStore }
    Services.FavoritesStore { id: favoriteStore }
    Services.RecentStore { id: recentStore }
    Settings {
        id: preferences
        location: StandardPaths.writableLocation(StandardPaths.ConfigLocation) + "/MacKey.ini"
        category: "MacKey"
        property string favoritesJson: "[]"
        property string recentJson: "[]"
        property alias themeName: app.themeName
        property alias accentName: app.accentName
        property alias keyboardPlatform: app.keyboardPlatform
        property alias keyboardLayout: app.keyboardLayout
        property alias keyboardScale: app.keyboardScale
        property alias uiFontFamily: app.uiFontFamily
        property alias uiFontSize: app.uiFontSize
        property alias animationsEnabled: app.animationsEnabled
        property alias physicalVisualizationEnabled: app.physicalVisualizationEnabled
    }
    Connections {
        target: favoriteStore
        function onItemsChanged() { preferences.favoritesJson = JSON.stringify(favoriteStore.items) }
    }
    Connections {
        target: recentStore
        function onItemsChanged() { preferences.recentJson = JSON.stringify(recentStore.items) }
    }

    function sameKeys(a, b) {
        if (!a || !b || a.length !== b.length) return false
        for (let i = 0; i < a.length; ++i) if (a[i] !== b[i]) return false
        return true
    }
    function sameKeySet(a, b) {
        if (!a || !b || a.length !== b.length) return false
        for (let i = 0; i < a.length; ++i) if (b.indexOf(a[i]) === -1) return false
        return true
    }
    function answerLearn(keys) {
        if (!currentQuestion) return
        if (sameKeySet(keys, currentQuestion.keys)) {
            ++learnScore
            learnMessage = "Correct! Score: " + learnScore
            selectedKeys = currentQuestion.keys
            learningIndex = (learningIndex + 1) % learningQuestions.length
        } else {
            learnMessage = "Not quite. Try the highlighted keys."
            selectedKeys = currentQuestion.keys
        }
    }
    function isFavorite(item) {
        for (let i = 0; i < favorites.length; ++i) if (sameKeys(favorites[i].keys, item.keys) && favorites[i].target === item.target && favorites[i].environment === item.environment) return true
        return false
    }
    function toggleFavorite(item) {
        let next = favoriteStore.items.slice()
        for (let i = 0; i < next.length; ++i) {
            if (sameKeys(next[i].keys, item.keys) && next[i].target === item.target && next[i].environment === item.environment) { next.splice(i, 1); favoriteStore.items = next; return }
        }
        next.unshift(item); favoriteStore.items = next
    }
    function openShortcut(item) {
        selectedShortcut = item
        selectedKeys = item.keys
        manualKeys = []
        let next = [item].concat(recentStore.items.filter(function(entry) { return !(sameKeys(entry.keys, item.keys) && entry.target === item.target && entry.environment === item.environment) }))
        recentStore.items = next.slice(0, 12)
    }
    function restorePersistentLists() {
        try {
            const savedFavorites = JSON.parse(preferences.favoritesJson || "[]")
            favoriteStore.items = Array.isArray(savedFavorites) ? savedFavorites.filter(function(item) { return item && Array.isArray(item.keys) }) : []
        } catch (error) { favoriteStore.items = [] }
        try {
            const savedRecent = JSON.parse(preferences.recentJson || "[]")
            recentStore.items = Array.isArray(savedRecent) ? savedRecent.filter(function(item) { return item && Array.isArray(item.keys) }).slice(0, 12) : []
        } catch (error) { recentStore.items = [] }
    }
    function toggleManualKey(code) {
        let next = manualKeys.length ? manualKeys.slice() : selectedKeys.slice()
        const index = next.indexOf(code)
        if (index >= 0) next.splice(index, 1)
        else next.push(code)
        manualKeys = next
    }
    function normalizeKey(key) {
        if (key === Qt.Key_Meta || key === Qt.Key_Super_L || key === Qt.Key_Super_R) return "SUPER"
        if (key === Qt.Key_Control || key === Qt.Key_Control_L || key === Qt.Key_Control_R) return "CTRL"
        if (key === Qt.Key_Shift || key === Qt.Key_Shift_L || key === Qt.Key_Shift_R) return "SHIFT"
        if (key === Qt.Key_Alt || key === Qt.Key_Alt_L || key === Qt.Key_Alt_R) return "ALT"
        if (key === Qt.Key_Space) return "SPACE"
        if (key === Qt.Key_Return || key === Qt.Key_Enter) return "ENTER"
        if (key === Qt.Key_Escape) return "ESC"
        if (key === Qt.Key_Backspace) return "BACKSPACE"
        if (key === Qt.Key_CapsLock) return "CAPS"
        if (key === Qt.Key_Delete) return "DELETE"
        if (key === Qt.Key_Tab) return "TAB"
        if (key === Qt.Key_Left) return "LEFT"
        if (key === Qt.Key_Right) return "RIGHT"
        if (key === Qt.Key_Up) return "UP"
        if (key === Qt.Key_Down) return "DOWN"
        if (key >= Qt.Key_F1 && key <= Qt.Key_F12) return "F" + (key - Qt.Key_F1 + 1)
        if (key === Qt.Key_BracketLeft) return "LBRACKET"
        if (key === Qt.Key_BracketRight) return "RBRACKET"
        if (key === Qt.Key_Backslash) return "BACKSLASH"
        if (key === Qt.Key_Semicolon) return "SEMICOLON"
        if (key === Qt.Key_Apostrophe) return "QUOTE"
        if (key === Qt.Key_Comma) return "COMMA"
        if (key === Qt.Key_Period) return "PERIOD"
        if (key === Qt.Key_Slash) return "SLASH"
        if (key === Qt.Key_Minus) return "MINUS"
        if (key === Qt.Key_Equal) return "EQUAL"
        if (key === Qt.Key_QuoteLeft) return "BACKTICK"
        const s = String.fromCharCode(key).toUpperCase()
        return s.length === 1 ? s : ""
    }
    function visibleItems() {
        let source = activeView === "Favorites" ? favorites : activeView === "Recent" ? recent : allShortcuts
        const q = query.trim().toLowerCase()
        return source.filter(function(item) {
            if (activeView === "Explore" && !q && applications.indexOf(activeTarget) >= 0 && item.target !== activeTarget) return false
            if (activeView === "Explore" && !q && applications.indexOf(activeTarget) < 0 && item.environment !== activeEnvironment) return false
            if (activeView === "Explore" && !q && applications.indexOf(activeTarget) < 0 && activeTarget !== "All" && item.target !== activeTarget) return false
            if (activeCategory !== "All" && item.category !== activeCategory) return false
            const haystack = [item.name,item.description,item.action,item.application,item.target,item.category,item.environment,item.keys.join(" ")].join(" ").toLowerCase()
            const normalizedQuery = q.replace(/\s*\+\s*/g, " ")
            return !q || haystack.indexOf(q) !== -1 || item.keys.join(" ").toLowerCase().indexOf(normalizedQuery) !== -1
        })
    }
    function environmentUnavailable() {
        if (activeView !== "Explore" || query.trim() || applications.indexOf(activeTarget) >= 0) return false
        return !allShortcuts.some(function(item) {
            return item.environment === activeEnvironment && (activeTarget === "All" || item.target === activeTarget)
        })
    }

    function restoreKeyFocus() { keyCapture.forceActiveFocus() }

    Item {
        id: keyCapture
        anchors.fill: parent
        focus: true
        z: -1
        Keys.onPressed: function(event) {
        const key = normalizeKey(event.key)
        let next = physicalKeys.slice()
        if (key && next.indexOf(key) === -1) next.push(key)
        if (event.modifiers & Qt.ControlModifier && next.indexOf("CTRL") === -1) next.push("CTRL")
        if (event.modifiers & Qt.ShiftModifier && next.indexOf("SHIFT") === -1) next.push("SHIFT")
        if (event.modifiers & Qt.AltModifier && next.indexOf("ALT") === -1) next.push("ALT")
        if (event.modifiers & Qt.MetaModifier && next.indexOf("SUPER") === -1) next.push("SUPER")
        physicalKeys = next
        if (activeView === "Learn" && key && key !== "CTRL" && key !== "SHIFT" && key !== "ALT" && key !== "SUPER") answerLearn(next)
        event.accepted = true
        }
        Keys.onReleased: function(event) {
        const key = normalizeKey(event.key)
        physicalKeys = physicalKeys.filter(function(value) { return value !== key })
        if (!(event.modifiers & Qt.ControlModifier)) physicalKeys = physicalKeys.filter(function(value) { return value !== "CTRL" })
        if (!(event.modifiers & Qt.ShiftModifier)) physicalKeys = physicalKeys.filter(function(value) { return value !== "SHIFT" })
        if (!(event.modifiers & Qt.AltModifier)) physicalKeys = physicalKeys.filter(function(value) { return value !== "ALT" })
        if (!(event.modifiers & Qt.MetaModifier)) physicalKeys = physicalKeys.filter(function(value) { return value !== "SUPER" })
        event.accepted = true
        }
    }
    Component.onCompleted: {
        restorePersistentLists()
        if (uiFontFamily !== "Sans Serif" && installedFonts.indexOf(uiFontFamily) < 0) {
            const preferred = ["Noto Sans", "Inter", "Cantarell", "DejaVu Sans", "Liberation Sans"]
            let match = ""
            for (let i = 0; i < preferred.length; ++i) if (installedFonts.indexOf(preferred[i]) >= 0) { match = preferred[i]; break }
            uiFontFamily = match || "Sans Serif"
        }
        if (environments.indexOf(activeEnvironment) < 0) activeEnvironment = environments[0]
        restoreKeyFocus()
    }
    onActiveChanged: if (!active) physicalKeys = []

    Rectangle { anchors.fill: parent; color: app.appBackground }
    RowLayout {
        anchors.fill: parent
        spacing: 0
        Rectangle {
            Layout.preferredWidth: 205
            Layout.fillHeight: true
            color: app.sideBackground
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14
                RowLayout {
                    Layout.fillWidth: true
                    Rectangle { Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 9; color: app.accent; Text { anchors.centerIn: parent; text: "⌨"; color: "#11151d"; font.pixelSize: 19 } }
                    Text { text: "MacKey"; color: "#e5e9f0"; font.family: app.uiFontFamily; font.pixelSize: 20; font.bold: true }
                }
                Repeater {
                    model: ["Explore", "Favorites", "Recent", "Learn", "Keyboard Visualizer"]
                    delegate: Button {
                        required property string modelData
                        Layout.fillWidth: true
                        implicitHeight: 38
                        text: modelData
                        highlighted: app.activeView === modelData
                        onClicked: { app.activeView = modelData; app.activeCategory = "All"; app.restoreKeyFocus() }
                        background: Rectangle { radius: 8; color: parent.highlighted ? "#202b36" : parent.hovered ? "#1b242e" : "transparent"; border.color: parent.highlighted ? "#2d414d" : "transparent"; border.width: 1; Behavior on color { ColorAnimation { duration: 120 } } }
                        contentItem: Text { text: parent.text; color: parent.highlighted ? app.accent : "#b7c0cd"; leftPadding: 11; verticalAlignment: Text.AlignVCenter; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize; font.weight: parent.highlighted ? Font.DemiBold : Font.Normal; elide: Text.ElideRight }
                    }
                }
                Item { Layout.fillHeight: true }
                Button {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    text: "Settings"
                    highlighted: app.activeView === "Settings"
                    onClicked: { app.activeView = "Settings"; app.restoreKeyFocus() }
                    background: Rectangle { radius: 8; color: parent.highlighted ? "#202b36" : parent.hovered ? "#1b242e" : "transparent"; border.color: parent.highlighted ? "#2d414d" : "transparent"; border.width: 1 }
                    contentItem: Text { text: parent.text; color: parent.highlighted ? app.accent : "#aab4c2"; leftPadding: 11; verticalAlignment: Text.AlignVCenter; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize }
                }
                Text { text: "Offline shortcut explorer"; color: "#637082"; font.family: app.uiFontFamily; font.pixelSize: 10; Layout.leftMargin: 8 }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 68
                color: app.themePalette.sidebar
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 22
                    anchors.rightMargin: 22
                    spacing: 8
                    Text { text: app.activeView !== "Explore" ? app.activeView : app.query.trim() ? "Search results" : app.applications.indexOf(app.activeTarget) >= 0 ? app.activeTarget + " shortcuts" : app.activeEnvironment + " shortcuts"; color: "#e5e9f0"; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize + 7; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true; Layout.minimumWidth: 50 }
                    RowLayout {
                        Layout.preferredWidth: 282
                        Layout.minimumWidth: 220
                        Layout.maximumWidth: 282
                        spacing: 8
                        SelectBox {
                            id: environmentPicker
                            objectName: "environmentPicker"
                            z: 3
                            Layout.fillWidth: true
                            Layout.minimumWidth: 110
                            Layout.maximumWidth: 142
                            model: app.environments
                            currentIndex: Math.max(0, model.indexOf(app.activeEnvironment))
                            onActivated: { app.activeEnvironment = currentText; app.activeTarget = "All"; app.activeView = "Explore"; app.activeCategory = "All"; app.query = ""; app.learningIndex = 0; app.learnMessage = "Press the shortcut on your keyboard or choose an answer."; app.selectedShortcut = null; app.selectedKeys = []; app.restoreKeyFocus() }
                            implicitWidth: 142
                            accent: app.accent; surfaceColor: app.themePalette.surface; borderColor: app.themePalette.border; textColor: app.themePalette.text; uiFontFamily: app.uiFontFamily; uiFontSize: app.uiFontSize
                        }
                        SelectBox {
                            id: targetPicker
                            objectName: "targetPicker"
                            z: 3
                            Layout.fillWidth: true
                            Layout.minimumWidth: 100
                            Layout.maximumWidth: 132
                            model: ["All", "Hyprland"].concat(app.applications)
                            currentIndex: Math.max(0, model.indexOf(app.activeTarget))
                            onActivated: { app.activeTarget = currentText; app.activeView = "Explore"; app.selectedShortcut = null; app.selectedKeys = []; app.manualKeys = []; app.restoreKeyFocus() }
                            implicitWidth: 132
                            accent: app.accent; surfaceColor: app.themePalette.surface; borderColor: app.themePalette.border; textColor: app.themePalette.text; uiFontFamily: app.uiFontFamily; uiFontSize: app.uiFontSize
                        }
                    }
                }
            }
            ScrollView {
                id: pageScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ColumnLayout {
                    width: pageScroll.availableWidth
                    spacing: 18
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(320, Math.max(205, width * 0.205))
                        visible: app.activeView !== "Settings" && app.activeView !== "Keyboard Visualizer"
                        Keyboard {
                            anchors.fill: parent
                            pressedKeys: app.visualKeys
                            keyboardPlatform: app.keyboardPlatform
                            keyboardLayout: app.keyboardLayout
                            accent: app.accent
                            keyColor: app.themePalette.key
                            borderColor: app.themePalette.border
                            textColor: app.themePalette.text
                            keyboardScale: app.keyboardScale / 100
                            uiFontFamily: app.uiFontFamily
                            animationsEnabled: app.animationsEnabled
                            onKeyToggled: function(code) {
                                app.toggleManualKey(code)
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 26
                        Layout.rightMargin: 26
                        spacing: 12
                        visible: ["Explore", "Favorites", "Recent"].indexOf(app.activeView) >= 0
                        SearchBar {
                            Layout.fillWidth: true
                            placeholderText: "Search shortcuts, keys, apps, actions…"
                            text: app.query
                            onTextChanged: app.query = text
                            accent: app.accent
                            surfaceColor: app.themePalette.surface
                            borderColor: app.themePalette.border
                            uiFontFamily: app.uiFontFamily
                            uiFontSize: app.uiFontSize
                        }
                        Text { text: app.visibleItems().length + " shortcuts"; color: "#8190a3"; font.pixelSize: 12 }
                    }
                    Flickable {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        Layout.leftMargin: 26
                        Layout.rightMargin: 26
                        contentWidth: categoryRow.implicitWidth
                        clip: true
                        visible: ["Explore", "Favorites", "Recent"].indexOf(app.activeView) >= 0
                        Row { id: categoryRow; spacing: 8
                            Repeater {
                                model: ["All", "Windows", "Workspaces", "Applications", "Tabs", "Navigation", "Editor", "Files"]
                                delegate: CategoryTab { required property string modelData; label: modelData; selected: app.activeCategory === modelData; accent: app.accent; uiFontFamily: app.uiFontFamily; uiFontSize: app.uiFontSize; onChosen: function(label) { app.activeCategory = label; app.restoreKeyFocus() } }
                            }
                        }
                    }
                    GridLayout {
                        id: shortcutGrid
                        Layout.fillWidth: true
                        Layout.leftMargin: 26
                        Layout.rightMargin: 26
                        columns: width > 950 ? 2 : 1
                        columnSpacing: 12
                        rowSpacing: 10
                        visible: ["Explore", "Favorites", "Recent"].indexOf(app.activeView) >= 0
                        Repeater {
                            model: app.visibleItems()
                            delegate: ShortcutCard {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 78
                                shortcut: modelData
                                favorite: app.isFavorite(modelData)
                                active: app.selectedShortcut && app.sameKeys(app.selectedShortcut.keys, modelData.keys) && app.selectedShortcut.target === modelData.target && app.selectedShortcut.environment === modelData.environment
                                accent: app.accent
                                surfaceColor: app.themePalette.surface
                                hoverColor: app.themePalette.hover
                                borderColor: app.themePalette.border
                                textColor: app.themePalette.text
                                mutedColor: app.themePalette.muted
                                uiFontFamily: app.uiFontFamily
                                uiFontSize: app.uiFontSize
                                animationsEnabled: app.animationsEnabled
                                onChosen: function(item) { app.openShortcut(item); app.restoreKeyFocus() }
                                onFavoriteToggled: function(item) { app.toggleFavorite(item); app.restoreKeyFocus() }
                            }
                        }
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 30
                        visible: ["Explore", "Favorites", "Recent"].indexOf(app.activeView) >= 0 && app.visibleItems().length === 0 && !app.environmentUnavailable()
                        text: app.query.trim() ? "No shortcuts match your search." : "No shortcuts found. Try another category."
                        color: "#8190a3"
                    }
                    Rectangle {
                        id: visualizerPanel
                        Layout.fillWidth: true
                        Layout.leftMargin: 26
                        Layout.rightMargin: 26
                        Layout.topMargin: 2
                        Layout.preferredHeight: 640
                        visible: app.activeView === "Keyboard Visualizer"
                        radius: 14
                        color: app.themePalette.surface
                        border.color: app.themePalette.border
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 22
                            spacing: 8
                            Text { text: "Press, hover, or select a key to explore your keyboard."; color: app.themePalette.muted; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize - 1; Layout.fillWidth: true; wrapMode: Text.Wrap }
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.minimumHeight: 280
                                Keyboard {
                                    anchors.fill: parent
                                    pressedKeys: app.visualKeys
                                    keyboardPlatform: app.keyboardPlatform
                                    keyboardLayout: app.keyboardLayout
                                    keyboardScale: app.keyboardScale / 100
                                    accent: app.accent
                                    keyColor: app.themePalette.key
                                    borderColor: app.themePalette.border
                                    textColor: app.themePalette.text
                                    uiFontFamily: app.uiFontFamily
                                    animationsEnabled: app.animationsEnabled
                                    onKeyToggled: function(code) { app.toggleManualKey(code); app.restoreKeyFocus() }
                                }
                            }
                            GridLayout {
                                Layout.fillWidth: true
                                columns: width > 800 ? 4 : 2
                                columnSpacing: 14
                                rowSpacing: 12
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Keyboard"; color: app.themePalette.muted; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize - 1 }
                                    SelectBox { Layout.fillWidth: true; model: Catalog.keyboardPlatforms; currentIndex: Math.max(0, model.indexOf(app.keyboardPlatform)); onActivated: { app.keyboardPlatform = currentText; app.restoreKeyFocus() }
                                        accent: app.accent; surfaceColor: app.themePalette.background; borderColor: app.themePalette.border; textColor: app.themePalette.text; uiFontFamily: app.uiFontFamily; uiFontSize: app.uiFontSize }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Layout"; color: app.themePalette.muted; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize - 1 }
                                    SelectBox { Layout.fillWidth: true; model: app.keyboardLayouts; currentIndex: Math.max(0, model.indexOf(app.keyboardLayout)); onActivated: { app.keyboardLayout = currentText; app.restoreKeyFocus() }
                                        accent: app.accent; surfaceColor: app.themePalette.background; borderColor: app.themePalette.border; textColor: app.themePalette.text; uiFontFamily: app.uiFontFamily; uiFontSize: app.uiFontSize }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Keyboard size  " + app.keyboardScale + "%"; color: app.themePalette.muted; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize - 1 }
                                    StyledSlider { Layout.fillWidth: true; from: 80; to: 150; stepSize: 1; value: app.keyboardScale; onMoved: app.keyboardScale = Math.round(value); onPressedChanged: { if (!pressed) app.restoreKeyFocus() }
                                        accent: app.accent }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Text { text: "Theme"; color: app.themePalette.muted; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize - 1 }
                                    SelectBox { Layout.fillWidth: true; model: app.themeNames; currentIndex: Math.max(0, model.indexOf(app.themeName)); onActivated: { app.themeName = currentText; app.restoreKeyFocus() }
                                        accent: app.accent; surfaceColor: app.themePalette.background; borderColor: app.themePalette.border; textColor: app.themePalette.text; uiFontFamily: app.uiFontFamily; uiFontSize: app.uiFontSize }
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Accent"; color: app.themePalette.muted; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize; Layout.preferredWidth: 120 }
                                SelectBox { Layout.fillWidth: true; model: Object.keys(app.accentChoices); currentIndex: Math.max(0, model.indexOf(app.accentName)); onActivated: { app.accentName = currentText; app.restoreKeyFocus() }
                                    accent: app.accent; surfaceColor: app.themePalette.background; borderColor: app.themePalette.border; textColor: app.themePalette.text; uiFontFamily: app.uiFontFamily; uiFontSize: app.uiFontSize }
                            }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 26
                        Layout.rightMargin: 26
                        Layout.topMargin: 20
                        Layout.preferredHeight: unavailableColumn.implicitHeight + 48
                        visible: app.environmentUnavailable()
                        radius: 16
                        color: app.themePalette.surface
                        border.color: app.themePalette.border
                        ColumnLayout {
                            id: unavailableColumn
                            anchors.fill: parent
                            anchors.margins: 24
                            spacing: 8
                            Text { text: "Keybindings not available yet"; color: app.themePalette.text; font.pixelSize: 18; font.bold: true }
                            Text { text: app.activeEnvironment + " shortcut data is not included yet."; color: app.themePalette.muted; font.pixelSize: 13; wrapMode: Text.Wrap; Layout.fillWidth: true }
                            Text { text: "Coming soon"; color: app.accent; font.pixelSize: 11; font.bold: true }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 26
                        Layout.rightMargin: 26
                        Layout.topMargin: 20
                        Layout.preferredHeight: learnColumn.implicitHeight + 44
                        visible: app.activeView === "Learn"
                        radius: 16
                        color: "#171e28"
                        border.color: "#293442"
                        ColumnLayout {
                            id: learnColumn
                            anchors.fill: parent
                            anchors.margins: 22
                            spacing: 16
                            Text { text: "LEARN SHORTCUTS"; color: app.accent; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize - 2; font.bold: true }
                            Text { visible: app.currentQuestion !== null; text: app.currentQuestion ? app.currentQuestion.prompt : ""; color: app.themePalette.text; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize + 6; font.bold: true; wrapMode: Text.Wrap; Layout.fillWidth: true }
                            Text { text: app.learnMessage; color: "#8291a4"; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize - 1 }
                            Text { visible: app.currentQuestion === null; text: "Keybindings not available yet. Learning mode will appear when this environment has shortcut data."; color: app.themePalette.muted; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize; wrapMode: Text.Wrap; Layout.fillWidth: true }
                            RowLayout {
                                Layout.fillWidth: true
                                visible: app.currentQuestion !== null
                                Repeater {
                                    model: app.currentQuestion ? app.currentQuestion.choices : []
                                    delegate: Button {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        text: modelData.label
                                        font.family: app.uiFontFamily
                                        font.pixelSize: app.uiFontSize
                                        onClicked: { app.answerLearn(modelData.keys); app.restoreKeyFocus() }
                                        background: Rectangle { radius: 8; color: parent.down ? "#283542" : parent.hovered ? app.themePalette.hover : app.themePalette.background; border.width: 1; border.color: parent.hovered ? app.accent : app.themePalette.border; Behavior on color { ColorAnimation { duration: 120 } } }
                                        contentItem: Text { text: parent.text; color: parent.hovered ? app.accent : app.themePalette.text; font: parent.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                                    }
                                }
                            }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 26
                        Layout.rightMargin: 26
                        Layout.topMargin: 20
                        Layout.preferredHeight: settingsColumn.implicitHeight + 44
                        visible: app.activeView === "Settings"
                        radius: 14
                        color: app.themePalette.surface
                        border.color: app.themePalette.border
                        ColumnLayout {
                            id: settingsColumn
                            anchors.fill: parent
                            anchors.margins: 22
                            spacing: 14
                            Text { text: "Appearance"; color: app.themePalette.text; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize + 5; font.bold: true }
                            Text { text: "Choose a theme, font, and keyboard scale for MacKey."; color: app.themePalette.muted; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize - 1 }
                            Text { text: "Theme"; color: app.themePalette.muted; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize - 1; font.bold: true }
                            GridLayout {
                                Layout.fillWidth: true
                                columns: width > 650 ? 4 : 2
                                columnSpacing: 9
                                rowSpacing: 8
                                Repeater {
                                    model: app.themeNames
                                    delegate: ThemeCard {
                                        required property string modelData
                                        Layout.fillWidth: true
                                        Layout.maximumWidth: 190
                                        themeName: modelData
                                        palette: ThemeData.palettes[modelData]
                                        selected: app.themeName === modelData
                                        uiFontFamily: app.uiFontFamily
                                        onChosen: function(name) { app.themeName = name; app.restoreKeyFocus() }
                                    }
                                }
                            }
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: app.themePalette.border }
                            Text { text: "Typography"; color: app.themePalette.text; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize + 3; font.bold: true }
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Font family"; color: app.themePalette.muted; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize; Layout.preferredWidth: 120 }
                                SelectBox { Layout.fillWidth: true; model: app.availableFonts; currentIndex: Math.max(0, model.indexOf(app.uiFontFamily)); onActivated: { app.uiFontFamily = currentText; app.restoreKeyFocus() }
                                    accent: app.accent; surfaceColor: app.themePalette.background; borderColor: app.themePalette.border; textColor: app.themePalette.text; uiFontFamily: app.uiFontFamily; uiFontSize: app.uiFontSize }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Font size  " + app.uiFontSize + " px"; color: app.themePalette.muted; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize; Layout.preferredWidth: 120 }
                                StyledSlider { Layout.fillWidth: true; from: 11; to: 18; stepSize: 1; value: app.uiFontSize; onMoved: app.uiFontSize = Math.round(value); onPressedChanged: { if (!pressed) app.restoreKeyFocus() }
                                    accent: app.accent }
                            }
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: app.themePalette.border }
                            Text { text: "Keyboard"; color: app.themePalette.text; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize + 3; font.bold: true }
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Keyboard type"; color: app.themePalette.muted; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize; Layout.preferredWidth: 120 }
                                SelectBox { Layout.fillWidth: true; model: Catalog.keyboardPlatforms; currentIndex: Math.max(0, model.indexOf(app.keyboardPlatform)); onActivated: { app.keyboardPlatform = currentText; app.restoreKeyFocus() }
                                    accent: app.accent; surfaceColor: app.themePalette.background; borderColor: app.themePalette.border; textColor: app.themePalette.text; uiFontFamily: app.uiFontFamily; uiFontSize: app.uiFontSize }
                                SelectBox { Layout.fillWidth: true; model: app.keyboardLayouts; currentIndex: Math.max(0, model.indexOf(app.keyboardLayout)); onActivated: { app.keyboardLayout = currentText; app.restoreKeyFocus() }
                                    accent: app.accent; surfaceColor: app.themePalette.background; borderColor: app.themePalette.border; textColor: app.themePalette.text; uiFontFamily: app.uiFontFamily; uiFontSize: app.uiFontSize }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Keyboard scale  " + app.keyboardScale + "%"; color: app.themePalette.muted; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize; Layout.preferredWidth: 150 }
                                StyledSlider { Layout.fillWidth: true; from: 80; to: 150; stepSize: 1; value: app.keyboardScale; onMoved: app.keyboardScale = Math.round(value); onPressedChanged: { if (!pressed) app.restoreKeyFocus() }
                                    accent: app.accent }
                            }
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: app.themePalette.border }
                            Text { text: "Behavior"; color: app.themePalette.text; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize + 3; font.bold: true }
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Recent history  ·  up to 12 shortcuts"; color: app.themePalette.muted; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize; Layout.fillWidth: true }
                                Text { text: "Favorites are saved on this device"; color: app.themePalette.muted; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize - 1 }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Animations"; color: app.themePalette.text; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize; Layout.fillWidth: true }
                                Switch { checked: app.animationsEnabled; onToggled: { app.animationsEnabled = checked; app.restoreKeyFocus() }
                                    indicator: Rectangle { implicitWidth: 38; implicitHeight: 22; x: parent.leftPadding; y: parent.height / 2 - height / 2; radius: 11; color: parent.checked ? app.accent : "#303a47"; Rectangle { x: parent.parent.checked ? parent.width - width - 3 : 3; y: 3; width: 16; height: 16; radius: 8; color: "#f2f4f8"; Behavior on x { NumberAnimation { duration: 130 } } } } }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Physical key visualization"; color: app.themePalette.text; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize; Layout.fillWidth: true }
                                Switch { checked: app.physicalVisualizationEnabled; onToggled: { app.physicalVisualizationEnabled = checked; app.restoreKeyFocus() }
                                    indicator: Rectangle { implicitWidth: 38; implicitHeight: 22; x: parent.leftPadding; y: parent.height / 2 - height / 2; radius: 11; color: parent.checked ? app.accent : "#303a47"; Rectangle { x: parent.parent.checked ? parent.width - width - 3 : 3; y: 3; width: 16; height: 16; radius: 8; color: "#f2f4f8"; Behavior on x { NumberAnimation { duration: 130 } } } } }
                            }
                            Text { text: "Key labels remain visible; hover a key for its readable name."; color: app.themePalette.muted; font.family: app.uiFontFamily; font.pixelSize: app.uiFontSize - 2; wrapMode: Text.Wrap; Layout.fillWidth: true }
                        }
                    }
                    Item { Layout.preferredHeight: 20 }
                }
            }
        }
    }
}
