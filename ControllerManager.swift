import Foundation
import GameController
import Combine
import SwiftUI

final class ControllerManager: ObservableObject {
    static let shared = ControllerManager()

    @Published var isConnected: Bool = false
    @Published var controllerName: String = "No Controller"
    @Published var productCategory: String = ""
    @Published var supportsBattery: Bool = false
    @Published var batteryPercent: Int = 0
    @Published var isCharging: Bool = false

    /// Buttons currently held down — purely visual, drives the live glow
    /// on the controller diagram regardless of what's mapped/selected.
    @Published var pressedButtons: Set<ControllerButton> = []

    /// User-selected paired Bluetooth device used as a battery fallback for
    /// controllers that don't expose battery through GCController at all.
    @Published var bluetoothDeviceAddress: String? {
        didSet {
            UserDefaults.standard.set(bluetoothDeviceAddress, forKey: "cm_bt_device_address")
            if let c = currentController { updateBattery(c) }
        }
    }
    private weak var currentController: GCController?

    // Raw axis values (−1 … 1)
    var leftStick:  CGPoint = .zero
    var rightStick: CGPoint = .zero
    var leftTrigger:  Float = 0
    var rightTrigger: Float = 0

    // Per-button pressed callbacks: [button -> (isPressed) -> Void]
    var buttonCallbacks: [ControllerButton: (Bool) -> Void] = [:]
    // Per-axis callbacks:  [button -> (value: −1…1) -> Void]
    var axisCallbacks:   [ControllerButton: (Float) -> Void] = [:]

    private var batteryTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Without this, macOS only delivers controller input to whichever
        // app is currently frontmost/key. Since this app spends almost all
        // its life as a backgrounded menu bar accessory (no window open),
        // mapping would silently stop working the moment the window closes.
        GCController.shouldMonitorBackgroundEvents = true

