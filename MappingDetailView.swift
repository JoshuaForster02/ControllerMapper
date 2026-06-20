import SwiftUI
import UniformTypeIdentifiers

/// Panel shown on the right side when a controller button is selected.
struct MappingDetailView: View {
    let button: ControllerButton
    @Binding var profile: Profile
    let profileID: UUID

    @State private var action: ButtonAction = .none
    @State private var isCapturingKey = false

    @ObservedObject private var profiles = ProfileManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.spacingL) {
                buttonHeader
                actionTypePicker
                actionDetail
                    .animation(.easeInOut(duration: 0.18), value: action.type)
                Spacer()
            }
            .padding(DS.spacingL)
        }
        .onAppear { action = profile.mappings[button] ?? .none }
        .onChange(of: button) { _, newButton in
            withAnimation(.easeInOut(duration: 0.15)) {
                action = profile.mappings[newButton] ?? .none
            }
        }
        .onChange(of: action) { saveAction($1) }
    }

    // MARK: - Header

    private var buttonHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: button.sfSymbol)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(button.displayName)
                    .font(.title3.bold())
                Text(button.isAxis ? "Analog axis" : "Digital button")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if action.type != .none {
                Button("Testen") { testAction() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(action.type == .mouseMoveAxis)

                Button("Clear") {
                    action = .none
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    private func testAction() {
        let injector = EventInjector.shared
        switch action.type {
        case .none, .mouseMoveAxis: break
        case .keyPress:    injector.keyTap(mapping: action.keyMapping)
        case .leftClick:   injector.mouseClick(button: .left)
        case .rightClick:  injector.mouseClick(button: .right)
        case .middleClick: injector.mouseClick(button: .center)
        case .scrollUp:    injector.scroll(dx: 0, dy: action.scrollAmount)
        case .scrollDown:  injector.scroll(dx: 0, dy: -action.scrollAmount)
        case .scrollLeft:  injector.scroll(dx: -action.scrollAmount, dy: 0)
        case .scrollRight: injector.scroll(dx: action.scrollAmount, dy: 0)
        case .macro:       injector.executeMacro(action.macroSteps)
        case .openApp:     injector.openApp(bundleID: action.appBundleID)
        }
    }

    // MARK: - Action Type Picker

    private var actionTypePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Action")
                .font(.headline)

            let types: [ActionType] = button.isAxis
                ? [.none, .mouseMoveAxis, .scrollUp, .scrollDown, .scrollLeft, .scrollRight]
                : ActionType.allCases.filter { !$0.isAxisCompatible || $0 == .none }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                ForEach(types, id: \.self) { type in
                    actionTypeCell(type)
                }
            }
        }
    }

    private func actionTypeCell(_ type: ActionType) -> some View {
        Button {
            var updated = action
            updated.type = type
            action = updated
        } label: {
            HStack(spacing: 6) {
                Image(systemName: type.sfSymbol)
                    .font(.caption)
                Text(type.rawValue)
                    .font(.caption)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(action.type == type
                          ? Color.accentColor.opacity(0.2)
                          : Color(.quaternarySystemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(action.type == type ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
            .foregroundStyle(action.type == type ? Color.accentColor : .primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Action Detail

    @ViewBuilder
    private var actionDetail: some View {
        switch action.type {
        case .none: EmptyView()
        case .keyPress: keyPressPicker
        case .leftClick, .rightClick, .middleClick: mouseClickDetail
        case .scrollUp, .scrollDown, .scrollLeft, .scrollRight: scrollDetail
        case .mouseMoveAxis: mouseMoveDetail
        case .macro: macroEditor
        case .openApp: appPicker
        }
    }

    // MARK: - Key Press Picker

    private var keyPressPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
            Text("Key")
                .font(.headline)

            // Current assignment
            HStack {
                Text(action.keyMapping == .none ? "No key assigned" : action.keyMapping.displayName)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.quaternarySystemFill)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor.opacity(0.4), lineWidth: 1)
                    )

                Spacer()

                Button(isCapturingKey ? "Press a key…" : "Capture Key") {
                    isCapturingKey.toggle()
                }
                .buttonStyle(.bordered)
                .overlay(keyCapture)
            }

            // Preset grid
            Text("PRESETS").sectionEyebrow()

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72))], spacing: 6) {
                ForEach(KeyMapping.presets, id: \.displayName) { km in
                    Button {
                        var a = action; a.keyMapping = km; action = a
                    } label: {
                        Text(km.displayName)
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(action.keyMapping == km
                                          ? Color.accentColor.opacity(0.2)
                                          : Color(.quaternarySystemFill))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(action.keyMapping == km ? Color.accentColor : Color.clear, lineWidth: 1)
                            )
                            .foregroundStyle(action.keyMapping == km ? Color.accentColor : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // Invisible view that captures next key event
    private var keyCapture: some View {
        Group {
            if isCapturingKey {
                KeyCaptureView { keyCode, modifiers, name in
                    var a = action
                    a.keyMapping = KeyMapping(keyCode: keyCode, modifiers: modifiers, displayName: name)
                    action = a
                    isCapturingKey = false
                }
                .frame(width: 0, height: 0)
            }
        }
    }

    // MARK: - Mouse Click

    private var mouseClickDetail: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            Label("Click will fire at current cursor position", systemImage: "cursorarrow")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Scroll

    private var scrollDetail: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
            Text("Scroll Amount (pixels per press)")
                .font(.headline)
            HStack {
                Slider(value: Binding(
                    get: { Double(action.scrollAmount) },
                    set: { var a = action; a.scrollAmount = Int($0); action = a }
                ), in: 1...100, step: 1)
                Text("\(action.scrollAmount)px")
                    .font(.caption.monospacedDigit())
                    .frame(width: 40)
            }
        }
    }

    // MARK: - Mouse Move Axis

    private var mouseMoveDetail: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            Text("Mouse Move Settings")
                .font(.headline)

            HStack {
                Text("Sensitivity")
                Spacer()
                Text(String(format: "%.1f", action.mouseSensitivity))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: Binding(
                get: { action.mouseSensitivity },
                set: { var a = action; a.mouseSensitivity = $0; action = a }
            ), in: 1...30, step: 0.5)

            Toggle("Invert axis", isOn: Binding(
                get: { action.mouseInverted },
                set: { var a = action; a.mouseInverted = $0; action = a }
            ))
        }
    }

    // MARK: - Macro Editor

    private var macroEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
            HStack {
                Text("Macro Steps")
                    .font(.headline)
                Spacer()
                Button {
                    var a = action
                    a.macroSteps.append(MacroStep())
                    action = a
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if action.macroSteps.isEmpty {
                Text("No steps yet — tap + to add a key event")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(action.macroSteps.indices, id: \.self) { i in
                    macroStepRow(index: i)
                }
            }
        }
    }

    private func macroStepRow(index: Int) -> some View {
        HStack(spacing: 8) {
            Text("\(index + 1)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Picker("", selection: Binding(
                get: { action.macroSteps[index].keyDown },
                set: { var a = action; a.macroSteps[index].keyDown = $0; action = a }
            )) {
                Text("↓ Down").tag(true)
                Text("↑ Up").tag(false)
            }
            .pickerStyle(.segmented)
            .frame(width: 110)

            Menu(action.macroSteps[index].keyMapping.displayName) {
                ForEach(KeyMapping.presets, id: \.displayName) { km in
                    Button(km.displayName) {
                        var a = action; a.macroSteps[index].keyMapping = km; action = a
                    }
                }
            }
            .frame(width: 80)

            Stepper(
                "\(action.macroSteps[index].delayAfterMs)ms",
                value: Binding(
                    get: { action.macroSteps[index].delayAfterMs },
                    set: { var a = action; a.macroSteps[index].delayAfterMs = $0; action = a }
                ),
                in: 0...2000, step: 10
            )
            .font(.caption)

            Button {
                var a = action; a.macroSteps.remove(at: index); action = a
            } label: {
                Image(systemName: "trash").foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.quaternarySystemFill)))
    }

    // MARK: - App Picker

    private var appPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
            Text("Open App")
                .font(.headline)

            HStack {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(.secondary)
                Text(action.appName.isEmpty ? "No app selected" : action.appName)
                    .foregroundStyle(action.appName.isEmpty ? .secondary : .primary)
                Spacer()
                Button("Choose…") {
                    pickApp()
                }
                .buttonStyle(.bordered)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.quaternarySystemFill)))
        }
    }

    private func pickApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            let bundleID = Bundle(url: url)?.bundleIdentifier ?? ""
            let name = url.deletingPathExtension().lastPathComponent
            var a = action
            a.appBundleID = bundleID
            a.appName = name
            action = a
        }
    }

    // MARK: - Save

    private func saveAction(_ newAction: ButtonAction) {
        profiles.setAction(newAction, for: button, in: profileID)
        // Also update local binding
        profile.mappings[button] = newAction
    }
}

// MARK: - Key Capture View (NSTextField trick)

struct KeyCaptureView: NSViewRepresentable {
    var onCapture: (UInt16, UInt64, String) -> Void

    func makeNSView(context: Context) -> NSTextField {
        let field = KeyCaptureTextField()
        field.onCapture = onCapture
        field.isHidden = true
        DispatchQueue.main.async { field.window?.makeFirstResponder(field) }
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {}
}

final class KeyCaptureTextField: NSTextField {
    var onCapture: ((UInt16, UInt64, String) -> Void)?

    override func keyDown(with event: NSEvent) {
        let name = event.charactersIgnoringModifiers?.uppercased() ?? "Key \(event.keyCode)"
        var displayName = ""
        if event.modifierFlags.contains(.command)  { displayName += "⌘" }
        if event.modifierFlags.contains(.shift)    { displayName += "⇧" }
        if event.modifierFlags.contains(.option)   { displayName += "⌥" }
        if event.modifierFlags.contains(.control)  { displayName += "⌃" }
        displayName += name
        onCapture?(event.keyCode, UInt64(event.modifierFlags.rawValue), displayName)
    }
}
