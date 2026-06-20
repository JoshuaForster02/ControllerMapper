import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 18) {
            Group {
                if let icon = NSImage(named: NSImage.applicationIconName) {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 84, height: 84)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 84, height: 84)
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(.white)
                    }
                }
            }
            .shadow(color: Color.accentColor.opacity(0.4), radius: 12, y: 6)
            .padding(.top, 8)

            VStack(spacing: 4) {
                Text("ControllerMapper")
                    .font(.title2.bold())
                Text("Version \(appVersion) (\(buildNumber))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Mappt Xbox-kompatible Controller (z. B. ShanWan-Klone) auf Tastatur, Maus und Macros — mit mehreren Profilen und Akku-Anzeige.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)

            Divider()

            permissionsSection

            Button {
                if let url = URL(string: "https://www.buymeacoffee.com/joshuaforster") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Label("Entwickler unterstützen", systemImage: "cup.and.saucer.fill")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.bordered)
            .tint(.orange)

            Spacer(minLength: 0)

            HStack {
                Link("GitHub", destination: URL(string: "https://github.com/joshuaforster/ControllerMapper")!)
                    .font(.caption)
                Spacer()
                Button("Schließen") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(width: 360, height: 500)
    }

    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Berechtigungen")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            HStack {
                Image(systemName: EventInjector.isAccessibilityGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(EventInjector.isAccessibilityGranted ? .green : .orange)
                Text("Bedienungshilfen")
                    .font(.subheadline)
                Spacer()
                if !EventInjector.isAccessibilityGranted {
                    Button("Öffnen") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    AboutView()
}
