import SwiftUI
import UniformTypeIdentifiers

struct MainWindowView: View {
    @ObservedObject private var controller = ControllerManager.shared
    @ObservedObject private var profiles   = ProfileManager.shared

    @State private var selectedProfileID: UUID?
    @State private var selectedButton: ControllerButton?
    @State private var showNewProfileSheet = false
    @State private var isImporting = false
    @State private var isExporting = false
    @State private var showBluetoothPicker = false
    @State private var showAbout = false
    @State private var searchText = ""

    private var activeProfile: Binding<Profile> {
        Binding(
            get: {
                guard let id = selectedProfileID,
                      let idx = profiles.profiles.firstIndex(where: { $0.id == id }) else {
                    return Profile.default
                }
                return profiles.profiles[idx]
            },
            set: { newValue in
                if let idx = profiles.profiles.firstIndex(where: { $0.id == newValue.id }) {
                    profiles.profiles[idx] = newValue
                }
            }
        )
    }

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            profileSidebar
        } detail: {
            if let id = selectedProfileID,
               let profile = profiles.profiles.first(where: { $0.id == id }) {
                mainContent(profile: profile)
            } else {
                Text("Select a profile")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("ControllerMapper")
        .toolbar { toolbarContent }
        .onAppear {
            if selectedProfileID == nil {
                selectedProfileID = profiles.activeProfileID ?? profiles.profiles.first?.id
            }
        }
        .sheet(isPresented: $showNewProfileSheet) {
            NewProfileSheet { profile in
                profiles.addProfile(profile)
                selectedProfileID = profile.id
            }
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.init(filenameExtension: "cmprofile")!]) { result in
            if case .success(let url) = result {
                try? profiles.importProfile(from: url)
            }
        }
        .sheet(isPresented: $showBluetoothPicker) {
            BluetoothDevicePickerView()
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
    }

    // MARK: - Sidebar

    private var profileSidebar: some View {
        List(selection: $selectedProfileID) {
            Section("Profiles") {
                ForEach(profiles.profiles) { profile in
                    profileRow(profile)
                        .tag(profile.id)
                }
                .onDelete { indices in
                    indices.forEach { profiles.delete(profiles.profiles[$0]) }
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button {
                    showNewProfileSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)

                Button {
                    isImporting = true
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.bar)
        }
    }

    private func profileRow(_ profile: Profile) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(profile.swiftUIColor)
                .frame(width: 8, height: 8)

            Image(systemName: profile.icon)
                .font(.footnote)
                .foregroundStyle(profile.swiftUIColor)
                .frame(width: 16)

            Text(profile.name)
                .lineLimit(1)

            Spacer()

            if profiles.activeProfileID == profile.id {
                Image(systemName: "bolt.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button("Activate") { profiles.activate(profile) }
            Button("Duplicate") { profiles.duplicate(profile) }
            Divider()
            Button("Export…") {
                if let url = profiles.exportProfile(profile) {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
            }
            Divider()
            Button("Delete", role: .destructive) { profiles.delete(profile) }
        }
    }

    // MARK: - Main Content

    private func mainContent(profile: Profile) -> some View {
        HSplitView {
            // Left: Controller layout + mappings list
            VStack(spacing: 0) {
                controllerSection(profile: profile)
                Divider()
                buttonList(profile: profile)
            }
            .frame(minWidth: 420)

            // Right: Mapping detail
            Group {
                if let btn = selectedButton {
                    MappingDetailView(
                        button: btn,
                        profile: activeProfile,
                        profileID: profile.id
                    )
                    .frame(minWidth: 300, maxWidth: 380)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.quaternary)
                        Text("Tap a button on the controller")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .frame(minWidth: 300, maxWidth: 380)
                }
            }
        }
    }

    private func controllerSection(profile: Profile) -> some View {
        VStack(spacing: 0) {
            // Profile header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(profile.swiftUIColor.opacity(0.16))
                        .frame(width: 36, height: 36)
                    Image(systemName: profile.icon)
                        .foregroundStyle(profile.swiftUIColor)
                        .font(.headline)
                }

                Text(profile.name)
                    .font(.title3.bold())

                if profiles.activeProfileID == profile.id {
                    Label("Aktiv", systemImage: "bolt.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(profile.swiftUIColor.gradient))
                } else {
                    Button("Aktivieren") {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            profiles.activate(profile)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Spacer()

                // Battery
                if controller.isConnected {
                    if controller.supportsBattery {
                        HStack(spacing: 8) {
                            BatteryRingView(
                                percent: controller.batteryPercent,
                                isCharging: controller.isCharging,
                                color: controller.batteryColor,
                                size: 30
                            )
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "battery.0")
                                .foregroundStyle(.tertiary)
                            Text("Akku nicht meldbar")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Button("Einrichten") { showBluetoothPicker = true }
                                .buttonStyle(.link)
                                .font(.caption2)
                        }
                    }
                }

                // Connection status
                HStack(spacing: 5) {
                    Circle()
                        .fill(controller.isConnected ? Color.green : Color.secondary)
                        .frame(width: 6, height: 6)
                        .shadow(color: controller.isConnected ? .green.opacity(0.6) : .clear, radius: 3)
                    Text(controller.isConnected ? controller.controllerName : "Nicht verbunden")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.thinMaterial)

            Divider()

            // Controller visual with ambient profile-color glow
            ZStack {
                RadialGradient(
                    colors: [profile.swiftUIColor.opacity(0.22), .clear],
                    center: .center, startRadius: 10, endRadius: 240
                )
                ControllerLayoutView(
                    selectedButton: $selectedButton,
                    profile: profile
                )
                .padding(20)
            }
            .frame(height: 240)
            .animation(.easeInOut(duration: 0.4), value: profile.id)
        }
    }

    private var filteredButtons: [ControllerButton] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return ControllerButton.allCases }
        return ControllerButton.allCases.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func buttonList(profile: Profile) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Button suchen…", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 7).fill(Color(.quaternarySystemFill)))
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)

            List(filteredButtons, id: \.self, selection: $selectedButton) { btn in
                HStack(spacing: 10) {
                    Image(systemName: btn.sfSymbol)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(width: 20)

                    Text(btn.displayName)
                        .font(.subheadline)

                    Spacer()

                    if let action = profile.mappings[btn], action.type != .none {
                        actionBadge(action)
                    } else {
                        Text("—")
                            .font(.caption)
                            .foregroundStyle(.quaternary)
                    }
                }
                .padding(.vertical, 2)
                .tag(btn)
            }
            .listStyle(.plain)
        }
    }

    private func actionBadge(_ action: ButtonAction) -> some View {
        HStack(spacing: 4) {
            Image(systemName: action.type.sfSymbol)
                .font(.caption2)
            Text(badgeLabel(action))
                .font(.caption)
                .lineLimit(1)
        }
        .foregroundStyle(Color.accentColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Capsule().fill(Color.accentColor.opacity(0.12)))
    }

    private func badgeLabel(_ action: ButtonAction) -> String {
        switch action.type {
        case .none: return ""
        case .keyPress: return action.keyMapping.displayName
        case .macro: return "\(action.macroSteps.count) steps"
        case .openApp: return action.appName.isEmpty ? "App" : action.appName
        default: return action.type.rawValue
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button {
                showNewProfileSheet = true
            } label: {
                Label("New Profile", systemImage: "plus")
            }

            Button {
                showAbout = true
            } label: {
                Label("Über ControllerMapper", systemImage: "info.circle")
            }
        }

        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                showBluetoothPicker = true
            } label: {
                Label("Bluetooth-Akku", systemImage: "battery.100.bolt")
            }
            .help("Akku-Quelle für Controller ohne Akku-Meldung einrichten")

            if let id = selectedProfileID,
               let profile = profiles.profiles.first(where: { $0.id == id }) {
                Button {
                    if let url = profiles.exportProfile(profile) {
                        NSSavePanel().runModal()
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
        }
    }
}

