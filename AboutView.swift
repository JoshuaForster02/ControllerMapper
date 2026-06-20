import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var iconTapCount = 0
    @State private var showHiddenBadge = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: DS.spacingL) {
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
            .rotationEffect(.degrees(showHiddenBadge ? 360 : 0))
            .animation(.easeOut(duration: 0.6), value: showHiddenBadge)
            .contentShape(Circle())
            .onTapGesture { registerIconTap() }

            VStack(spacing: 4) {
                Text("ControllerMapper")
                    .font(.title2.bold())
                Text("Version \(appVersion) (\(buildNumber))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if showHiddenBadge {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)
                    Text("Hidden badge unlocked — thanks for clicking around!")
                        .font(.caption2.weight(.medium))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.yellow.opacity(0.15)))
                .transition(.scale.combined(with: .opacity))
            } else {
                Text("Maps Xbox-compatible controllers (incl. ShanWan clones) to keyboard, mouse, and macros — with multiple profiles and a live battery indicator.")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
            }

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
        .sheetContainer(width: 360)
        .frame(height: 500)
    }

    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: DS.spacingS) {
            Text("Berechtigungen").sectionEyebrow()

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
            .padding(DS.spacingS)
            .cardSurface(radius: DS.radiusSmall)
        }
        .frame(maxWidth: .infinity)
    }

    private func registerIconTap() {
        iconTapCount += 1
        if iconTapCount >= 7 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showHiddenBadge = true
            }
        }
    }
}

#Preview {
    AboutView()
}
