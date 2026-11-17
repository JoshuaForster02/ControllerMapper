import Foundation
import CoreGraphics
import ApplicationServices
import AppKit

/// Injects keyboard, mouse and scroll events via CGEvent.
/// Requires Accessibility permission, requested only by an explicit user action.
final class EventInjector {

    static let shared = EventInjector()
    private let eventSource = CGEventSource(stateID: .hidSystemState)
    private var heldKeys: [UInt16: (Int, UInt64)] = [:]
    private var heldMouse: [UInt32: Int] = [:]
    private var macroTasks: [UUID: Task<Void, Never>] = [:]
    private var generation = 0
    private init() {}

    // MARK: - Accessibility

    static func requestAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(opts)
    }

    static var isAccessibilityGranted: Bool { AXIsProcessTrusted() }

    // MARK: - Key Press

    func keyPress(keyCode: UInt16, modifiers: UInt64, down: Bool) {
        guard keyCode != 65535 else { return }
        var flags = modifiers
        if down {
            guard Self.isAccessibilityGranted else { return }
            if let held = heldKeys[keyCode] { heldKeys[keyCode] = (held.0 + 1, held.1); return }
            heldKeys[keyCode] = (1, modifiers)
        } else {
            guard let held = heldKeys[keyCode] else { return }
            if held.0 > 1 { heldKeys[keyCode] = (held.0 - 1, held.1); return }
            heldKeys.removeValue(forKey: keyCode); flags = held.1
        }
        guard Self.isAccessibilityGranted,
              let event = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: down) else { return }
        event.flags = CGEventFlags(rawValue: flags)
        event.post(tap: .cgAnnotatedSessionEventTap)
    }
    func releaseAll() {
        generation += 1; macroTasks.values.forEach { $0.cancel() }; macroTasks.removeAll()
        for (code, held) in Array(heldKeys) { heldKeys[code] = (1, held.1); keyPress(keyCode: code, modifiers: held.1, down: false) }
        for raw in Array(heldMouse.keys) {
            heldMouse[raw] = 1
            if let button = CGMouseButton(rawValue: raw) { mouseClick(button: button, down: false) }
        }
    }
    func keyTap(mapping: KeyMapping) {
        guard mapping.keyCode != 65535 else { return }
        keyPress(keyCode: mapping.keyCode, modifiers: mapping.modifiers, down: true)
        keyPress(keyCode: mapping.keyCode, modifiers: mapping.modifiers, down: false)
    }

    // MARK: - Mouse Click

    func mouseClick(button: CGMouseButton, down: Bool) {
        let raw = button.rawValue
        if down {
            guard Self.isAccessibilityGranted else { return }
            let count = heldMouse[raw, default: 0]; heldMouse[raw] = count + 1
            if count > 0 { return }
        } else {
            guard let count = heldMouse[raw] else { return }
            if count > 1 { heldMouse[raw] = count - 1; return }
            heldMouse.removeValue(forKey: raw)
        }
        guard Self.isAccessibilityGranted else { return }
        let position = NSEvent.mouseLocation
        let cgPoint = CGPoint(x: position.x,
                              y: (NSScreen.main?.frame.height ?? 800) - position.y)

        let downType: CGEventType
        let upType:   CGEventType
        switch button {
        case .left:   downType = .leftMouseDown;  upType = .leftMouseUp
        case .right:  downType = .rightMouseDown; upType = .rightMouseUp
        default:      downType = .otherMouseDown; upType = .otherMouseUp
        }

        let type = down ? downType : upType
        let event = CGEvent(mouseEventSource: eventSource, mouseType: type,
                            mouseCursorPosition: cgPoint, mouseButton: button)
        event?.post(tap: .cgAnnotatedSessionEventTap)
    }

    func mouseClick(button: CGMouseButton) {
        mouseClick(button: button, down: true)
        mouseClick(button: button, down: false)
    }

    // MARK: - Mouse Move

    func moveMouse(dx: Double, dy: Double) {
        let position = NSEvent.mouseLocation
        let screen = NSScreen.main?.frame.height ?? 800
        let newPoint = CGPoint(
            x: position.x + dx,
            y: screen - position.y - dy   // screen coords Y flipped
        )
        let event = CGEvent(mouseEventSource: eventSource, mouseType: .mouseMoved,
                            mouseCursorPosition: newPoint, mouseButton: .left)
        event?.post(tap: .cgAnnotatedSessionEventTap)
    }

    // MARK: - Scroll

    func scroll(dx: Int, dy: Int) {
        // .line units = discrete scroll wheel behaviour (what apps actually respond to).
        // .pixel would produce continuous/trackpad-style events that most apps ignore.
        let event = CGEvent(scrollWheelEvent2Source: eventSource,
                            units: .line,
                            wheelCount: 2,
                            wheel1: Int32(dy),
                            wheel2: Int32(dx),
                            wheel3: 0)
        event?.post(tap: .cgAnnotatedSessionEventTap)
    }

    // MARK: - Macro

    func executeMacro(_ steps: [MacroStep]) {
        let id = UUID(), expectedGeneration = generation
        macroTasks[id] = Task { @MainActor [weak self] in
            guard let self else { return }
            var owned: [UInt16: (Int, UInt64)] = [:]
            defer {
                if expectedGeneration == self.generation {
                    for (code, hold) in owned {
                        for _ in 0..<hold.0 { self.keyPress(keyCode: code, modifiers: hold.1, down: false) }
                    }
                }
                self.macroTasks.removeValue(forKey: id)
            }
            var elapsed = 0
            for step in steps.prefix(200) {
                guard !Task.isCancelled, expectedGeneration == self.generation else { return }
                let key = step.keyMapping
                if key.keyCode != 65535 {
                    if step.keyDown {
                        let old = owned[key.keyCode] ?? (0, key.modifiers)
                        owned[key.keyCode] = (old.0 + 1, old.1)
                        self.keyPress(keyCode: key.keyCode, modifiers: key.modifiers, down: true)
                    } else if let old = owned[key.keyCode] {
                        self.keyPress(keyCode: key.keyCode, modifiers: old.1, down: false)
                        if old.0 == 1 { owned.removeValue(forKey: key.keyCode) }
                        else { owned[key.keyCode] = (old.0 - 1, old.1) }
                    }
                }
                let delay = min(10000, max(0, step.delayAfterMs)); elapsed += delay
                guard elapsed <= 60000 else { return }
                if delay > 0 {
                    do { try await Task.sleep(nanoseconds: UInt64(delay) * 1_000_000) }
                    catch { return }
                }
            }
        }
    }
    // MARK: - Open App

    func openApp(bundleID: String) {
        guard !bundleID.isEmpty,
              let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }
}
