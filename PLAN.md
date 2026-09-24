Ich möchte eine kleine macOS-App in Swift/AppKit bauen, mit der ich in jeder App schnell Sonderzeichen (vor allem Pfeile) einfügen kann. Zielgerät: MacBook Pro 2019 (Intel) mit Touch Bar. Nur für den Eigengebrauch, kein App Store.

## Ziel
- Ein Button in der Touch-Bar-Control-Strip, der systemweit (in jeder App) sichtbar ist.
- Tipp darauf öffnet eine system-modale Touch Bar mit Kategorien; jede Kategorie zeigt Symbole in einem horizontal scrollbaren NSScrubber.
- Tipp auf ein Symbol fügt es in das aktuell fokussierte Textfeld der Vordergrund-App ein und schließt die modale Touch Bar wieder.
- Zusätzlich ein zweites Frontend: globaler Hotkey (Standard ⌥⇧Space) öffnet ein kleines schwebendes Panel mit denselben Kategorien/Symbolen, per Maus oder Pfeiltasten+Enter bedienbar. Das Panel darf der Vordergrund-App NICHT den Fokus stehlen (NSPanel mit .nonactivatingPanel).

## Architektur
- AppKit, kein SwiftUI für die Touch Bar (NSTouchBar ist AppKit). SwiftUI im Hotkey-Panel ist ok, falls sinnvoll.
- Hintergrund-App: LSUIElement = YES, Menüleisten-Icon (NSStatusItem) mit Einträgen: "Bedienungshilfen prüfen", "Konfiguration öffnen", "Konfiguration neu laden", "Beenden".
- Klare Trennung:
  - `SymbolInserter` — fügt einen String per CGEvent ein (CGEvent keyboardSetUnicodeString, keyDown+keyUp, post an .cghidEventTap). Kein Umweg über die Zwischenablage.
  - `SymbolStore` — lädt Kategorien/Symbole aus ~/Library/Application Support/<AppName>/symbols.json; legt beim ersten Start eine Standarddatei an.
  - `TouchBarController` — Control-Strip-Integration über private API.
  - `HotkeyPanelController` — globaler Hotkey + Panel. Hotkey über Carbon RegisterEventHotKey (keine Drittanbieter-Abhängigkeit).
- Beim Start AXIsProcessTrustedWithOptions prüfen und bei fehlender Berechtigung den Dialog auslösen + im Menü deutlich anzeigen.

## Private API (Touch Bar Control Strip)
- Private Framework /System/Library/PrivateFrameworks/DFRFoundation.framework linken (Framework Search Path setzen).
- Bridging Header mit Deklarationen:
  - extern void DFRElementSetControlStripPresenceForIdentifier(NSTouchBarItemIdentifier, BOOL);
  - extern void DFRSystemModalShowsCloseBoxWhenFrontMost(BOOL);
  - Kategorie auf NSTouchBarItem: +addSystemTrayItem:, +removeSystemTrayItem:
  - Kategorie auf NSTouchBar: +presentSystemModalTouchBar:systemTrayItemIdentifier:, +presentSystemModalTouchBar:placement:systemTrayItemIdentifier:, +dismissSystemModalTouchBar:, +minimizeSystemModalTouchBar:
- Mit respondsToSelector: prüfen, welche Selektor-Varianten es auf dem System gibt, und sauber fallbacken bzw. loggen, statt zu crashen. Orientiere dich an der Umsetzung in Open-Source-Projekten wie Pock oder MTMR, falls nötig.
- Hinweis im README: In den Systemeinstellungen muss die Touch Bar so eingestellt sein, dass die Control Strip angezeigt wird.

## Standard-Symbole (symbols.json)
- Pfeile: → ← ↑ ↓ ↔ ↕ ⇒ ⇐ ⇔ ↗ ↘ ↩ ⟶
- Typografie: – — … • · „ “ ‚ ‘ « » ‹ › § ¶ †
- Mathe: × ÷ ± ≈ ≠ ≤ ≥ ∞ √ ∑ ° ‰ ² ³ ½
- Sonstiges: ✓ ✗ ★ ☆ ⌘ ⌥ ⇧ ⌃ ⏎ ⌫ € ™ © ®
JSON-Schema: Array von { "name": String, "symbols": [String] }. Reihenfolge = Anzeigereihenfolge. Fehlerhafte JSON-Datei darf die App nicht crashen: Fehler loggen, Standardwerte nutzen, im Menü anzeigen.

## Build & Signierung
- Xcode-Projekt, Deployment Target macOS 12, Swift 5.
- Kein App Sandbox (verträgt sich nicht mit CGEvent-Posting und privaten Frameworks). Hardened Runtime aus oder passend konfiguriert.
- Mit stabiler Identität signieren (Apple Development), NICHT ad-hoc, damit die Bedienungshilfen-Berechtigung zwischen Builds erhalten bleibt. Erkläre mir im README, wie ich das einrichte und wie ich die Berechtigung zurücksetze (tccutil reset Accessibility <bundle-id>).
- Optional: Start bei Anmeldung über SMAppService.mainApp, per Menü-Toggle.

## Vorgehen
1. Erst SymbolInserter + Menüleisten-App + Berechtigungsprüfung, testbar über einen Menüeintrag "Test: → einfügen".
2. Dann SymbolStore mit JSON.
3. Dann Hotkey-Panel.
4. Zuletzt die Touch-Bar-Integration über private API.
Nach jedem Schritt kurz zusammenfassen, was ich manuell testen soll. Wenn etwas an der privaten API auf meinem System nicht funktioniert, sag es klar, statt es zu verschleiern.

## Nicht gewünscht
- Keine Drittanbieter-Pakete, sofern nicht zwingend nötig.
- Keine Zwischenablage-Hacks zum Einfügen.
- Keine unnötigen Abstraktionsschichten; das ist ein kleines persönliches Tool.
