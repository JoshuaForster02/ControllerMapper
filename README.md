<div align="center">

# 🎮 ControllerMapper

**Turn any Xbox-compatible controller into a fully programmable macOS input device.**

Map buttons to keystrokes, mouse clicks, scrolling, and macros — works great with genuine Xbox controllers *and* cheap clones like ShanWan that have no official Mac software.

[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue?style=flat-square)](#installation)
[![Swift](https://img.shields.io/badge/swift-5-orange?style=flat-square)](#installation)
[![License: MIT](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)
[![Stars](https://img.shields.io/github/stars/joshuaforster/ControllerMapper?style=flat-square)](https://github.com/joshuaforster/ControllerMapper/stargazers)

</div>

---

## Why this exists

Plenty of no-name "Xbox compatible" gamepads — ShanWan, generic Bluetooth clones, old PS3-style pads with an Xbox switch — work fine on macOS at the driver level (`GameController.framework` sees them just fine), but their manufacturers ship **zero Mac software**. No key mapping, no macro support, no battery indicator. ControllerMapper fills that gap as a free, open-source menu bar app.

If you searched for *"ShanWan controller Mac driver"*, *"map Xbox controller to keyboard Mac"*, *"gamepad as mouse Mac"*, or *"controller key remapping macOS"* — this is built for exactly that.

## Features

- 🎮 **Universal detection** — works with anything that registers as an Xbox controller via `GameController.framework` (Xbox Series/One controllers, ShanWan and other clones, generic Bluetooth gamepads)
- ⌨️ **Full keyboard mapping** — any button → any key, including modifiers (⌘⇧⌥⌃)
- 🖱️ **Mouse control** — clicks, cursor movement via analog sticks, scroll wheel emulation
- 🔁 **Macros** — chain multiple key events with custom delays per step
- 🔋 **Live battery indicator** — animated ring gauge in the menu bar, with a Bluetooth fallback for controllers that don't report battery natively (common on clones)
- 🗂️ **Multiple profiles** — different mappings per game/app, color-coded, import/export as `.cmprofile`
- ⚡ **Global kill switch** — instantly pause all input injection without unplugging the controller
- 🧪 **Test button** — fire any mapped action once, without touching the controller
- 🔍 Searchable button list, About panel with live permission status
- 🚀 Launches at login, lives quietly in the menu bar

## Screenshot

> *Add a screenshot or GIF of the menu bar popover + mapping window here — drag one into this README on GitHub.com and it'll embed automatically.*

## Installation

### Requirements

- macOS 14 (Sonoma) or later
- Xcode 15+ (to build from source — there's no signed binary release yet, see [why](#why-no-app-store-version))

### Build from source

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
Yes, if you haven't selected a Team in Signing & Capabilities. Without a stable code signature, macOS treats every rebuild as a "new app" and forgets the grant. Selecting any Apple ID as your team (even a free one) fixes this.

**My controller shows up but battery says "not reported".**
Common with clones — they don't implement the HID battery report `GCController` reads. If it's paired over real Bluetooth, use the in-app "Bluetooth Battery" picker to read the battery level macOS already tracks. Over USB or a 2.4 GHz dongle there's no system-level battery source, unfortunately.

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
