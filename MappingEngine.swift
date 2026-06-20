import Foundation
import CoreGraphics
import Combine

/// Bridges controller input → actions based on the active profile.
/// Owns the movement timer for analog stick mouse control.
final class MappingEngine: ObservableObject {
    static let shared = MappingEngine()

    private let controller = ControllerManager.shared
    private let injector   = EventInjector.shared
    private let profiles   = ProfileManager.shared

    private var movementTimer: Timer?

    /// Global kill switch — lets the user pause all key/mouse injection
    /// (e.g. while typing) without disconnecting the controller.
    @Published var isEnabled: Bool = true {
        didSet { UserDefaults.standard.set(isEnabled, forKey: "cm_mapping_enabled") }
    }

    private init() {
        isEnabled = UserDefaults.standard.object(forKey: "cm_mapping_enabled") as? Bool ?? true
        wireCallbacks()
        startMovementTimer()
    }

    // MARK: - Wire Controller Callbacks

    private func wireCallbacks() {
        // Digital buttons
        for button in ControllerButton.allCases where !button.isAxis {
            controller.buttonCallbacks[button] = { [weak self] pressed in
                self?.handleButton(button, pressed: pressed)
            }
        }
        // Axes handled in movement timer loop via raw stick values
    }

    // MARK: - Button Handler

    private func handleButton(_ button: ControllerButton, pressed: Bool) {
        guard isEnabled,
              let profile = profiles.activeProfile,
              let action = profile.mappings[button] else { return }

        // Only fire on press (keyDown), release for key-ups
        switch action.type {
        case .none: break

        case .keyPress:
            injector.keyPress(keyCode: action.keyMapping.keyCode,
                              modifiers: action.keyMapping.modifiers,
                              down: pressed)

        case .leftClick:
            injector.mouseClick(button: .left, down: pressed)

        case .rightClick:
            injector.mouseClick(button: .right, down: pressed)

        case .middleClick:
            injector.mouseClick(button: .center, down: pressed)

        case .scrollUp, .scrollDown, .scrollLeft, .scrollRight:
            guard pressed else { break }
            let amt = action.scrollAmount
            switch action.type {
            case .scrollUp:    injector.scroll(dx: 0,   dy: amt)
            case .scrollDown:  injector.scroll(dx: 0,   dy: -amt)
            case .scrollLeft:  injector.scroll(dx: -amt, dy: 0)
            case .scrollRight: injector.scroll(dx: amt,  dy: 0)
            default: break
            }

        case .macro:
            guard pressed else { break }
            injector.executeMacro(action.macroSteps)

        case .openApp:
            guard pressed else { break }
            injector.openApp(bundleID: action.appBundleID)

        case .mouseMoveAxis:
            break   // handled by movement timer
        }
    }

    // MARK: - Movement Timer (60 fps)

    private func startMovementTimer() {
        movementTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tickMovement()
        }
        RunLoop.main.add(movementTimer!, forMode: .common)
    }

    private func tickMovement() {
        guard isEnabled, let profile = profiles.activeProfile else { return }

        // Left stick
        applyAxisMouse(
            xValue: Float(controller.leftStick.x),
            yValue: Float(controller.leftStick.y),
            xButton: .leftStickX,
            yButton: .leftStickY,
            profile: profile
        )

        // Right stick
        applyAxisMouse(
            xValue: Float(controller.rightStick.x),
            yValue: Float(controller.rightStick.y),
            xButton: .rightStickX,
            yButton: .rightStickY,
            profile: profile
        )
    }

    private func applyAxisMouse(
        xValue: Float, yValue: Float,
        xButton: ControllerButton, yButton: ControllerButton,
        profile: Profile
    ) {
        let deadzone: Float = 0.12

        let xAction = profile.mappings[xButton]
        let yAction = profile.mappings[yButton]

        // Mouse move
        if xAction?.type == .mouseMoveAxis || yAction?.type == .mouseMoveAxis {
            let sensitivity = xAction?.mouseSensitivity ?? yAction?.mouseSensitivity ?? 10.0
            let rawX = abs(xValue) > deadzone ? xValue : 0
            let rawY = abs(yValue) > deadzone ? yValue : 0
            let dx = Double(rawX) * sensitivity
            let dy = Double(rawY) * sensitivity * (xAction?.mouseInverted == true ? -1 : 1)
            if dx != 0 || dy != 0 {
                injector.moveMouse(dx: dx, dy: dy)
            }
            return
        }

        // Scroll via axis
        let scrollThreshold: Float = 0.5
        if let xa = xAction {
            let amt = xa.scrollAmount
            if xValue > scrollThreshold  { injector.scroll(dx: amt,  dy: 0) }
            if xValue < -scrollThreshold { injector.scroll(dx: -amt, dy: 0) }
        }
        if let ya = yAction {
            let amt = ya.scrollAmount
            if yValue > scrollThreshold  { injector.scroll(dx: 0, dy: amt) }
            if yValue < -scrollThreshold { injector.scroll(dx: 0, dy: -amt) }
        }
    }
}
