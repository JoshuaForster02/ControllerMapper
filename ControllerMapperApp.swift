import SwiftUI
import ServiceManagement
import UserNotifications

@main
struct ControllerMapperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Menu bar popover
        MenuBarExtra {
            MenuBarView()
        } label: {
            MenuBarLabel()
        }
        .menuBarExtraStyle(.window)

        // Main settings window (opened via button in menu bar)
        Window("Controller Mapper", id: "main-window") {
            MainWindowView()
                .frame(minWidth: 780, minHeight: 520)
        }
        .defaultSize(width: 960, height: 620)
        .defaultPosition(.center)
    }
}

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {

    // Singletons — instantiate once so they're alive for the app lifetime
    private let controllerManager = ControllerManager.shared
    private let profileManager    = ProfileManager.shared
    private let mappingEngine     = MappingEngine.shared   // wires up callbacks

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request Accessibility permission for key/mouse injection
        EventInjector.requestAccessibilityIfNeeded()

        // Register as login item (macOS 13+)
        try? SMAppService.mainApp.register()

        // Request permission for the Konami-code easter egg notification.
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        NotificationCenter.default.addObserver(
            forName: .controllerMapperEasterEgg, object: nil, queue: .main
        ) { _ in
            let content = UNMutableNotificationContent()
            content.title = "🎮 Secret found!"
            content.body = "↑↑↓↓←←→→ B A — nice combo. Turbo mode... engaged? (not really, but still nice)"
            content.sound = .default
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false  // keep running as menu bar app
    }
}
