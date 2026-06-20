import Foundation
import SwiftUI

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
