# ControllerMapper

Eine native macOS-Menüleisten-App, die Xbox-kompatible Controller (auch günstige Klone wie ShanWan) auf Tastatur, Maus, Scroll und Macros mappt — mit mehreren Profilen, Live-Akkuanzeige und Bluetooth-Fallback für Controller ohne native Akku-Meldung.

![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue)
![Swift](https://img.shields.io/badge/swift-5-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- 🎮 Erkennt jeden Controller, der sich über `GameController.framework` als Xbox-Controller meldet (Xbox-Controller, ShanWan- und andere Klone)
- 🔋 Live-Akkuanzeige in der Menüleiste mit animiertem Ring-Indikator
- 🔵 Bluetooth-Akku-Fallback für Controller, die keinen nativen Akkustand melden
- 🗂️ Mehrere Profile mit eigenen Farben/Icons, Import/Export als `.cmprofile`
- ⌨️ Mapping auf Tastendrücke (inkl. Modifier ⌘⇧⌥⌃), Mausklicks, Mausbewegung über Analog-Sticks, Scroll und Macros
- ⚡ Globaler An/Aus-Schalter, um die Eingabe-Injection jederzeit zu pausieren
- 🧪 "Testen"-Button pro Zuweisung, um sie ohne Controller auszuprobieren
- 🔍 Suchbare Button-Liste, About-Fenster mit Berechtigungsstatus
- 🚀 Autostart beim Login

## Installation

### Voraussetzungen

- macOS 14 (Sonoma) oder neuer
- Xcode 15 oder neuer (zum Selbstbauen)

### Build

1. Repository klonen
2. `Controller test.xcodeproj` in Xcode öffnen
3. ⌘R drücken
4. Beim ersten Start: Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen → ControllerMapper erlauben

Ausführliche Setup- und Distributions-Anleitung (Code Signing, Notarization, DMG) siehe [SETUP.md](SETUP.md).

## Warum keine App-Store-Version?

Die App injiziert systemweit Tastatur- und Mausereignisse über `CGEventPost`. Das erfordert, dass die App **ohne App Sandbox** läuft — und Sandbox ist Pflicht für den App Store. Die App wird daher als Developer-ID-signierte App direkt zum Download angeboten.

## Bekannte Einschränkungen

- Manche günstigen Controller-Klone melden ihren Akkustand über keine vom System lesbare Schnittstelle — dafür gibt es den Bluetooth-Fallback, der aber nur bei echter Bluetooth-Kopplung funktioniert (nicht bei USB/2.4GHz-Dongle).
- Der Xbox-/Home-Button wird nicht von jeder macOS-Version über `GameController.framework` freigegeben.

## Mitwirken

Issues und Pull Requests sind willkommen.

## Unterstützen

Wenn dir die App hilft, kannst du den Entwickler über [Buy Me a Coffee](https://www.buymeacoffee.com/joshuaforster) unterstützen ☕️.

## Lizenz

[MIT](LICENSE)
