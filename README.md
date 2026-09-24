# touchBarText

Kleine macOS-Menüleisten-App (AppKit, Swift), um in jeder App schnell Sonderzeichen einzufügen — über einen Button in der Touch-Bar-Control-Strip und über ein globales Hotkey-Panel (⌥⇧Space). Nur für den Eigengebrauch, kein App Store.

## Voraussetzungen

- Xcode 16, Deployment Target macOS 12.0.
- Das Projekt wird mit [XcodeGen](https://github.com/yonaskolb/XcodeGen) aus `project.yml` generiert. Nach Änderungen an `project.yml` oder neuen Dateigruppen: `xcodegen generate`.

## Bauen

```
xcodegen generate
open touchBarText.xcodeproj
```

In Xcode ⌘R zum Starten. Die App zeigt kein Fenster und kein Dock-Icon (`LSUIElement`), nur ein Icon in der Menüleiste.

## Code-Signing einrichten (wichtig!)

Damit die einmal erteilte Bedienungshilfen-Berechtigung (Accessibility) nach jedem Rebuild erhalten bleibt, braucht die App eine **stabile** Signatur — keine Ad-hoc-Signatur, die sich bei jedem Build ändert.

1. Xcode → Settings → Accounts → eigene Apple-ID hinzufügen (ein kostenloser "Personal Team"-Account genügt).
2. Projekt `touchBarText` auswählen → Target `touchBarText` → Tab **Signing & Capabilities**.
3. **Automatically manage signing** aktivieren.
4. **Team** auf das eigene (Personal) Team setzen — **nicht** auf "None" / "Sign to Run Locally" lassen.
5. Prüfen, dass unter "Signing Certificate" tatsächlich `Apple Development: <deine E-Mail> (TEAMID)` steht.

Solange Bundle-ID (`com.maxim.touchBarText`) und Team gleich bleiben, bleibt die Berechtigung über Rebuilds hinweg erhalten.

**App Sandbox ist absichtlich nicht aktiviert** (verträgt sich nicht mit CGEvent-Posting und privaten Frameworks) und **Hardened Runtime ist aus** — beides ist in `project.yml` so konfiguriert und sollte in Xcode nicht nachträglich aktiviert werden.

### Berechtigung zurücksetzen

Zum erneuten Testen des Bedienungshilfen-Dialogs:

```
tccutil reset Accessibility com.maxim.touchBarText
```

## Touch-Bar-Einstellungen

Damit das Control-Strip-Icon erscheint, muss die Touch Bar in den Systemeinstellungen so konfiguriert sein, dass die **Control Strip** angezeigt wird (Systemeinstellungen → Tastatur → Touch Bar zeigt: "App-Steuerelemente mit Control Strip", nicht z. B. eine feste F1–F12-Belegung).

## Konfiguration

Die Symbol-Kategorien liegen in `~/Library/Application Support/touchBarText/symbols.json` (wird beim ersten Start mit Standardwerten angelegt). Format:

```json
[
  { "name": "Pfeile", "symbols": ["→", "←", "…"] }
]
```

Über das Menüleisten-Icon: "Konfiguration öffnen" (zeigt die Datei im Finder) und "Konfiguration neu laden" (lädt sie neu, ohne die App neu zu starten). Eine fehlerhafte JSON-Datei lässt die App nicht abstürzen — sie fällt auf die Standardwerte zurück und zeigt einen Hinweis im Menü.

## Bedienung

- **Menüleiste**: Klick auf "Test: → einfügen" fügt testweise einen Pfeil an der Cursor-Position ein; "Bedienungshilfen prüfen" zeigt den aktuellen Berechtigungsstatus.
- **Globaler Hotkey** ⌥⇧Space: öffnet ein schwebendes Panel (stiehlt der Vordergrund-App nicht den Fokus). Pfeiltasten hoch/runter wechseln die Kategorie, links/rechts das Symbol, Enter fügt ein, Escape / erneutes ⌥⇧Space schließt das Panel. Auswahl per Mausklick funktioniert ebenso.
- **Touch Bar**: Icon in der Control Strip antippen öffnet eine system-modale Touch Bar mit Kategorie-Umschalter (Segmented Control) und einem Scrubber für die Symbole der gewählten Kategorie. Antippen eines Symbols fügt es ein und schließt die modale Touch Bar automatisch.

## Bekannte Risiken (private API)

Die Touch-Bar-Control-Strip-Integration nutzt undokumentierte, private macOS-APIs (`DFRFoundation`, private Kategorien auf `NSTouchBar`/`NSTouchBarItem`). Das ist der einzige Weg, ein systemweites Control-Strip-Icon ohne App Store / Notarization-Beschränkungen zu realisieren, hat aber Konsequenzen:

- `DFRFoundation.framework` existiert seit macOS Big Sur nicht mehr als Datei auf der Platte, nur noch im `dyld_shared_cache`. Die App lädt die beiden benötigten Funktionen deshalb per `dlopen`/`dlsym` zur Laufzeit statt sie zu linken.
- Alle privaten Aufrufe sind mit `responds(to:)`-Prüfungen abgesichert: Ist eine Funktion/Methode auf dem jeweiligen macOS nicht vorhanden, loggt die App das (sichtbar in Console.app, Filter nach "touchBarText:") und deaktiviert nur das Touch-Bar-Feature — kein Crash. Das Hotkey-Panel funktioniert davon unabhängig immer.
- Ein künftiges macOS-Update kann diese private API jederzeit ändern oder entfernen, ohne Ankündigung. Falls das Control-Strip-Icon nach einem Systemupdate nicht mehr erscheint oder reagiert, ist das ein bekanntes Risiko dieses Ansatzes — bitte in dem Fall die Console-Logs prüfen.

## Start bei Anmeldung

Über den Menüpunkt "Bei Anmeldung starten" umschaltbar (`SMAppService.mainApp`). Da diese API erst ab macOS 13 existiert (Deployment Target hier: macOS 12), wird der Menüpunkt auf älteren Systemen automatisch ausgeblendet.
