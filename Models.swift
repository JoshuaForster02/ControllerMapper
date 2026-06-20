import Foundation
import SwiftUI

// MARK: - Notifications

extension Notification.Name {
    /// Posted when the Konami-style button combo is detected.
    static let controllerMapperEasterEgg = Notification.Name("cm.easterEgg")
    /// Posted when a profile is switched via the controller's hold-shortcut.
    /// `object` is the new `Profile`.
    static let controllerMapperProfileSwitched = Notification.Name("cm.profileSwitchedViaController")
}

// MARK: - Controller Visual Style

/// Adapts the on-screen diamond (face buttons) to match what's actually
/// printed on the connected controller. GameController.framework already
/// normalizes button *positions* across brands (buttonA is always the
/// bottom action button, etc.), so this only needs to swap the symbol/label
/// shown — the geometry stays correct automatically.
enum ControllerVisualStyle: String, CaseIterable {
    case xbox
    case playStation
    case generic

    var displayName: String {
        switch self {
        case .xbox: return "Xbox-Style (ABXY)"
        case .playStation: return "PlayStation-Style (✕○□△)"
        case .generic: return "Generic (ABXY)"
        }
    }

    static func detect(productCategory: String) -> ControllerVisualStyle {
        let c = productCategory.lowercased()
        if c.contains("dualshock") || c.contains("dualsense") || c.contains("playstation") {
            return .playStation
        }
        if c.contains("xbox") {
            return .xbox
        }
        return .generic
    }

    struct FaceButtonStyle {
        let label: String
        let color: Color
    }

    /// Returns an override label/color for face buttons, or `nil` to keep
    /// the app's default Xbox-style ABXY look.
    func override(for button: ControllerButton) -> FaceButtonStyle? {
        guard self == .playStation else { return nil }
        switch button {
        case .a: return FaceButtonStyle(label: "✕", color: Color(hex: "#5B9CF5") ?? .blue)
        case .b: return FaceButtonStyle(label: "○", color: Color(hex: "#E8534A") ?? .red)
        case .x: return FaceButtonStyle(label: "□", color: Color(hex: "#F5739E") ?? .pink)
        case .y: return FaceButtonStyle(label: "△", color: Color(hex: "#42C35C") ?? .green)
        default: return nil
        }
    }
}

// MARK: - Controller Buttons

enum ControllerButton: String, CaseIterable, Codable, Hashable {
    // Face
    case a, b, x, y
    // Shoulders & Triggers
    case lb, rb, lt, rt
    // Stick clicks
    case l3, r3
    // D-Pad
    case dUp, dDown, dLeft, dRight
    // System
    case menu, view, home
    // Axes (for mouse movement / scroll)
    case leftStickX, leftStickY
    case rightStickX, rightStickY

    var displayName: String {
        switch self {
        case .a: return "A"
        case .b: return "B"
        case .x: return "X"
        case .y: return "Y"
        case .lb: return "LB"
        case .rb: return "RB"
        case .lt: return "LT"
        case .rt: return "RT"
        case .l3: return "L3 (Stick Click)"
        case .r3: return "R3 (Stick Click)"
        case .dUp: return "D-Pad ↑"
        case .dDown: return "D-Pad ↓"
        case .dLeft: return "D-Pad ←"
        case .dRight: return "D-Pad →"
        case .menu: return "Menu"
        case .view: return "View"
        case .home: return "Xbox Button"
        case .leftStickX: return "Left Stick X"
        case .leftStickY: return "Left Stick Y"
        case .rightStickX: return "Right Stick X"
        case .rightStickY: return "Right Stick Y"
        }
    }

    var isAxis: Bool {
        switch self {
        case .leftStickX, .leftStickY, .rightStickX, .rightStickY: return true
        default: return false
        }
    }

    var sfSymbol: String {
        switch self {
        case .a: return "a.circle.fill"
        case .b: return "b.circle.fill"
        case .x: return "x.circle.fill"
        case .y: return "y.circle.fill"
        case .lb: return "l.button.roundedbottom.horizontal.fill"
        case .rb: return "r.button.roundedbottom.horizontal.fill"
        case .lt: return "l.joystick.tilt.left.fill"
        case .rt: return "r.joystick.tilt.right.fill"
        case .l3, .r3: return "circle.fill"
        case .dUp, .dDown, .dLeft, .dRight: return "dpad.fill"
        case .menu: return "line.3.horizontal"
        case .view: return "square.on.square"
        case .home: return "house.fill"
        case .leftStickX, .leftStickY, .rightStickX, .rightStickY:
            return "arrow.left.and.right.circle.fill"
        }
    }

