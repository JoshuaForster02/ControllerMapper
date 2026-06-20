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
