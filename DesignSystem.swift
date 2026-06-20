import SwiftUI

/// Shared design tokens so spacing, corner radii, and typography stay
/// consistent across the menu bar popover, main window, and every sheet.
enum DS {
    // MARK: Corner Radii
    static let radiusSmall: CGFloat  = 6
    static let radiusMedium: CGFloat = 10
    static let radiusLarge: CGFloat  = 16
    static let radiusSheet: CGFloat  = 18

    // MARK: Spacing
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat  = 8
    static let spacingM: CGFloat  = 14
    static let spacingL: CGFloat  = 20
    static let spacingXL: CGFloat = 28

    // MARK: Sheet Sizing
    static let sheetWidthCompact: CGFloat = 340
    static let sheetWidthRegular: CGFloat = 440
}

// MARK: - Reusable Modifiers

extension View {
    /// A subtle card surface: translucent fill + hairline border. Used for
    /// list rows, badges, and grouped content blocks throughout the app.
    func cardSurface(radius: CGFloat = DS.radiusMedium) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color(.quaternarySystemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(.white.opacity(0.06), lineWidth: 1)
            )
    }

    /// Standard padding + sizing wrapper for sheet content (New Profile,
    /// Bluetooth picker, About). Keeps every sheet's outer rhythm identical.
    func sheetContainer(width: CGFloat = DS.sheetWidthCompact) -> some View {
        self
            .padding(DS.spacingXL)
            .frame(width: width)
    }

    /// "Eyebrow" section label style — small, bold, tracked-out, muted.
    func sectionEyebrow() -> some View {
        self
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.secondary)
            .tracking(1)
    }
}

// MARK: - Shared Sheet Header

/// Icon + title (+ optional subtitle) row used at the top of every sheet,
/// so they all read as part of the same app instead of separately styled
/// screens bolted together.
struct SheetHeader: View {
    let title: String
    var systemImage: String? = nil
    var subtitle: String? = nil
    var tint: Color = .accentColor

    var body: some View {
        HStack(spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3.bold())
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
    }
}
