import Foundation
import SwiftUI
import Combine

final class ProfileManager: ObservableObject {
    static let shared = ProfileManager()

    @Published var profiles: [Profile] = []
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
        guard let data = try? JSONEncoder().encode(profile) else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(profile.name).cmprofile")
        try? data.write(to: url)
        return url
    }

    func importProfile(from url: URL) throws {
        let data = try Data(contentsOf: url)
        var profile = try JSONDecoder().decode(Profile.self, from: data)
        profile.id = UUID()   // new ID to avoid collision
        profiles.append(profile)
        save()
    }
}
