import Foundation

/// Retains the output selected on key-down, across profile changes and pauses.
struct HeldInputs<Input: Hashable, Output: Hashable> {
    private var held: [Input: Output] = [:]
    private var counts: [Output: Int] = [:]
    mutating func begin(_ input: Input, output: Output) -> Output? {
        guard held[input] == nil else { return nil }
        held[input] = output
        let count = counts[output, default: 0]; counts[output] = count + 1
        return count == 0 ? output : nil
    }
    mutating func end(_ input: Input) -> Output? {
        guard let output = held.removeValue(forKey: input), let count = counts[output] else { return nil }
        if count > 1 { counts[output] = count - 1; return nil }
        counts.removeValue(forKey: output); return output
    }
    mutating func releaseAll() -> [Output] {
        let outputs = Array(counts.keys); held.removeAll(); counts.removeAll(); return outputs
    }
}

enum HeldOutput: Hashable {
    case key(UInt16, UInt64)
    case mouse(UInt32)
}

enum ProfileFileError: LocalizedError {
    case tooLarge, invalid
    var errorDescription: String? {
        switch self {
        case .tooLarge: return "Das Profil ist zu groß. Maximal 512 KB sind erlaubt."
        case .invalid: return "Keine gültige Ctrl-Profildatei. Name, Belegungen und Makro-Grenzen prüfen."
        }
    }
}

enum ProfileFile {
    static let maximumBytes = 512 * 1024
    static func decode(_ data: Data) throws -> Profile {
        guard data.count <= maximumBytes else { throw ProfileFileError.tooLarge }
        let profile: Profile
        do { profile = try JSONDecoder().decode(Profile.self, from: data) }
        catch { throw ProfileFileError.invalid }
        return try validate(profile)
    }
    static func validate(_ profile: Profile) throws -> Profile {
        guard !profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              profile.name.count <= 100, profile.icon.count <= 100,
              profile.autoSwitchBundleID.count <= 255,
              profile.mappings.count <= ControllerButton.allCases.count else { throw ProfileFileError.invalid }
        for action in profile.mappings.values {
            guard action.mouseSensitivity.isFinite, (0...100).contains(action.mouseSensitivity),
                  (0...100).contains(action.scrollAmount), action.appBundleID.count <= 255,
                  action.appName.count <= 200, action.macroSteps.count <= 200,
                  validKey(action.keyMapping) else { throw ProfileFileError.invalid }
            var delay = 0
            for step in action.macroSteps {
                guard (0...10000).contains(step.delayAfterMs), validKey(step.keyMapping) else { throw ProfileFileError.invalid }
                delay += step.delayAfterMs
            }
            guard delay <= 60000 else { throw ProfileFileError.invalid }
        }
        return profile
    }
    private static func validKey(_ key: KeyMapping) -> Bool {
        (key.keyCode <= 255 || key.keyCode == 65535) && key.modifiers <= 0x7fffffff && key.displayName.count <= 100
    }
    static func safeFilename(_ name: String) -> String {
        let components = name.components(separatedBy: CharacterSet.alphanumerics.union(.whitespaces).inverted).filter { !$0.isEmpty }
        let title = String(components.joined(separator: "-").prefix(80)).trimmingCharacters(in: .whitespaces)
        return (title.isEmpty ? "Ctrl-Profil" : title) + ".cmprofile"
    }
}
