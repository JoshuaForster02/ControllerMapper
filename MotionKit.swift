import SwiftUI
import AppKit

/// Decorative telemetry. No polling, synthetic device data or input work occurs here.
/// Animation pauses when the app is inactive and respects system Reduce Motion.
struct CircuitBackdrop: View {
    var emphasis: Double = 0.65
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage("futuristicMotion") private var motionMode = "system"
    private var reduceMotion: Bool { motionMode == "off" || (motionMode != "on" && systemReduceMotion) }
    @State private var active = NSApplication.shared.isActive
    private let tint = Color(red: 0.27, green: 0.67, blue: 1)
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: reduceMotion || !active)) { context in
            let time = reduceMotion || !active ? 0 : context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600)
            Canvas { graphics, size in
                guard size.width > 0, size.height > 0 else { return }
                let center = CGPoint(x: size.width * 0.62, y: size.height * 0.35)
                var grid = Path()
                for x in stride(from: CGFloat(0), through: size.width, by: 32) { grid.move(to: CGPoint(x: x, y: 0)); grid.addLine(to: CGPoint(x: x, y: size.height)) }
                for y in stride(from: CGFloat(0), through: size.height, by: 32) { grid.move(to: CGPoint(x: 0, y: y)); grid.addLine(to: CGPoint(x: size.width, y: y)) }
                graphics.stroke(grid, with: .color(tint.opacity(0.035)), lineWidth: 0.5)
                for index in 0..<3 {
                    let radius = min(size.width, size.height) * (0.36 + Double(index) * 0.13)
                    let rect = CGRect(x: center.x - radius, y: center.y - radius * 0.6, width: radius * 2, height: radius * 1.2)
                    let orbit = Path(ellipseIn: rect)
                    graphics.stroke(orbit, with: .color(tint.opacity(0.07 * emphasis)), lineWidth: 0.7)
                    let angle = time * (0.12 + Double(index) * 0.03) + Double(index) * 2.1
                    let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius * 0.6)
                    let dot = CGRect(x: point.x - 2, y: point.y - 2, width: 4, height: 4)
                    graphics.fill(Path(ellipseIn: dot), with: .color(tint.opacity(0.7 * emphasis)))
                    let arc = orbit.trimmedPath(from: CGFloat((time * 0.02 + Double(index) * 0.28).truncatingRemainder(dividingBy: 0.85)), to: CGFloat(min(1, (time * 0.02 + Double(index) * 0.28).truncatingRemainder(dividingBy: 0.85) + 0.15)))
                    graphics.stroke(arc, with: .color(tint.opacity(0.2 * emphasis)), lineWidth: 1.4)
                }
                let sweep = (sin(time * 0.18) * 0.5 + 0.5) * size.height
                let line = Path { path in path.move(to: CGPoint(x: 0, y: sweep)); path.addLine(to: CGPoint(x: size.width, y: sweep)) }
                graphics.stroke(line, with: .linearGradient(Gradient(colors: [.clear, tint.opacity(0.12 * emphasis), .clear]), startPoint: CGPoint(x: 0, y: sweep), endPoint: CGPoint(x: size.width, y: sweep)), lineWidth: 1)
            }
        }
        .background(Color(red: 0.035, green: 0.043, blue: 0.06))
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in active = true }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in active = false }
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}

struct SignalGlyph: View {
    var symbol: String
    var active: Bool
    var pulse: Int
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage("futuristicMotion") private var motionMode = "system"
    private var reduceMotion: Bool { motionMode == "off" || (motionMode != "on" && systemReduceMotion) }
    @State private var flash = false
    private let tint = Color(red: 0.27, green: 0.67, blue: 1)
    var body: some View {
        ZStack {
            Circle().stroke(tint.opacity(active ? 0.32 : 0.1), lineWidth: 1)
            Circle().trim(from: 0.05, to: active ? 0.84 : 0.3).stroke(tint.opacity(active ? 0.85 : 0.3), style: StrokeStyle(lineWidth: 1.5, lineCap: .round)).rotationEffect(.degrees(flash && !reduceMotion ? 26 : 0))
            Circle().stroke(tint.opacity(flash ? 0.65 : 0), lineWidth: 1).scaleEffect(flash && !reduceMotion ? 1.3 : 1)
            Image(systemName: symbol).font(.system(size: 20, weight: .light)).foregroundStyle(active ? tint : .gray)
        }
        .frame(width: 58, height: 58)
        .shadow(color: tint.opacity(flash ? 0.55 : (active ? 0.16 : 0)), radius: flash ? 18 : 8)
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.62), value: flash)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: active)
        .task(id: pulse) {
            guard pulse != 0 else { return }
            flash = true
            do { try await Task.sleep(nanoseconds: 260_000_000) } catch { return }
            flash = false
        }
        .accessibilityHidden(true)
    }
}
