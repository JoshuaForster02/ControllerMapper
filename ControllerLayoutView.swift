import SwiftUI

/// Visual Xbox Series S controller. Tap a button to select it.
struct ControllerLayoutView: View {
    @Binding var selectedButton: ControllerButton?
    let profile: Profile

    @ObservedObject private var liveController = ControllerManager.shared

    private func isLivePressed(_ btn: ControllerButton) -> Bool {
        liveController.pressedButtons.contains(btn)
    }

    /// Subtle white glow + scale bump applied on top of a button while it's
    /// physically held — purely cosmetic, independent of selection/mapping.
    private func pressGlow(_ btn: ControllerButton) -> some View {
        let pressed = isLivePressed(btn)
        return Circle()
            .stroke(.white.opacity(pressed ? 0.9 : 0), lineWidth: 2)
            .scaleEffect(pressed ? 1.25 : 1.0)
            .animation(.easeOut(duration: 0.12), value: pressed)
            .allowsHitTesting(false)
    }

    // Controller body size (scales with frame)
    private let W: CGFloat = 520
    private let H: CGFloat = 310

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / W, geo.size.height / H)
            ZStack {
                controllerBody
                    .frame(width: W, height: H)
                    .scaleEffect(scale)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(W / H, contentMode: .fit)
    }

    // MARK: - Controller Body

    private var controllerBody: some View {
        ZStack {
            // Shadow + shell
            RoundedRectangle(cornerRadius: 60)
                .fill(
                    LinearGradient(
                        colors: [Color(.sRGB, red: 0.18, green: 0.18, blue: 0.20, opacity: 1),
                                 Color(.sRGB, red: 0.12, green: 0.12, blue: 0.14, opacity: 1)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.5), radius: 24, y: 12)
                .padding(.horizontal, 20)

            // Grip bumps
            HStack {
                Capsule()
                    .fill(Color(.sRGB, red: 0.15, green: 0.15, blue: 0.17, opacity: 1))
                    .frame(width: 90, height: 40)
                    .offset(y: 70)
                Spacer()
                Capsule()
                    .fill(Color(.sRGB, red: 0.15, green: 0.15, blue: 0.17, opacity: 1))
                    .frame(width: 90, height: 40)
                    .offset(y: 70)
            }
            .padding(.horizontal, 30)

            // ── Triggers & Bumpers ──
            HStack {
                VStack(spacing: 4) {
                    triggerButton(.lt, label: "LT")
                    bumpButton(.lb, label: "LB")
                }
                Spacer()
                VStack(spacing: 4) {
                    triggerButton(.rt, label: "RT")
                    bumpButton(.rb, label: "RB")
                }
            }
            .padding(.horizontal, 30)
            .offset(y: -100)

            // ── Left Stick ──
            analogStick(buttons: (.leftStickX, .leftStickY), click: .l3, at: CGPoint(x: -90, y: 20))

            // ── Right Stick ──
            analogStick(buttons: (.rightStickX, .rightStickY), click: .r3, at: CGPoint(x: 90, y: 60))

            // ── D-Pad ──
            dpad(at: CGPoint(x: -160, y: 60))

            // ── ABXY ──
            abxyCluster(at: CGPoint(x: 160, y: 20))

            // ── Center Buttons ──
            HStack(spacing: 16) {
                centerButton(.view, label: "⧉")
                homeButton(.home)
                centerButton(.menu, label: "☰")
            }
            .offset(y: -10)
        }
    }

    // MARK: - Button Factories

    private func triggerButton(_ btn: ControllerButton, label: String) -> some View {
        controlButton(btn, size: CGSize(width: 60, height: 22)) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    private func bumpButton(_ btn: ControllerButton, label: String) -> some View {
        controlButton(btn, size: CGSize(width: 58, height: 18)) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private func dpad(at offset: CGPoint) -> some View {
        ZStack {
            // Cross shape
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.sRGB, red: 0.1, green: 0.1, blue: 0.12, opacity: 1))
                .frame(width: 72, height: 24)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.sRGB, red: 0.1, green: 0.1, blue: 0.12, opacity: 1))
                .frame(width: 24, height: 72)

            // Tap zones
            Group {
                dpadBtn(.dUp,    at: CGPoint(x: 0, y: -24))
                dpadBtn(.dDown,  at: CGPoint(x: 0, y:  24))
                dpadBtn(.dLeft,  at: CGPoint(x: -24, y: 0))
                dpadBtn(.dRight, at: CGPoint(x:  24, y: 0))
            }
        }
        .offset(x: offset.x, y: offset.y)
    }

    private func dpadBtn(_ btn: ControllerButton, at pos: CGPoint) -> some View {
        Button {
            selectedButton = btn
        } label: {
            Circle()
                .fill(Color.clear)
                .frame(width: 22, height: 22)
                .overlay(
                    Image(systemName: arrowFor(btn))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(hasMapping(btn) ? mappingColor(btn) : .white.opacity(0.5))
                )
                .overlay(
                    Circle()
                        .stroke(selectedButton == btn ? Color.accentColor : Color.clear, lineWidth: 2)
                )
                .overlay(pressGlow(btn))
                .scaleEffect(isLivePressed(btn) ? 1.2 : 1.0)
                .animation(.easeOut(duration: 0.1), value: isLivePressed(btn))
        }
        .buttonStyle(.plain)
        .offset(x: pos.x, y: pos.y)
    }

    private func arrowFor(_ btn: ControllerButton) -> String {
        switch btn {
        case .dUp:    return "chevron.up"
        case .dDown:  return "chevron.down"
        case .dLeft:  return "chevron.left"
        case .dRight: return "chevron.right"
        default: return "circle"
        }
    }

    private func abxyCluster(at offset: CGPoint) -> some View {
        ZStack {
            faceBtn(.y, label: "Y", color: Color(hex: "#F5B942") ?? .yellow, at: CGPoint(x: 0,   y: -28))
            faceBtn(.a, label: "A", color: Color(hex: "#42C35C") ?? .green,  at: CGPoint(x: 0,   y:  28))
            faceBtn(.x, label: "X", color: Color(hex: "#5B9CF5") ?? .blue,   at: CGPoint(x: -28, y:  0))
            faceBtn(.b, label: "B", color: Color(hex: "#E8534A") ?? .red,    at: CGPoint(x:  28, y:  0))
        }
        .offset(x: offset.x, y: offset.y)
    }

    private func faceBtn(_ btn: ControllerButton, label: String, color: Color, at pos: CGPoint) -> some View {
        Button {
            selectedButton = btn
        } label: {
            ZStack {
                Circle()
                    .fill(selectedButton == btn ? color : color.opacity(0.25))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .stroke(selectedButton == btn ? color : color.opacity(0.5), lineWidth: 1.5)
                    )
                    .shadow(color: selectedButton == btn ? color.opacity(0.5) : .clear, radius: 6)

                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(selectedButton == btn ? .white : color)

                if hasMapping(btn) && selectedButton != btn {
                    Circle()
                        .fill(color.opacity(0.8))
                        .frame(width: 6, height: 6)
                        .offset(x: 9, y: -9)
                }

                pressGlow(btn).frame(width: 28, height: 28)
            }
            .scaleEffect(isLivePressed(btn) ? 1.12 : 1.0)
            .animation(.easeOut(duration: 0.1), value: isLivePressed(btn))
        }
        .buttonStyle(.plain)
        .offset(x: pos.x, y: pos.y)
    }

    private func analogStick(
        buttons: (ControllerButton, ControllerButton),
        click: ControllerButton,
        at offset: CGPoint
    ) -> some View {
        Button {
            selectedButton = click
        } label: {
            ZStack {
                // Outer ring
                Circle()
                    .fill(Color(.sRGB, red: 0.08, green: 0.08, blue: 0.10, opacity: 1))
                    .frame(width: 58, height: 58)
                    .shadow(color: .black.opacity(0.4), radius: 4, y: 3)

                // Inner cap
                Circle()
                    .fill(
                        selectedButton == click
                            ? LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
                                             startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [Color(.sRGB, red: 0.22, green: 0.22, blue: 0.25, opacity: 1),
                                                      Color(.sRGB, red: 0.16, green: 0.16, blue: 0.18, opacity: 1)],
                                             startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 40, height: 40)

                // Axis indicator dots
                let hasMappings = hasMapping(buttons.0) || hasMapping(buttons.1)
                if hasMappings {
                    Circle().fill(Color.accentColor).frame(width: 5, height: 5)
                }

                Circle()
                    .stroke(selectedButton == click ? Color.accentColor : Color.clear, lineWidth: 2)
                    .frame(width: 58, height: 58)
            }
        }
        .buttonStyle(.plain)
        .offset(x: offset.x, y: offset.y)
        .contextMenu {
            Button("Map X-Axis") { selectedButton = buttons.0 }
            Button("Map Y-Axis") { selectedButton = buttons.1 }
            Button("Map Click")  { selectedButton = click }
        }
    }

    private func centerButton(_ btn: ControllerButton, label: String) -> some View {
        Button {
            selectedButton = btn
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedButton == btn
                          ? Color.accentColor.opacity(0.3)
                          : Color(.sRGB, red: 0.15, green: 0.15, blue: 0.18, opacity: 1))
                    .frame(width: 32, height: 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(selectedButton == btn ? Color.accentColor : Color.clear, lineWidth: 1.5)
                    )
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .buttonStyle(.plain)
    }

    private func homeButton(_ btn: ControllerButton) -> some View {
        Button {
            selectedButton = btn
        } label: {
            Circle()
                .fill(
                    selectedButton == btn
                        ? LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
                                         startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Color(.sRGB, red: 0.25, green: 0.25, blue: 0.28, opacity: 1),
                                                  Color(.sRGB, red: 0.18, green: 0.18, blue: 0.20, opacity: 1)],
                                         startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 26, height: 26)
                .shadow(color: selectedButton == btn ? Color.accentColor.opacity(0.5) : .black.opacity(0.3),
                        radius: 4)
                .overlay(
                    Image(systemName: "circle")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                )
                .overlay(pressGlow(btn))
                .scaleEffect(isLivePressed(btn) ? 1.15 : 1.0)
                .animation(.easeOut(duration: 0.1), value: isLivePressed(btn))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func controlButton<Content: View>(
        _ btn: ControllerButton,
        size: CGSize,
        @ViewBuilder label: () -> Content
    ) -> some View {
        Button {
            selectedButton = btn
        } label: {
            RoundedRectangle(cornerRadius: 5)
                .fill(isLivePressed(btn)
                      ? Color.white.opacity(0.25)
                      : selectedButton == btn
                          ? Color.accentColor.opacity(0.3)
                          : Color(.sRGB, red: 0.14, green: 0.14, blue: 0.16, opacity: 1))
                .frame(width: size.width, height: size.height)
                .overlay(label())
                .scaleEffect(isLivePressed(btn) ? 1.06 : 1.0)
                .animation(.easeOut(duration: 0.1), value: isLivePressed(btn))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(selectedButton == btn ? Color.accentColor : Color.white.opacity(0.08),
                                lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }

    private func hasMapping(_ btn: ControllerButton) -> Bool {
        if let action = profile.mappings[btn] {
            return action.type != .none
        }
        return false
    }

    private func mappingColor(_ btn: ControllerButton) -> Color {
        Color.accentColor
    }
}

#Preview {
    ControllerLayoutView(selectedButton: .constant(.a), profile: .default)
        .frame(width: 560, height: 340)
        .background(Color(.windowBackgroundColor))
}
