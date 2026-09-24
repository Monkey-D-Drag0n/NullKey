# MacKey

MacKey is an offline QML shortcut explorer prototype for Linux desktop environments. The keyboard is interactive: select a shortcut to highlight its keys, click keys to toggle them, or focus the app and press physical keys. Search covers descriptions, actions, applications, categories, environments, and key names.

## Run

From this directory, start it with a Qt 6 QML runner or Quickshell:

```sh
quickshell -p main.qml
```

The project uses QtQuick, QtQuick Controls, QtQuick Layouts, and QtQuick Window. It does not need a network connection.

## Included

- Responsive full-size keyboard, TKL and 60% views, plus independent Mac and Windows/Linux modifier labels and QWERTY selection.
- Physical keyboard feedback, mouse hover and click, shortcut selection, and key name tooltips.
- Searchable shortcut cards, categories, application targets, environment navigation, favorites, and recent items.
- Nord, Catppuccin, Tokyo Night, and Dracula accent palettes; a basic learning quiz.
- Starter shortcuts for Hyprland, Omarchy, Brave, Chrome, VS Code, LazyVim, Kitty, and Dolphin.
- A data store, recent/favorites services, conflict helper, and a parser for common Hyprland `bind`, `bindr`, and `bindm` lines.

## Data and scope

Shortcut records live in `data/shortcuts.js`. Add records there to extend the explorer. Only representative Hyprland and Omarchy records are included; environments without matching records show a clear unavailable state instead of borrowing another environment's bindings. Favorites and recent shortcuts persist through Qt settings. Config import parsing is available as a service, while file picking, custom binding editing, learning progress, and environment comparison still need their UI/storage work.