// MARK: - New Profile Sheet

struct NewProfileSheet: View {
    var onCreate: (Profile) -> Void

    @State private var name: String = "New Profile"
    @State private var colorHex: String = "#007AFF"
    @State private var icon: String = "gamecontroller.fill"
    @Environment(\.dismiss) private var dismiss

    let icons = ["gamecontroller.fill", "bolt.fill", "star.fill", "flame.fill",
                 "scope", "desktopcomputer", "film.fill", "music.note", "paintbrush.fill", "terminal.fill"]
    let colors = ["#007AFF", "#34C759", "#FF3B30", "#FF9500", "#AF52DE", "#5AC8FA", "#FFD60A", "#FF2D55"]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("New Profile")
                .font(.title2.bold())

            TextField("Profile name", text: $name)
                .textFieldStyle(.roundedBorder)

            VStack(alignment: .leading, spacing: 8) {
                Text("Color").font(.subheadline)
                HStack {
                    ForEach(colors, id: \.self) { hex in
                        Button {
                            colorHex = hex
                        } label: {
                            Circle()
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle().stroke(.white, lineWidth: colorHex == hex ? 2 : 0)
                                        .shadow(radius: colorHex == hex ? 2 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Icon").font(.subheadline)
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(36)), count: 5), spacing: 8) {
                    ForEach(icons, id: \.self) { sf in
                        Button {
                            icon = sf
                        } label: {
                            Image(systemName: sf)
                                .font(.body)
                                .frame(width: 32, height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(icon == sf ? Color.accentColor.opacity(0.2) : Color(.quaternarySystemFill))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(icon == sf ? Color.accentColor : Color.clear, lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack {
                Button("Cancel", role: .cancel) { dismiss() }
                Spacer()
                Button("Create") {
                    let p = Profile(name: name, colorHex: colorHex, icon: icon)
                    onCreate(p)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 320)
    }
}