        self.bluetoothDeviceAddress = UserDefaults.standard.string(forKey: "cm_bt_device_address")
        if let raw = UserDefaults.standard.string(forKey: "cm_manual_style") {
            self.manualVisualStyle = ControllerVisualStyle(rawValue: raw)
        } else {
            self.manualVisualStyle = nil
        }
        setupNotifications()
        // Try to connect to already-connected controllers
        if let controller = GCController.controllers().first {
            connect(controller)
        }
    }

    // MARK: - Notifications

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerConnected(_:)),
            name: .GCControllerDidConnect,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDisconnected(_:)),
            name: .GCControllerDidDisconnect,
            object: nil
        )
        GCController.startWirelessControllerDiscovery {}
    }

    @objc private func controllerConnected(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        DispatchQueue.main.async { self.connect(controller) }
    }

    @objc private func controllerDisconnected(_ notification: Notification) {
        DispatchQueue.main.async {
            self.isConnected = false
            self.controllerName = "No Controller"
            self.productCategory = ""
            self.supportsBattery = false
            self.batteryPercent = 0
            self.isCharging = false
            self.batteryTimer?.invalidate()
            // Clear live-press state so buttons don't appear stuck glowing after disconnect.
            self.pressedButtons = []
            self.leftStick  = .zero
            self.rightStick = .zero
        }
    }

    // MARK: - Connect

    private func connect(_ controller: GCController) {
        isConnected = true
        controllerName = controller.vendorName ?? "Xbox Controller"
        productCategory = controller.productCategory
        currentController = controller
        setupBattery(controller)
        setupGamepad(controller)
    }

    private func setupBattery(_ controller: GCController) {
        // Initial read
        updateBattery(controller)
        // Poll every 30 s (GCDeviceBattery doesn't have callbacks on all macOS versions)
        batteryTimer?.invalidate()
        batteryTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self, weak controller] _ in
            guard let c = controller else { return }
            self?.updateBattery(c)
        }
    }

    private func updateBattery(_ controller: GCController) {
        DispatchQueue.main.async {
            // 1. Native GameController battery (works for genuine MFi/Xbox/PS controllers)
            if let battery = controller.battery {
                self.supportsBattery = true
                self.batteryPercent = Int((battery.batteryLevel * 100).rounded())
                self.isCharging = battery.batteryState == .charging
                return
            }

            // 2. Fallback: user-selected paired Bluetooth device.
            // Many third-party "Xbox-compatible" controllers (e.g. ShanWan clones)
            // don't implement the HID battery feature report GCController reads,
            // but macOS's own Bluetooth stack often still knows the battery level.
            if let address = self.bluetoothDeviceAddress,
               let percent = BluetoothBatteryReader.batteryPercent(forAddress: address) {
                self.supportsBattery = true
                self.batteryPercent = percent
                self.isCharging = false
                return
            }

            self.supportsBattery = false
            self.batteryPercent = 0
            self.isCharging = false
        }
    }

    // MARK: - Gamepad Input

    private func setupGamepad(_ controller: GCController) {
        guard let gp = controller.extendedGamepad else { return }

        // Helper to fire button callback
        let btn: (ControllerButton) -> GCControllerButtonInput? = { [gp] button in
            switch button {
            case .a:    return gp.buttonA
            case .b:    return gp.buttonB
            case .x:    return gp.buttonX
            case .y:    return gp.buttonY
            case .lb:   return gp.leftShoulder
            case .rb:   return gp.rightShoulder
            case .l3:   return gp.leftThumbstickButton
            case .r3:   return gp.rightThumbstickButton
            case .dUp:  return gp.dpad.up
            case .dDown: return gp.dpad.down
            case .dLeft: return gp.dpad.left
            case .dRight: return gp.dpad.right
            case .menu: return gp.buttonMenu
            case .view: return gp.buttonOptions
            case .home: return gp.buttonHome
            default:    return nil
            }
        }

        // Wire up all digital buttons
        for button in ControllerButton.allCases where !button.isAxis {
            guard let input = btn(button) else { continue }
            input.pressedChangedHandler = { [weak self] _, _, pressed in
                self?.setPressed(button, pressed)
                self?.buttonCallbacks[button]?(pressed)
            }
        }

        // Triggers (analog → digital at 0.5 threshold, plus raw axis)
        gp.leftTrigger.valueChangedHandler = { [weak self] _, value, _ in
            let pressed = value > 0.5
            let wasPressed = (self?.leftTrigger ?? 0) > 0.5
            self?.leftTrigger = value
            self?.axisCallbacks[.lt]?(value)
            if pressed != wasPressed {
                self?.setPressed(.lt, pressed)
                self?.buttonCallbacks[.lt]?(pressed)
            }
        }
        gp.rightTrigger.valueChangedHandler = { [weak self] _, value, _ in
            let pressed = value > 0.5
            let wasPressed = (self?.rightTrigger ?? 0) > 0.5
            self?.rightTrigger = value
            self?.axisCallbacks[.rt]?(value)
            if pressed != wasPressed {
                self?.setPressed(.rt, pressed)
                self?.buttonCallbacks[.rt]?(pressed)
            }
        }

        // Sticks
        gp.leftThumbstick.valueChangedHandler = { [weak self] _, x, y in
            self?.leftStick = CGPoint(x: CGFloat(x), y: CGFloat(y))
            self?.axisCallbacks[.leftStickX]?(x)
            self?.axisCallbacks[.leftStickY]?(y)
        }
        gp.rightThumbstick.valueChangedHandler = { [weak self] _, x, y in
            self?.rightStick = CGPoint(x: CGFloat(x), y: CGFloat(y))
            self?.axisCallbacks[.rightStickX]?(x)
            self?.axisCallbacks[.rightStickY]?(y)
        }
    }

    // MARK: - Live Press State (visual only)

    private func setPressed(_ button: ControllerButton, _ pressed: Bool) {
        DispatchQueue.main.async {
            if pressed {
                self.pressedButtons.insert(button)
            } else {
                self.pressedButtons.remove(button)
            }
        }
    }

    /// Manual override for the diamond's look — lets you pick a style
    /// yourself when auto-detection guesses wrong (common for unbranded
    /// clones) or you simply prefer a different symbol set. `nil` = auto.
    @Published var manualVisualStyle: ControllerVisualStyle? {
        didSet { UserDefaults.standard.set(manualVisualStyle?.rawValue, forKey: "cm_manual_style") }
    }

    /// Visual style (Xbox/PlayStation/generic) derived from the connected
    /// controller's reported product category, unless manually overridden.
    var visualStyle: ControllerVisualStyle {
        manualVisualStyle ?? ControllerVisualStyle.detect(productCategory: productCategory)
    }

    // MARK: - Battery Display Helpers

    var batteryIcon: String {
        if isCharging { return "battery.100.bolt" }
        switch batteryPercent {
        case 76...: return "battery.100"
        case 51...: return "battery.75"
        case 26...: return "battery.50"
        case 11...: return "battery.25"
        default:    return "battery.0"
        }
    }

    var batteryColor: Color {
        switch batteryPercent {
        case 21...: return .green
        case 11...: return .yellow
        default:    return .red
        }
    }
}
