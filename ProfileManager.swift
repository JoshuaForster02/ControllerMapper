import Foundation
import SwiftUI
import Combine
import AppKit
import UniformTypeIdentifiers

final class ProfileManager: ObservableObject {
    static let shared = ProfileManager()

    @Published var profiles: [Profile] = []
    @Published var transferError: String?
    @Published var activeProfileID: UUID?

    private let storageKey  = "cm_profiles"
    private let activeKey   = "cm_active_profile"

    var activeProfile: Profile? {
        get { profiles.first { $0.id == activeProfileID } }
        set {
            if let p = newValue { activeProfileID = p.id }
        }
    }

    private init() {
        load()
        setupAutoSwitch()
        if profiles.isEmpty {
            let p = Profile.default
            profiles = [p]
            activeProfileID = p.id
            save()
        } else {
            // Restore last active
            if let raw = UserDefaults.standard.string(forKey: activeKey),
               let id = UUID(uuidString: raw),
               profiles.contains(where: { $0.id == id }) {
                activeProfileID = id
            } else {
                activeProfileID = profiles.first?.id
            }
        }
    }

    // MARK: - Auto-Switch (frontmost app → profile)

    private func setupAutoSwitch() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(frontmostAppChanged(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    @objc private func frontmostAppChanged(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleID = app.bundleIdentifier,
              !bundleID.isEmpty else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard let match = profiles.first(where: {
                !$0.autoSwitchBundleID.isEmpty && $0.autoSwitchBundleID == bundleID
            }) else { return }
            activate(match)
        }
    }

    func setAutoSwitch(_ bundleID: String?, for profileID: UUID) {
        guard let idx = profiles.firstIndex(where: { $0.id == profileID }) else { return }
        profiles[idx].autoSwitchBundleID = bundleID ?? ""
        save()
    }

    // MARK: - CRUD

    func addProfile(_ profile: Profile = Profile()) {
        profiles.append(profile)
        save()
    }

    func duplicate(_ profile: Profile) {
        var copy = profile
        copy.id   = UUID()
        copy.name = profile.name + " Copy"
        profiles.append(copy)
        save()
    }

    func delete(_ profile: Profile) {
        profiles.removeAll { $0.id == profile.id }
        if activeProfileID == profile.id {
            activeProfileID = profiles.first?.id
        }
        save()
    }

    func update(_ profile: Profile) {
        if let idx = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[idx] = profile
            save()
        }
    }

    func activate(_ profile: Profile) {
        activeProfileID = profile.id
        UserDefaults.standard.set(profile.id.uuidString, forKey: activeKey)
    }

    func setAction(_ action: ButtonAction, for button: ControllerButton, in profileID: UUID) {
        guard let idx = profiles.firstIndex(where: { $0.id == profileID }) else { return }
        profiles[idx].mappings[button] = action
        save()
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        if let id = activeProfileID {
            UserDefaults.standard.set(id.uuidString, forKey: activeKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Profile].self, from: data) else { return }
        profiles = decoded
    }

    // MARK: - Export / Import

    func exportProfile(_ profile: Profile) -> URL? {
        do {
            let valid = try ProfileFile.validate(profile)
            let panel = NSSavePanel()
            panel.allowedContentTypes = [UTType(importedAs: "com.joshuaforster.ctrl.profile", conformingTo: .json)]
            panel.nameFieldStringValue = ProfileFile.safeFilename(profile.name)
            guard panel.runModal() == .OK, let url = panel.url else { return nil }
            let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(valid).write(to: url, options: .atomic)
            return url
        } catch { transferError = error.localizedDescription; return nil }
    }
    @discardableResult func importProfile(from url: URL) throws -> UUID {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        guard let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize, size <= ProfileFile.maximumBytes else { throw ProfileFileError.tooLarge }
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var profile = try ProfileFile.decode(try handle.read(upToCount: ProfileFile.maximumBytes + 1) ?? Data())
        guard profiles.count < 100 else { throw ProfileFileError.invalid }
        profile.id = UUID()
        profiles.append(profile); save(); return profile.id
    }
}
