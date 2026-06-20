import SwiftUI
import GameController

struct MenuBarView: View {
    @ObservedObject private var controller = ControllerManager.shared
    @ObservedObject private var profiles   = ProfileManager.shared
    @ObservedObject private var engine     = MappingEngine.shared
    @Environment(\.openWindow) private var openWindow

    @State private var showEasterEgg = false
    @State private var toastText: String?

    private var activeColor: Color {
        profiles.activeProfile?.swiftUIColor ?? .accentColor
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            profilePicker
            footer
        }
        .frame(width: 300)
        .background {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                AmbientBackground(colors: [activeColor, controller.isConnected ? .green : .gray])
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .overlay {
            if showEasterEgg {
                ConfettiOverlay()
                    .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .top) {
            if let text = toastText {
                Text(text)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.75), in: Capsule())
                    .foregroundStyle(.white)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .controllerMapperEasterEgg)) { _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { showEasterEgg = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                withAnimation(.easeOut(duration: 0.5)) { showEasterEgg = false }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .controllerMapperProfileSwitched)) { note in
            guard let profile = note.object as? Profile else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                toastText = "🎮 Switched to \(profile.name)"
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation { toastText = nil }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: controller.isConnected
                                    ? [.green, .green.opacity(0.5)]
                                    : [.secondary.opacity(0.4), .secondary.opacity(0.15)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: controller.isConnected ? .green.opacity(0.4) : .clear, radius: 8)
                    Image(systemName: "gamecontroller.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(controller.isConnected ? controller.controllerName : "Kein Controller")
                        .font(.headline)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Circle()
                            .fill(controller.isConnected ? Color.green : Color.secondary)
                            .frame(width: 6, height: 6)
                        Text(controller.isConnected ? "Verbunden" : "Suche läuft…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if controller.isConnected && controller.supportsBattery {
                    BatteryRingView(
                        percent: controller.batteryPercent,
                        isCharging: controller.isCharging,
                        color: controller.batteryColor,
                        size: 40
                    )
                } else if controller.isConnected {
                    VStack(spacing: 2) {
                        Image(systemName: "battery.0")
                            .foregroundStyle(.tertiary)
                        Text("kein Akku")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    // MARK: - Profile Picker

    private var profilePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PROFILE")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(1)
                .padding(.horizontal, 18)
                .padding(.bottom, 2)

            VStack(spacing: 3) {
                ForEach(profiles.profiles) { profile in
                    profileRow(profile)
                }
            }
            .padding(.horizontal, 10)

            Button {
                openMainWindow()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.caption)
                    Text("Profile verwalten")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 18)
            .padding(.top, 6)
            .padding(.bottom, 14)
        }
        .padding(.top, 4)
    }

    private func profileRow(_ profile: Profile) -> some View {
        let isActive = profiles.activeProfileID == profile.id
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                profiles.activate(profile)
            }
        } label: {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(profile.swiftUIColor)
                    .frame(width: 4, height: 22)

                Image(systemName: profile.icon)
                    .font(.caption)
                    .foregroundStyle(profile.swiftUIColor)
                    .frame(width: 18)

                Text(profile.name)
                    .font(.subheadline.weight(isActive ? .semibold : .regular))
                    .foregroundStyle(.primary)

                Spacer()

                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(profile.swiftUIColor)
                }
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(isActive ? profile.swiftUIColor.opacity(0.14) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.5)

            VStack(spacing: 10) {
                Toggle(isOn: $engine.isEnabled.animation(.spring(response: 0.3, dampingFraction: 0.8))) {
                    HStack(spacing: 8) {
                        Image(systemName: engine.isEnabled ? "bolt.fill" : "bolt.slash.fill")
                            .foregroundStyle(engine.isEnabled ? .yellow : .secondary)
                            .font(.caption)
                        Text(engine.isEnabled ? "Mapping aktiv" : "Mapping pausiert")
                            .font(.subheadline)
                            .foregroundStyle(engine.isEnabled ? .primary : .secondary)
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.small)

                HStack {
                    Button {
                        openMainWindow()
                    } label: {
                        Label("Open Mapper", systemImage: "slider.horizontal.3")
                            .font(.subheadline.weight(.medium))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)

                    Spacer()

                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Image(systemName: "power")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Open Main Window

    private func openMainWindow() {
        openWindow(id: "main-window")
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Menu Bar Label (Icon)

struct MenuBarLabel: View {
    @ObservedObject private var controller = ControllerManager.shared
    @ObservedObject private var engine     = MappingEngine.shared

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: engine.isEnabled ? "gamecontroller.fill" : "gamecontroller")
                .opacity(engine.isEnabled ? 1 : 0.5)
            if controller.isConnected && controller.supportsBattery {
                Image(systemName: controller.batteryIcon)
                    .foregroundStyle(controller.batteryColor)
            }
        }
        .symbolRenderingMode(.hierarchical)
    }
}
