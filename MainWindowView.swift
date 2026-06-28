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
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
        } detail: {
            if let id = selectedProfileID,
               let profile = profiles.profiles.first(where: { $0.id == id }) {
                mainContent(profile: profile)
            } else {
                Text("Profil auswählen")
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
        HStack(spacing: 9) {
            // Colored icon tile — compact, polished, like an iOS app icon
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(profile.swiftUIColor.opacity(0.18))
                    .frame(width: 28, height: 28)
                Image(systemName: profile.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(profile.swiftUIColor)
            }

            Text(profile.name)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            if profiles.activeProfileID == profile.id {
                Image(systemName: "bolt.fill")
                    .font(.caption2)
                    .foregroundStyle(profile.swiftUIColor)
                    .shadow(color: profile.swiftUIColor.opacity(0.5), radius: 3)
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button("Aktivieren") { profiles.activate(profile) }
            Button("Duplizieren") { profiles.duplicate(profile) }
            Divider()
            Button("Exportieren…") {
                if let url = profiles.exportProfile(profile) {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
            }
            Divider()
            Button("Löschen", role: .destructive) { profiles.delete(profile) }
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
                    .frame(minWidth: 320, idealWidth: 360, maxWidth: 460)
                    .transition(.opacity)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.quaternary)
                        Text("Button am Controller auswählen")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .frame(minWidth: 320, idealWidth: 360, maxWidth: 460)
                }
            }
            .animation(.easeInOut(duration: 0.18), value: selectedButton)
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

                // Design picker (auto-detected, but switchable)
                designPicker

                // Connection status
                HStack(spacing: 5) {
                    Circle()
                        .fill(controller.isConnected ? Color.green : Color.secondary)
                        .frame(width: 6, height: 6)
                        .shadow(color: controller.isConnected ? .green.opacity(0.6) : .clear, radius: 3)
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(controller.isConnected ? controller.controllerName : "Nicht verbunden")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if controller.isConnected && !controller.productCategory.isEmpty {
                            Text(controller.productCategory)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.thinMaterial)

            Divider()

            // Auto-switch row
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.swap")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                if !profile.autoSwitchBundleID.isEmpty,
                   let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: profile.autoSwitchBundleID) {
                    Text("Auto-Switch:")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text(appURL.deletingPathExtension().lastPathComponent)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Button {
                        profiles.setAutoSwitch(nil, for: profile.id)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Auto-Switch:")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Button("App wählen…") {
                        pickAutoSwitchApp(for: profile)
                    }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial)

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

    private func pickAutoSwitchApp(for profile: Profile) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Auswählen"
        panel.message = "Welche App soll dieses Profil automatisch aktivieren?"
        guard panel.runModal() == .OK, let url = panel.url,
              let bundleID = Bundle(url: url)?.bundleIdentifier else { return }
        profiles.setAutoSwitch(bundleID, for: profile.id)
    }

    private var designPicker: some View {
        Menu {
            Button {
                controller.manualVisualStyle = nil
            } label: {
                Label("Automatisch", systemImage: controller.manualVisualStyle == nil ? "checkmark" : "")
            }
            Divider()
            ForEach(ControllerVisualStyle.allCases, id: \.self) { style in
                Button {
                    controller.manualVisualStyle = style
                } label: {
                    Label(style.displayName, systemImage: controller.manualVisualStyle == style ? "checkmark" : "")
                }
            }
        } label: {
            Label(
                controller.manualVisualStyle == nil ? "Design: Auto" : "Design: \(controller.manualVisualStyle!.displayName)",
                systemImage: "paintpalette"
            )
            .font(.caption)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
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
                let mappedAction = profile.mappings[btn].flatMap { $0.type != .none ? $0 : nil }
                HStack(spacing: 10) {
                    Image(systemName: btn.sfSymbol)
                        .font(.footnote)
                        // Icon adopts action color when mapped — makes the list scannable at a glance
                        .foregroundStyle(mappedAction.map { badgeColor($0) } ?? Color.secondary)
                        .frame(width: 20)

                    Text(btn.displayName)
                        .font(.subheadline)

                    Spacer()

                    if let action = mappedAction {
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

    // Color-coded by action type — at a glance you can see what's mapped where
    private func badgeColor(_ action: ButtonAction) -> Color {
        switch action.type {
        case .keyPress:                                          return .blue
        case .leftClick, .rightClick, .middleClick:             return .purple
        case .scrollUp, .scrollDown, .scrollLeft, .scrollRight: return .teal
        case .macro:                                             return .orange
        case .openApp:                                          return .pink
        default:                                                return Color.accentColor
        }
    }

    private func actionBadge(_ action: ButtonAction) -> some View {
        let color = badgeColor(action)
        return HStack(spacing: 4) {
            Image(systemName: action.type.sfSymbol)
                .font(.caption2)
            Text(badgeLabel(action))
                .font(.caption)
                .lineLimit(1)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Capsule().fill(color.opacity(0.12)))
    }

    private func badgeLabel(_ action: ButtonAction) -> String {
        switch action.type {
        case .none: return ""
        case .keyPress: return action.keyMapping.displayName
        case .macro: return "\(action.macroSteps.count) Schritte"
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
                    // Encode first — bail early if that fails.
                    guard let data = try? JSONEncoder().encode(profile) else { return }
                    let panel = NSSavePanel()
                    panel.nameFieldStringValue = "\(profile.name).cmprofile"
                    panel.allowedContentTypes = [.init(filenameExtension: "cmprofile") ?? .data]
                    panel.canCreateDirectories = true
                    guard panel.runModal() == .OK, let dest = panel.url else { return }
                    try? data.write(to: dest)
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

    @State private var name: String = "Neues Profil"
    @State private var colorHex: String = "#007AFF"
    @State private var icon: String = "gamecontroller.fill"
    @State private var basePreset: Profile?
    @State private var customColor: Color = Color(hex: "#007AFF") ?? .blue
    @State private var useCustomColor = false
    @Environment(\.dismiss) private var dismiss

    let icons = ["gamecontroller.fill", "bolt.fill", "star.fill", "flame.fill",
                 "scope", "desktopcomputer", "film.fill", "music.note", "paintbrush.fill", "terminal.fill"]
    let colors = ["#007AFF", "#34C759", "#FF3B30", "#FF9500", "#AF52DE", "#5AC8FA", "#FFD60A", "#FF2D55"]

    var body: some View {
        VStack(alignment: .leading, spacing: DS.spacingL) {
            SheetHeader(title: "Neues Profil", systemImage: "plus.circle.fill")

            VStack(alignment: .leading, spacing: DS.spacingS) {
                Text("VORLAGE").sectionEyebrow()
                HStack(spacing: 8) {
                    presetChip(nil, label: "Leer", symbol: "doc")
                    ForEach(Profile.builtInPresets) { preset in
                        presetChip(preset, label: preset.name, symbol: preset.icon)
                    }
                }
            }

            TextField("Profilname", text: $name)
                .textFieldStyle(.roundedBorder)

            VStack(alignment: .leading, spacing: 8) {
                Text("FARBE").sectionEyebrow()
                HStack(spacing: 8) {
                    ForEach(colors, id: \.self) { hex in
                        Button {
                            colorHex = hex
                            useCustomColor = false
                        } label: {
                            Circle()
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle().stroke(.white, lineWidth: !useCustomColor && colorHex == hex ? 2 : 0)
                                        .shadow(radius: !useCustomColor && colorHex == hex ? 2 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    Divider().frame(height: 20)

                    // Free color pick
                    ColorPicker("", selection: $customColor, supportsOpacity: false)
                        .labelsHidden()
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(.white, lineWidth: useCustomColor ? 2 : 0)
                                .frame(width: 24, height: 24)
                                .allowsHitTesting(false)
                        )
                        .onChange(of: customColor) { _, c in
                            colorHex = c.hexString
                            useCustomColor = true
                        }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("SYMBOL").sectionEyebrow()
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
                Button("Abbrechen", role: .cancel) { dismiss() }
                Spacer()
                Button("Erstellen") {
                    var p = basePreset ?? Profile()
                    p.id = UUID()
                    p.name = name
                    p.colorHex = colorHex
                    p.icon = icon
                    onCreate(p)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .sheetContainer(width: DS.sheetWidthCompact)
    }

    private func presetChip(_ preset: Profile?, label: String, symbol: String) -> some View {
        let isSelected = basePreset?.id == preset?.id
        return Button {
            basePreset = preset
            name = preset?.name ?? "Neues Profil"
            colorHex = preset?.colorHex ?? "#007AFF"
            icon = preset?.icon ?? "gamecontroller.fill"
            useCustomColor = false
        } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.body)
                Text(label)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(width: 78, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.18) : Color(.quaternarySystemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
            .foregroundStyle(isSelected ? Color.accentColor : .primary)
        }
        .buttonStyle(.plain)
    }
}
