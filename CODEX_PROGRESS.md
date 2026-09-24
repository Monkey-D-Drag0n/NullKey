# MacKey Development Progress

**Last reviewed:** 2026-09-24  
**Project:** `/home/roronoa/Projects/Work/Work/MacKey`

## Current state

MacKey is a runnable Quickshell/QML desktop app. The existing data-driven architecture is intact. The latest UI refinement is implemented in the project; this pass is a handoff record only and does not change application behavior.

Launch with:

```sh
quickshell -p /home/roronoa/Projects/Work/Work/MacKey/main.qml
```

The app was launched successfully and reported `INFO: Configuration Loaded`. `qmllint` completed without diagnostics for the changed QML files. A non-fatal Qt portal D-Bus registration warning appeared on this host. An attempted `qmltestrunner` run exited with a GTK/display initialization error, so it did not provide application interaction coverage.

## Implemented

- **Navigation and selectors:** Explore, Favorites, Recent, Learn, Settings, and a dedicated Keyboard Visualizer view. Shared custom dark selectors are used for environment, target/application, keyboard platform/layout, theme, font, and accent settings.
- **Environment data integrity:** Omarchy has environment-scoped shortcut data. Caelestia, DankShell, Noctalia, end-4, and HyDE Project show an explicit unavailable state when there are no records; Hyprland starter data is not presented as those environments' data. Search can return matches across data sources and identifies their source.
- **Keyboard:** Physical key geometry is rendered from keyboard data and scales proportionally to fit the view. Layout choices include QWERTY, 60%, 65%, 75%, TKL, and Full Size; platform choice changes modifier labels/arrangement. Keycaps support hover names and visual pressed/selected states. Physical key input and shortcut selection are connected to highlighting.
- **Shortcut browsing:** Cards show keys and descriptions, retain favorite controls, and provide selection feedback. Search covers shortcut name, description, action, application/target, category, environment, and key combinations.
- **Preferences and personalization:** Theme cards/swatches, accent choices, installed font families with a generic Sans Serif fallback, font-size and keyboard-scale sliders, and animation/physical-key visualization settings. Preferences use Qt `Settings`.
- **Favorites and Recent:** Environment-aware stores persist their contents as JSON; both are surfaced in their own views.
- **Learning:** Questions are derived from shortcuts available in the active environment; an environment without data does not silently learn from another environment's records.
- **Data and UI organization:** Shortcut records/catalog remain separate from visual components; the Hyprland config parser service remains in place.

## Important files

- `main.qml` — application shell, navigation, active environment/target, shared state, global search, and preference wiring.
- `components/SelectBox.qml` — shared custom selector and popup.
- `components/Keyboard.qml`, `components/KeyCap.qml` — keyboard geometry/rendering, key states, tooltips, and key interaction.
- `components/ShortcutCard.qml`, `components/SearchBar.qml`, `components/CategoryTab.qml` — shortcut and browse controls.
- `components/StyledSlider.qml`, `components/ThemeCard.qml` — settings controls and theme previews.
- `views/KeyboardView.qml` — dedicated visualizer; `views/SettingsView.qml` — appearance and behavior settings.
- `views/CheatsheetView.qml`, `views/FavoritesView.qml`, `views/RecentView.qml`, `views/LearnView.qml` — primary content views.
- `data/catalog.js`, `data/shortcuts.js`, `data/shortcuts.json` — catalog and shortcut data/metadata.
- `services/ShortcutStore.qml` — data filtering/search; `FavoritesStore.qml`, `RecentStore.qml` — saved/recent entries; `LearnEngine.qml` — learning flow; `ConfigParser.qml` — Hyprland parser.
- `theme/Colors.qml`, `theme/Theme.qml`, `themes/themes.js` — theme state and palettes.
- `README.md` — project usage/documentation.

## Pending work

- Run a full interactive verification pass on the actual desktop. Launch and visual rendering were verified, but every selector and persistence path was not tested end to end.
- Add accurate, sourced shortcut records for environments that currently have none. Keep the unavailable state until verified data is added.
- Review the visual/physical accuracy of each keyboard geometry, especially compact layouts and Mac modifier placement.
- Confirm persistence behavior across application restarts and inspect how malformed or missing stored JSON is handled.
- Get the QML test runner working in a usable display/Qt environment, then add or run appropriate automated coverage if requested.

## Known issues and validation limits

- No shortcut dataset is currently available for Caelestia, DankShell, Noctalia, end-4, or HyDE Project; these are intentionally shown as unavailable.
- Persistence is implemented, but surviving a real restart has not yet been verified in this validation pass.
- Mouse and keyboard navigation through all dropdown options, all settings combinations, resize extremes, and physical modifier combinations still need hands-on verification.
- The test-runner attempt failed while initializing GTK/display. Treat this as an environment limitation, not evidence that application startup failed.
- The host emitted a non-fatal portal D-Bus warning during launch.

## Exact next steps

1. Launch the app with the command above and inspect the terminal for QML errors.
2. Try the Environment selector using both mouse and keyboard. Confirm Omarchy displays its own records and each other environment displays the unavailable message without Hyprland starter cards.
3. Exercise keyboard platform and every layout option. Resize the window and adjust keyboard scale at small and large sizes; check centering, proportions, spacing, and clipping.
4. Hover and click keys; press letter, special, and modifier-combination keys. Verify all simultaneously held keys highlight and tooltips show readable names. Click shortcut cards and verify both card selection and matching keyboard highlights.
5. Search using a shortcut name, description, application, category, environment, and normalized combinations such as `Ctrl+Shift+P`. Verify source/environment labeling.
6. Add/remove Favorites and open Recent entries, restart MacKey, then confirm both lists persist and remain correctly scoped.
7. Change theme, accent, installed font, font size, keyboard layout/scale, and behavior toggles. Restart and verify the preferences persist and apply consistently across views.
8. Check Learn with Omarchy data and with an environment that has no data. Confirm it never uses another environment's shortcuts.
9. Resolve the local `qmltestrunner` GTK/display setup or use a working Qt test/display environment; rerun `qmllint` and the app launch check after any code changes.
10. Only add environment shortcut data after verifying its source and environment association; keep data in the data layer.

## Deferred by scope

Hyprland config import improvements/UI, keybinding conflict detection, environment comparison, and adding new environment datasets are not implemented in this refinement pass. Do not start those until requested; the immediate follow-up is interactive verification and correcting any issues it reveals.
