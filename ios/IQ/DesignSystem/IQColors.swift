import SwiftUI

/// Brand base tones (original hexes)
struct IQColors {
    static let pink     = Color(hex: "FFCAE9")
    static let lavender = Color(hex: "CDD0F8")
    static let blush    = Color(hex: "F4DBE9")

    /// Deeper, more saturated variants (same hue families — no new palette)
    static let pinkVivid     = Color(hex: "F0629D")
    static let lavenderVivid = Color(hex: "7C85EB")
    static let blushVivid    = Color(hex: "DCA5BE")

    /// Strong accents for strokes, tab tint, CTAs
    static let pinkDark     = Color(hex: "D9488A")
    static let lavenderDark = Color(hex: "5B66E0")

    // Backgrounds — airy pastel (avoid pure white canvas)
    static let background = Color(hex: "FFCAE9").opacity(0.12)
    static let card       = Color.white.opacity(0.78)
    static let inputBg    = Color(hex: "F4DBE9").opacity(0.35)

    /// Soft wash behind screens for contrast with vibrant accents (flat, no gradient)
    static let canvasWash = Color(hex: "F4DBE9").opacity(0.28)

    /// Full-screen canvas: light pink ↔ lavender (behind glass cards)
    static var appCanvasGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "FFCAE9").opacity(0.22),
                Color(hex: "FFF8FC").opacity(0.92),
                Color(hex: "CDD0F8").opacity(0.16)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Commit / activity heatmap (legend MUST match grid cells; index = min(count, 4))
    static let commitHeatmapColors: [Color] = [
        lavender.opacity(0.14),
        blush,
        pink.opacity(0.92),
        pinkVivid.opacity(0.62),
        pinkVivid
    ]

    // Border / track
    static let border       = Color(hex: "CDD0F8").opacity(0.55)
    static let borderStrong = Color(hex: "9AA3F0").opacity(0.65)

    // Text
    static let textPrimary   = Color.primary
    static let textSecondary = Color.secondary
    static let textMuted     = Color(hex: "63636B")

    // Risk levels — vivid flat colors from the same family
    static let riskLow        = lavenderVivid
    static let riskLowBg      = lavender.opacity(0.45)
    static let riskModerate   = blushVivid
    static let riskModerateBg = blush.opacity(0.5)
    static let riskHigh       = pinkVivid
    static let riskHighBg     = pink.opacity(0.55)

    static let headerStart = pink
    static let headerEnd   = lavender

    static var headerGradient: LinearGradient {
        LinearGradient(colors: [pinkVivid.opacity(0.85)], startPoint: .leading, endPoint: .trailing)
    }
    static var diskGradient: LinearGradient {
        LinearGradient(colors: [blushVivid.opacity(0.6)], startPoint: .leading, endPoint: .trailing)
    }

    static let actionAnalytics = Gradient(colors: [lavenderVivid])
    static let actionCalendar  = Gradient(colors: [lavenderVivid])
    static let actionFood      = Gradient(colors: [blushVivid])
    static let actionSymptoms  = Gradient(colors: [pinkVivid])

    // MARK: - Flare prediction calendar (state colors — prompt spec)
    static let calStable    = Color(hex: "9B59B6")
    static let calMild      = Color(hex: "FFC300")
    static let calModerate  = Color(hex: "FF6B4A")
    static let calFlare     = Color(hex: "D91E18")
    static let calRecovery  = Color(hex: "1ABC9C")
    static let calFrost     = Color(hex: "F4DBE9")

    /// Rim label color — alternates vivid pink / lavender for readability
    static func rimWordColor(index: Int) -> Color {
        index % 2 == 0 ? pinkDark.opacity(0.92) : lavenderDark.opacity(0.92)
    }
}

extension View {
    /// Premium glass card: material + layered shadow depth (no gradients on the card itself)
    func iqVibrantMaterialCard(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.10), radius: 14, x: 0, y: 7)
            .shadow(color: IQColors.pinkVivid.opacity(0.10), radius: 22, x: 0, y: 0)
    }

    /// Global app screen backdrop (replaces flat white)
    func iqAppCanvasBackground() -> some View {
        background {
            IQColors.appCanvasGradient
                .ignoresSafeArea()
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8)*17, (int >> 4 & 0xF)*17, (int & 0xF)*17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 1, 1, 1)
        }
        self.init(.sRGB,
                  red:   Double(r) / 255,
                  green: Double(g) / 255,
                  blue:  Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

struct IQFont {
    static func black(_ size: CGFloat)     -> Font { .system(size: size, weight: .black) }
    static func bold(_ size: CGFloat)      -> Font { .system(size: size, weight: .bold) }
    static func semibold(_ size: CGFloat)  -> Font { .system(size: size, weight: .semibold) }
    static func medium(_ size: CGFloat)    -> Font { .system(size: size, weight: .medium) }
    static func regular(_ size: CGFloat)   -> Font { .system(size: size, weight: .regular) }
}