    // Buttons shown in the controller layout (axes handled separately)
    static var layoutButtons: [ControllerButton] {
        [.lb, .rb, .lt, .rt,
         .dUp, .dDown, .dLeft, .dRight,
         .l3, .r3,
         .a, .b, .x, .y,
         .menu, .view, .home]
    }
}

// MARK: - Key Mapping

struct KeyMapping: Codable, Hashable {
    var keyCode: UInt16
    var modifiers: UInt64   // CGEventFlags raw value
    var displayName: String

    static let none = KeyMapping(keyCode: 65535, modifiers: 0, displayName: "—")

    static let presets: [KeyMapping] = {
        let raw: [(UInt16, UInt64, String)] = [
            (49, 0, "Space"),
            (36, 0, "Return ↩"),
            (53, 0, "Escape"),
            (48, 0, "Tab ⇥"),
            (51, 0, "Delete ⌫"),
            (117, 0, "Fwd Delete"),
            (126, 0, "↑"),
            (125, 0, "↓"),
            (123, 0, "←"),
            (124, 0, "→"),
            (122, 0, "F1"), (120, 0, "F2"), (99, 0, "F3"), (118, 0, "F4"),
            (96, 0, "F5"),  (97, 0, "F6"),  (98, 0, "F7"), (100, 0, "F8"),
            (101, 0, "F9"), (109, 0, "F10"),(103, 0, "F11"),(111, 0, "F12"),
            (0, 0, "A"), (11, 0, "B"), (8, 0, "C"), (2, 0, "D"),
            (14, 0, "E"), (3, 0, "F"), (5, 0, "G"), (4, 0, "H"),
            (34, 0, "I"), (38, 0, "J"), (40, 0, "K"), (37, 0, "L"),
            (46, 0, "M"), (45, 0, "N"), (31, 0, "O"), (35, 0, "P"),
            (12, 0, "Q"), (15, 0, "R"), (1, 0, "S"), (17, 0, "T"),
            (32, 0, "U"), (9, 0, "V"), (13, 0, "W"), (7, 0, "X"),
            (16, 0, "Y"), (6, 0, "Z"),
            // With CMD
            (8, 0x100108, "⌘C"), (9, 0x100108, "⌘V"), (7, 0x100108, "⌘X"),
            (0, 0x100108, "⌘A"), (12, 0x100108, "⌘Q"), (13, 0x100108, "⌘W"),
            (17, 0x100108, "⌘T"), (15, 0x100108, "⌘R"), (5, 0x100108, "⌘G"),
            // With SHIFT
            (49, 0x20102, "⇧Space"),
            // Media
            (130, 0, "Vol Up"), (129, 0, "Vol Down"), (128, 0, "Mute"),
        ]
        return raw.map { KeyMapping(keyCode: $0.0, modifiers: $0.1, displayName: $0.2) }
    }()
}

// MARK: - Actions

enum ActionType: String, Codable, CaseIterable {
    case none           = "None"
    case keyPress       = "Key Press"
    case leftClick      = "Left Click"
    case rightClick     = "Right Click"
    case middleClick    = "Middle Click"
    case scrollUp       = "Scroll Up"
    case scrollDown     = "Scroll Down"
    case scrollLeft     = "Scroll Left"
    case scrollRight    = "Scroll Right"
    case mouseMoveAxis  = "Move Mouse"
    case macro          = "Macro"
    case openApp        = "Open App"

    var isAxisCompatible: Bool { self == .mouseMoveAxis }
    var sfSymbol: String {
        switch self {
        case .none: return "slash.circle"
        case .keyPress: return "keyboard"
        case .leftClick, .rightClick, .middleClick: return "cursorarrow.click"
        case .scrollUp, .scrollDown, .scrollLeft, .scrollRight: return "scroll"
        case .mouseMoveAxis: return "cursorarrow.motionlines"
        case .macro: return "list.bullet.rectangle"
        case .openApp: return "square.and.arrow.up"
        }
    }
}

struct MacroStep: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var keyMapping: KeyMapping = .none
    var keyDown: Bool = true
    var delayAfterMs: Int = 50
}

