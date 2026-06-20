<div align="center">

# 🎮 ControllerMapper

**Turn any Xbox-compatible controller into a fully programmable macOS input device — for gaming, studying, or media control.**

Map buttons to keystrokes, mouse clicks, scrolling, and macros — works great with genuine Xbox controllers, 8BitDo pads, and cheap clones like ShanWan that ship with no official Mac software at all.

[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue?style=flat-square)](#installation)
[![Swift](https://img.shields.io/badge/swift-5-orange?style=flat-square)](#installation)
[![License: MIT](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)
[![Latest Release](https://img.shields.io/github/v/release/joshuaforster/ControllerMapper?style=flat-square)](https://github.com/joshuaforster/ControllerMapper/releases/latest)
[![Stars](https://img.shields.io/github/stars/joshuaforster/ControllerMapper?style=flat-square)](https://github.com/joshuaforster/ControllerMapper/stargazers)

</div>

---

## Why this exists

Plenty of no-name "Xbox compatible" gamepads — ShanWan, generic Bluetooth clones, old PS3-style pads with an Xbox switch, even 8BitDo controllers in Xbox mode — work fine on macOS at the driver level (`GameController.framework` sees them just fine), but their manufacturers ship **zero Mac software**. No key mapping, no macro support, no battery indicator. ControllerMapper fills that gap as a free, open-source menu bar app.

It's not just for games either: a controller is a surprisingly good input device for **spaced-repetition study apps like Anki** (D-pad = grade your card, no keyboard reach needed) or for **controlling music/video playback from across the room**. Built-in presets cover both out of the box — see [Built-in presets](#built-in-presets) below.

If you searched for *"ShanWan controller Mac driver"*, *"map Xbox controller to keyboard Mac"*, *"gamepad as mouse Mac"*, *"controller key remapping macOS"*, *"Anki controller review"*, or *"8BitDo Mac mapping"* — this is built for exactly that.

## Features

- 🎮 **Universal detection** — works with anything that registers as an Xbox controller via `GameController.framework` (Xbox Series/One controllers, 8BitDo pads, ShanWan and other clones, generic Bluetooth gamepads)
- 🎨 **Controller-aware design** — the on-screen diagram automatically shows Xbox, PlayStation, Nintendo, or 8BitDo-style button glyphs depending on what's actually connected, with a manual override if you'd rather pick the look yourself
- ⌨️ **Full keyboard mapping** — any button → any key, including modifiers (⌘⇧⌥⌃)
- 🖱️ **Mouse control** — clicks, cursor movement via analog sticks, scroll wheel emulation
- 🔁 **Macros** — chain multiple key events with custom delays per step
- 🗂️ **Multiple profiles** — different mappings per game/app, color-coded, import/export as `.cmprofile`
- 📚 **Built-in presets** — ready-made profiles for [Anki](#built-in-presets) and media/playback control, not just gaming
- 🔋 **Live battery indicator** — animated ring gauge in the menu bar, with a Bluetooth fallback for controllers that don't report battery natively (common on clones)
- 🌙 **Works fully backgrounded** — mapping keeps running with just the menu bar icon visible; no window needs to stay open
- ⚡ **Global kill switch** — instantly pause all input injection without unplugging the controller
- 🧪 **Test button** — fire any mapped action once, without touching the controller
- 🔍 Searchable button list, About panel with live permission status
- 🚀 Launches at login, lives quietly in the menu bar
- ✨ **Live press glow** — the on-screen controller lights up in real time as you press physical buttons
- 🎮 **Controller-only profile switching** — hold **View + Menu** for a second to cycle profiles without touching your Mac
- 🥚 **Easter eggs & achievements** — a few secrets are hiding in the app, permanently tracked once you find them. One hint: try a classic ↑↑↓↓←←→→ B A combo on the controller.

## Built-in presets

Pick these straight from "New Profile" instead of mapping buttons from scratch:

| Preset | What it's for |
|---|---|
| **Anki Review** | D-pad / face buttons mapped to Again/Hard/Good/Easy and Space to flip the card — review your deck without touching the keyboard |
| **Media Control** | Play/pause, skip, volume, and seek mapped to the sticks and shoulder buttons — control music or video from the couch |

Both ship as regular profiles, so you can duplicate and tweak them like any other.

## Screenshot

> *Add a screenshot or GIF of the menu bar popover + mapping window here — drag one into this README on GitHub.com and it'll embed automatically.*

## Installation

### Option 1: Download (easiest)

Grab the latest build from the [**Releases page**](https://github.com/joshuaforster/ControllerMapper/releases/latest) — unzip, move `ControllerMapper.app` to `/Applications`, and open it. Since it isn't notarized yet, right-click → **Open** the first time (or **System Settings → Privacy & Security → Open Anyway**) to bypass Gatekeeper.

### Option 2: Build from source

**Requirements:** macOS 14 (Sonoma) or later, Xcode 15+.

```bash
git clone https://github.com/joshuaforster/ControllerMapper.git
cd ControllerMapper
open "Controller test.xcodeproj"
```

Then in Xcode:
1. **Signing & Capabilities** → select your Apple ID as Team (free personal team is fine — this keeps the code signature stable across rebuilds, which matters for permissions, see [FAQ](#faq))
2. ⌘R to build and run
3. On first launch: **System Settings → Privacy & Security → Accessibility** → enable ControllerMapper
4. Plug in or pair your controller — it's detected automatically

Full setup and distribution guide (code signing, notarization, DMG packaging) in [SETUP.md](SETUP.md).

## FAQ

**It keeps asking for Accessibility permission every time I rebuild — is that normal?**
Yes, if you haven't selected a Team in Signing & Capabilities. Without a stable code signature, macOS treats every rebuild as a "new app" and forgets the grant. Selecting any Apple ID as your team (even a free one) fixes this. Downloaded releases don't have this problem since they're signed consistently.

**Button mapping stops working once I close the app window — bug?**
No — and if you're on an older build, update: this is now handled automatically. The app sets `GCController.shouldMonitorBackgroundEvents = true` so controller input keeps flowing to the menu bar process even when no window is open and the app isn't frontmost (which is its normal state, being a menu bar app).

**My controller shows up but battery says "not reported".**
Common with clones — they don't implement the HID battery report `GCController` reads. If it's paired over real Bluetooth, use the in-app "Bluetooth Battery" picker to read the battery level macOS already tracks. Over USB or a 2.4 GHz dongle there's no system-level battery source, unfortunately.

**Can I force a specific controller design (e.g. PlayStation glyphs on a generic pad)?**
Yes — the design picker in the main window lets you override auto-detection with any supported style.

**Does this work with emulators like Dolphin?**
Likely yes, with no extra setup. ControllerMapper maps controller buttons to regular keyboard keys, and Dolphin (like most emulators) lets you bind its virtual GameCube/Wii controller to keyboard keys in its own input settings. Map your buttons in ControllerMapper, then bind those same keys inside Dolphin's controller config. If you hit a snag, please open an issue.

## Roadmap

Ideas being considered, not yet started:

- **Virtual gamepad driver** (DS4Windows-style) — would let the controller appear as a native virtual gamepad to apps that don't accept keyboard input, instead of (or alongside) key remapping. On macOS this requires a DriverKit system extension, which needs a paid Apple Developer Program membership and a separate driver-entitlement request from Apple — a much bigger undertaking than the app itself.
- **Windows version** — not a port (SwiftUI/AppKit/GameController.framework are Apple-only), but a ground-up rewrite using XInput/DirectInput and SendInput, most likely in C#/WPF.

Interested in either? Open an issue or a PR — contributions welcome.

**Why no App Store version?** <a name="why-no-app-store-version"></a>
The app injects keyboard/mouse events system-wide via `CGEventPost`, which requires running **without App Sandbox** — and Sandbox is mandatory for the App Store. This will ship as a Developer ID–signed direct download instead.

## Known limitations

- No system-level battery reporting for controllers connected via USB or 2.4 GHz dongle (Bluetooth-paired controllers can use the in-app fallback)
- The Xbox/Home button isn't exposed by `GameController.framework` on every macOS version

## Contributing

Issues and pull requests are welcome — especially compatibility reports for controllers you've tested (open an issue with the exact model/clone name, it helps everyone searching for the same hardware).

## Support

If this saved you from returning a "broken" controller, consider [buying the developer a coffee](https://www.buymeacoffee.com/joshuaforster) ☕️.

## License

[MIT](LICENSE)
