import SwiftUI

/// A circular battery gauge with a glowing progress ring.
struct BatteryRingView: View {
    let percent: Int
    let isCharging: Bool
    let color: Color
    var size: CGFloat = 40

    private var fraction: Double { max(0, min(1, Double(percent) / 100)) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.18), lineWidth: size * 0.11)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    AngularGradient(colors: [color.opacity(0.5), color], center: .center),
                    style: StrokeStyle(lineWidth: size * 0.11, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.5), radius: size * 0.08)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: fraction)

            Group {
                if isCharging {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: size * 0.32, weight: .bold))
                        .foregroundStyle(color)
                } else {
                    Text("\(percent)")
                        .font(.system(size: size * 0.30, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.6)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

/// Soft, ambient blurred color blobs used as background décor.
struct AmbientBackground: View {
    let colors: [Color]
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                Circle()
                    .fill(color)
                    .frame(width: 160, height: 160)
                    .offset(
                        x: animate ? CGFloat(index * 40 - 40) : CGFloat(index * -30 + 20),
                        y: animate ? CGFloat(index * -30 + 10) : CGFloat(index * 25 - 10)
                    )
                    .blur(radius: 50)
                    .opacity(0.35)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        BatteryRingView(percent: 82, isCharging: false, color: .green, size: 48)
        BatteryRingView(percent: 24, isCharging: false, color: .red, size: 48)
        BatteryRingView(percent: 60, isCharging: true, color: .yellow, size: 48)
    }
    .padding()
}

// MARK: - Easter Egg Confetti

/// A burst of falling confetti pieces + a fun message — triggered by the
/// Konami-style button combo (↑↑↓↓←←→→ B A) on the controller.
struct ConfettiOverlay: View {
    private let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    @State private var animate = false

    private static let messages: [String] = [
        "Turbo mode... engaged? (not really, but nice combo)",
        "You've clearly done this before.",
        "Achievement unlocked: muscle memory.",
        "Somewhere, an old arcade cabinet just felt a disturbance.",
        "+0 stats. +1 vibe.",
        "Konami would be proud."
    ]
    private let message = ConfettiOverlay.messages.randomElement()!

    private struct Piece: Identifiable {
        let id = UUID()
        let x: CGFloat
        let delay: Double
        let color: Color
        let rotation: Double
    }

    private let pieces: [Piece] = (0..<26).map { i in
        Piece(
            x: CGFloat.random(in: 10...290),
            delay: Double.random(in: 0...0.4),
            color: [Color.red, .orange, .yellow, .green, .blue, .purple, .pink].randomElement()!,
            rotation: Double.random(in: 0...360)
        )
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.25)

            ForEach(pieces) { piece in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(piece.color)
                    .frame(width: 6, height: 10)
                    .rotationEffect(.degrees(piece.rotation + (animate ? 540 : 0)))
                    .position(x: piece.x, y: animate ? 340 : -20)
                    .animation(
                        .easeIn(duration: 1.8).delay(piece.delay),
                        value: animate
                    )
            }

            VStack(spacing: 4) {
                Text("🎮 Secret found!")
                    .font(.headline)
                Text(message)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            .scaleEffect(animate ? 1.0 : 0.6)
            .opacity(animate ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animate)
        }
        .onAppear { animate = true }
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