struct ButtonAction: Codable, Hashable {
    var type: ActionType = .none
    var keyMapping: KeyMapping = .none
    var macroSteps: [MacroStep] = []
    var mouseSensitivity: Double = 10.0
    var mouseInverted: Bool = false
    var appBundleID: String = ""
    var appName: String = ""
    var scrollAmount: Int = 10

    static let none = ButtonAction(type: .none)
}

// MARK: - Profile

struct Profile: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String = "New Profile"
    var colorHex: String = "#007AFF"
    var icon: String = "gamecontroller.fill"
    var autoSwitchBundleID: String = ""  // switch when this app is frontmost
    var mappings: [ControllerButton: ButtonAction] = [:]

    init(
        name: String = "New Profile",
        colorHex: String = "#007AFF",
        icon: String = "gamecontroller.fill"
    ) {
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
    }

    var swiftUIColor: Color {
        Color(hex: colorHex) ?? .blue
    }

    static let `default` = Profile(name: "Default", colorHex: "#30D158", icon: "gamecontroller.fill")

    // MARK: - Built-in Presets

    /// Ready-made profiles covering use cases beyond gaming — pick one as a
    /// starting point in "New Profile", then tweak freely.
    static var builtInPresets: [Profile] {
        [ankiPreset, mediaPreset]
    }

    private static var ankiPreset: Profile {
        var p = Profile(name: "Anki — Study", colorHex: "#5AC8FA", icon: "graduationcap.fill")
        p.mappings[.a]  = ButtonAction(type: .keyPress, keyMapping: KeyMapping(keyCode: 49, modifiers: 0, displayName: "Space"))       // Show Answer
        p.mappings[.b]  = ButtonAction(type: .keyPress, keyMapping: KeyMapping(keyCode: 18, modifiers: 0, displayName: "1"))           // Again
        p.mappings[.x]  = ButtonAction(type: .keyPress, keyMapping: KeyMapping(keyCode: 19, modifiers: 0, displayName: "2"))           // Hard
        p.mappings[.y]  = ButtonAction(type: .keyPress, keyMapping: KeyMapping(keyCode: 20, modifiers: 0, displayName: "3"))           // Good
        p.mappings[.rb] = ButtonAction(type: .keyPress, keyMapping: KeyMapping(keyCode: 21, modifiers: 0, displayName: "4"))           // Easy
        p.mappings[.lb] = ButtonAction(type: .keyPress, keyMapping: KeyMapping(keyCode: 6,  modifiers: 0x100108, displayName: "⌘Z"))   // Undo
        return p
    }

    private static var mediaPreset: Profile {
        var p = Profile(name: "Media Control", colorHex: "#FF9500", icon: "play.circle.fill")
        p.mappings[.a]      = ButtonAction(type: .keyPress, keyMapping: KeyMapping(keyCode: 49,  modifiers: 0, displayName: "Space"))  // Play/Pause
        p.mappings[.dLeft]  = ButtonAction(type: .keyPress, keyMapping: KeyMapping(keyCode: 123, modifiers: 0, displayName: "←"))       // Rewind
        p.mappings[.dRight] = ButtonAction(type: .keyPress, keyMapping: KeyMapping(keyCode: 124, modifiers: 0, displayName: "→"))       // Forward
        p.mappings[.dUp]    = ButtonAction(type: .keyPress, keyMapping: KeyMapping(keyCode: 126, modifiers: 0, displayName: "↑"))       // Volume up
        p.mappings[.dDown]  = ButtonAction(type: .keyPress, keyMapping: KeyMapping(keyCode: 125, modifiers: 0, displayName: "↓"))       // Volume down
        return p
    }
}

// MARK: - Color Helper

extension Color {
    init?(hex: String) {
        let h = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: h).scanHexInt64(&rgb) else { return nil }
        self.init(
            red:   Double((rgb & 0xFF0000) >> 16) / 255,
            green: Double((rgb & 0x00FF00) >> 8)  / 255,
            blue:  Double( rgb & 0x0000FF)         / 255
        )
    }

    var hexString: String {
        let c = NSColor(self).usingColorSpace(.sRGB) ?? NSColor(self)
        let r = Int((c.redComponent   * 255).rounded())
        let g = Int((c.greenComponent * 255).rounded())
        let b = Int((c.blueComponent  * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
