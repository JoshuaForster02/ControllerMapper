import Foundation
@main struct SafetyTests {
    static func main() throws {
        var count = 0
        func check(_ value: @autoclosure () -> Bool, _ message: String) { precondition(value(), message); count += 1 }
        var held = HeldInputs<String, String>()
        check(held.begin("a", output: "space") == "space", "Press is delivered")
        check(held.begin("a", output: "return") == nil, "Repeat cannot replace held output")
        check(held.end("a") == "space", "Release retains original profile action")
        check(held.end("a") == nil, "Stray release ignored")
        _ = held.begin("a", output: "space"); check(held.begin("b", output: "space") == nil, "Shared key only pressed once")
        check(held.end("a") == nil, "Shared output remains held")
        check(held.end("b") == "space", "Last owner releases output")
        _ = held.begin("a", output: "space"); _ = held.begin("b", output: "mouse")
        check(Set(held.releaseAll()) == Set(["space","mouse"]), "Pause/disconnect releases all unique outputs")
        check(held.releaseAll().isEmpty, "Cleanup is idempotent")
        let valid = Profile.builtInPresets[0]
        let validated = try ProfileFile.validate(valid)
        check(validated.name == valid.name, "Built-in profile validates")
        let encoded = try JSONEncoder().encode(valid), decoded = try ProfileFile.decode(encoded)
        check(decoded.mappings == valid.mappings, "Profile transfer preserves mappings")
        do { _ = try ProfileFile.decode(Data("broken".utf8)); preconditionFailure("Invalid JSON") } catch { count += 1 }
        do { _ = try ProfileFile.decode(Data(repeating: 0, count: ProfileFile.maximumBytes + 1)); preconditionFailure("Oversized file") } catch { count += 1 }
        var bad = valid; bad.name = " "
        do { _ = try ProfileFile.validate(bad); preconditionFailure("Empty name") } catch { count += 1 }
        bad = valid; var action = ButtonAction(type: .macro); action.macroSteps = [MacroStep(keyMapping: .none, keyDown: true, delayAfterMs: -1)]; bad.mappings[.a] = action
        do { _ = try ProfileFile.validate(bad); preconditionFailure("Negative delay") } catch { count += 1 }
        action.macroSteps = Array(repeating: MacroStep(), count: 201); bad.mappings[.a] = action
        do { _ = try ProfileFile.validate(bad); preconditionFailure("Oversized macro") } catch { count += 1 }
        check(!ProfileFile.safeFilename("../../bad/name").contains("/"), "Export name cannot escape chosen folder")
        print("\(count) Ctrl input-safety and profile checks passed")
    }
}
