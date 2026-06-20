# ControllerMapper – Xcode Setup

## Anforderungen
- Xcode 15 oder neuer
- macOS 14 (Sonoma) oder neuer als Target

---

## 1. Xcode-Projekt erstellen

1. **Xcode öffnen** → *File → New → Project*
2. **macOS** → **App** → *Next*
3. Felder ausfüllen:
   | Feld | Wert |
   |---|---|
   | Product Name | ControllerMapper |
   | Team | (dein Apple ID) |
   | Organization Identifier | com.deinname |
   | Interface | **SwiftUI** |
   | Language | **Swift** |
4. Speicherort wählen → *Create*

---

## 2. Swift-Dateien hinzufügen

Alle `.swift`-Dateien aus diesem Ordner in Xcode ziehen:

- `Models.swift`
- `ControllerMapperApp.swift`
- `ControllerManager.swift`
- `ProfileManager.swift`
- `MappingEngine.swift`
- `EventInjector.swift`
- `MenuBarView.swift`
- `MainWindowView.swift`
- `ControllerLayoutView.swift`
- `MappingDetailView.swift`

Die **automatisch erstellte** `ContentView.swift` und `YourApp.swift` löschen (Xcode hat eigene erstellt – die werden durch unsere ersetzt).

---

## 3. Info.plist anpassen

In Xcode: *Projekt → Target → Info*

| Key | Value |
|---|---|
| `Application is agent (UIElement)` | **YES** – kein Dock-Icon |
| `Privacy - Accessibility Usage Description` | "ControllerMapper braucht Zugriff, um Tasten- und Mauseingaben zu injizieren." |
| `Privacy - AppleEvents Sending Usage Description` | "Zum Öffnen von Apps per Controller-Taste." |

---

## 4. Frameworks hinzufügen

*Projekt → Target → General → Frameworks, Libraries and Embedded Content*

Auf **+** klicken und hinzufügen:
- `GameController.framework`
- `CoreGraphics.framework` (meist schon vorhanden)
- `ServiceManagement.framework`

---

## 5. Signing & Capabilities

- *Signing & Capabilities → + Capability*
- **Hardened Runtime** hinzufügen
- Haken setzen bei: **Input Monitoring** (für spätere MAS-Distribution)

---

## 6. Minimum Deployment Target

*General → Minimum Deployments → macOS 14.0*

---

## 7. Build & Run

1. **⌘R** zum Bauen
2. Beim ersten Start: **Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen**
   → ControllerMapper erlauben
3. Das App-Icon erscheint in der **Menüleiste** (Gamepad-Symbol)
4. Controller anschließen (USB oder Bluetooth) → automatisch erkannt
5. Menüleiste-Icon klicken → *Open Mapper* → Buttons zuweisen

---

## Funktionen

| Feature | Status |
|---|---|
| Xbox S Controller erkennen | ✅ |
| Akku-Anzeige in Menüleiste | ✅ |
| Bluetooth-Akku-Fallback (für Controller ohne GC-Battery) | ✅ |
| Mehrere Profile | ✅ |
| Profile aktivieren | ✅ |
| Profile im/exportieren (.cmprofile) | ✅ |
| Keyboard Keys mappen | ✅ |
| Modifier Keys (⌘⇧⌥⌃) | ✅ |
| Maus-Clicks mappen | ✅ |
| Maus-Bewegung (Analog Sticks) | ✅ |
| Scroll mappen | ✅ |
| Macros (Sequenzen mit Delays) | ✅ |
| Apps öffnen | ✅ |
| Autostart beim Login | ✅ |
| Key-Capture (einfach drücken) | ✅ |
| Globaler An/Aus-Schalter (Mapping pausieren) | ✅ |
| Suche in Button-Liste | ✅ |
| About-Fenster mit Berechtigungs-Status | ✅ |
| Eigenes App-Icon | ✅ |

---

## Bekannte Einschränkungen

- **Accessibility Permission** muss manuell erteilt werden (macOS-Sicherheit)
- Home/Xbox-Button: `GCController` gibt ihn nicht auf allen macOS-Versionen frei
- ShanWan wird als "Xbox Controller" erkannt → alle Buttons funktionieren trotzdem
- Akku ohne GC-Battery-Support: nur via Bluetooth-Fallback lösbar (Einstellung im Hauptfenster, Toolbar-Button "Bluetooth-Akku") — bei USB/2.4GHz-Dongle gibt es keine Systemquelle dafür
- Für App Store Distribution: Entitlement `com.apple.security.temporary-exception.mach-lookup.global-name` nötig (für CGEventPost) — App Sandbox muss dafür aktiviert sein, was im Widerspruch zu globaler Event-Injection steht. Realistisch: **Distribution außerhalb des App Stores** (Direct Download / Developer ID).

---

## Distribution außerhalb des App Stores

Da die App systemweit Tasten/Maus injiziert, **keine App-Sandbox** nutzt — das schließt App Store Distribution faktisch aus. Der richtige Weg ist **Developer ID Signing + Notarization**, dann als DMG verteilen.

### Voraussetzung
- Kostenpflichtige **Apple Developer Program**-Mitgliedschaft (99 $/Jahr)
- Ohne Apple Developer Account: App läuft nur lokal bei dir, Verteilung an andere Nutzer würde bei denen "nicht verifizierter Entwickler" auslösen (Gatekeeper)

### 1. Signing-Zertifikat einrichten
*Xcode → Settings → Accounts → dein Apple-Account hinzufügen*
*Projekt → Signing & Capabilities → Team auswählen, Signing Certificate: "Developer ID Application"*

### 2. Archive bauen
```
Product → Archive (⌘B reicht nicht, Archive ist nötig für Distribution-Export)
```
Im Organizer: **Distribute App → Direct Distribution → Export**

### 3. Notarization (Apple prüft die App automatisch auf Malware)
```bash
xcrun notarytool submit "ControllerMapper.app.zip" \
  --apple-id "deine@appleid.com" \
  --team-id "DEINTEAMID" \
  --password "app-spezifisches-passwort" \
  --wait
```
App-spezifisches Passwort erstellen unter: appleid.apple.com → Sicherheit → App-spezifische Passwörter

### 4. Notarization-Ticket einbetten
```bash
xcrun stapler staple "ControllerMapper.app"
```

### 5. DMG erstellen
```bash
hdiutil create -volname "ControllerMapper" \
  -srcfolder "ControllerMapper.app" \
  -ov -format UDZO \
  "ControllerMapper.dmg"
```

### 6. Verifizieren
```bash
spctl -a -vvv -t install ControllerMapper.dmg
```
Sollte `accepted` zeigen — dann öffnet sich die App bei jedem Nutzer ohne Gatekeeper-Warnung.

---

## Troubleshooting

**Controller wird nicht erkannt:**
→ USB-Kabel versuchen → dann Bluetooth neu koppeln

**Tasten-Injection funktioniert nicht:**
→ Systemeinstellungen → Bedienungshilfen → App neu hinzufügen

**Akku zeigt "nicht meldbar":**
→ Hauptfenster öffnen → Toolbar → "Bluetooth-Akku" → gekoppeltes Gerät auswählen (nur falls Controller per echtem Bluetooth verbunden ist)

**"Open Mapper" reagiert nicht:**
→ App einmal komplett beenden (Menüleiste → Power-Icon) und neu starten — SwiftUI-Window-Scenes brauchen manchmal einen Neustart nach Codeänderungen
