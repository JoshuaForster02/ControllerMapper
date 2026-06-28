import Foundation
import CoreGraphics
import ApplicationServices
import AppKit

/// Injects keyboard, mouse and scroll events via CGEvent.
/// Requires Accessibility permission (requested on first launch).
final class EventInjector {

    static let shared = EventInjector()
    private let eventSource = CGEventSource(stateID: .hidSystemState)
    private init() {}

    // MARK: - Accessibility

    static func requestAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        // Only open System Settings once — not on every rebuild.
        // After the first prompt the About panel's "Öffnen" button handles re-granting.
        let key = "cm_accessibility_prompted_once"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(opts)
    }

    static var isAccessibilityGranted: Bool { AXIsProcessTrusted() }

    // MARK: - Key Press

    func keyPress(keyCode: UInt16, modifiers: UInt64, down: Bool) {
        guard let event = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: down) else { return }
        event.flags = CGEventFlags(rawValue: modifiers)
        event.post(tap: .cgAnnotatedSessionEventTap)
    }

    func keyTap(mapping: KeyMapping) {
        guard mapping.keyCode != 65535 else { return }
        keyPress(keyCode: mapping.keyCode, modifiers: mapping.modifiers, down: true)
        keyPress(keyCode: mapping.keyCode, modifiers: mapping.modifiers, down: false)
    }

    // MARK: - Mouse Click

    func mouseClick(button: CGMouseButton, down: Bool) {
        let position = NSEvent.mouseLocation
        let cgPoint = CGPoint(x: position.x,
                              y: NSScreen.main!.frame.height - position.y)

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
        Task { @MainActor [weak self] in
            for step in steps {
                if step.keyMapping.keyCode != 65535 {
                    self?.keyPress(keyCode: step.keyMapping.keyCode,
                                   modifiers: step.keyMapping.modifiers,
                                   down: step.keyDown)
                }
                if step.delayAfterMs > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(step.delayAfterMs) * 1_000_000)
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
