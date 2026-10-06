import SwiftUI
import AppKit

// Lavender design system for unADHD.
enum Theme {
    // Neutral app background (lavender is reserved for inner boxes + the floating card).
    static let appBgTop   = Color(hex: 0xFFFFFF)
    static let appBgBottom = Color(hex: 0xEFEFF3)
    static let cardTop    = Color(hex: 0xFEFDFF)   // barely-there lavender card
    static let cardBottom = Color(hex: 0xF4F0FB)
    static let accent     = Color(hex: 0x7C5CD8)   // primary purple (text accents, toggle)
    static let accentMuted = Color(hex: 0x9385D6)  // softer fill for buttons / selected chip
    static let accentSoft = Color(hex: 0xB9A5F0)
    static let ink        = Color(hex: 0x3A2E5C)   // deep purple text
    static let subtle     = Color(hex: 0x8A7CB0)
    static let cardStroke = Color(hex: 0xE7DFF4)   // soft lavender card border

    // Neutral surfaces for the app's inner boxes — lavender stays as accent only.
    static let surface       = Color(hex: 0xF6F6F8)
    static let surfaceStroke = Color(hex: 0xE5E5EA)

    // Inner-core fill for nested "tray + plate" boxes (text fields sitting inside a card).
    static let inputFill     = Color(hex: 0xFFFFFF)

    // MARK: - Spacing scale
    // One ladder so every gap/padding is a deliberate step, not a magic number.
    // (high-end-visual-design §4C: consistent spatial rhythm.)
    enum Space {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 28
    }

    // MARK: - Corner-radius scale
    // Concentric curves: an inner box nested in a card uses the next step DOWN
    // so their rounded corners stay visually parallel (§4A).
    enum Radius {
        static let sm: CGFloat = 8    // chips, small inputs
        static let md: CGFloat = 12   // inner boxes inside a card
        static let lg: CGFloat = 16   // app cards
        static let xl: CGFloat = 22   // floating card
    }

    // MARK: - Typography
    // SF Pro Rounded reads as warm + native on macOS — the right voice for a calm
    // focus app. (The skill's "banned fonts" list is web-font advice; it doesn't
    // apply to native Apple apps, so we lean into the system face deliberately.)
    enum Typo {
        static let display  = Font.system(size: 28, weight: .bold,     design: .rounded)
        static let title    = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 16, weight: .semibold, design: .rounded)
        static let body     = Font.system(size: 14, weight: .regular,  design: .rounded)
        static let callout  = Font.system(size: 13, weight: .medium,   design: .rounded)
        static let caption  = Font.system(size: 11, weight: .medium,   design: .rounded)
        // Pill-shaped section label: tiny, bold, wide tracking (§4C "eyebrow tags").
        static let eyebrow  = Font.system(size: 10, weight: .bold,     design: .rounded)
    }

    // MARK: - Motion
    // Real motion has mass. Default easings feel mechanical — springs feel alive (§5).
    enum Motion {
        static let spring  = Animation.spring(response: 0.42, dampingFraction: 0.82)
        static let snappy  = Animation.spring(response: 0.28, dampingFraction: 0.74)
        static let gentle  = Animation.spring(response: 0.55, dampingFraction: 0.9)
    }

    // MARK: - Shadows
    // Soft, highly diffused, and TINTED with ink/accent — never harsh black (§2, §3.3).
    struct Shadow {
        let color: Color, radius: CGFloat, y: CGFloat
        // Resting elevation for app cards & inner boxes.
        static let soft = Shadow(color: Theme.ink.opacity(0.07),    radius: 14, y: 6)
        // Lifted elements that float above the app (the floating card).
        static let card = Shadow(color: Theme.accent.opacity(0.20), radius: 20, y: 10)
    }
}

// MARK: - Reusable surface modifiers

extension View {
    /// Soft, tinted ambient shadow from a Theme.Shadow token.
    func softShadow(_ s: Theme.Shadow = .soft) -> some View {
        shadow(color: s.color, radius: s.radius, x: 0, y: s.y)
    }

    /// A neutral app card: rounded surface + hairline stroke + soft shadow.
    /// This is the "plate" that inner boxes (the "tray") nest inside.
    func themeCard(radius: CGFloat = Theme.Radius.lg,
                   fill: Color = Theme.surface,
                   stroke: Color = Theme.surfaceStroke,
                   shadow: Theme.Shadow = .soft) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(fill)
                .overlay(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .stroke(stroke, lineWidth: 1)
                )
                .softShadow(shadow)
        )
    }

    /// An inner "tray" box (text fields, nested rows) — one radius step down from
    /// its parent card, with a faint inset highlight so it reads as recessed.
    func innerBox(radius: CGFloat = Theme.Radius.md) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Theme.inputFill.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .stroke(Theme.surfaceStroke.opacity(0.7), lineWidth: 1)
                )
        )
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(.sRGB,
                  red:   Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue:  Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }
}

// Mascot, loaded from the app bundle's Resources.
enum Assets {
    static let mascot: NSImage? = {
        if let url = Bundle.main.url(forResource: "mascot", withExtension: "png") {
            return NSImage(contentsOf: url)
        }
        return nil
    }()

    // The waving "Hi!" sprout (transparent background) — the hero on Focus & Add.
    static let mascotHi: NSImage? = {
        if let url = Bundle.main.url(forResource: "mascot_hi", withExtension: "png") {
            return NSImage(contentsOf: url)
        }
        return nil
    }()

    // Monochrome sprout glyph for the menu bar (template = auto light/dark tint).
    static let menuBarIcon: NSImage? = {
        if let url = Bundle.main.url(forResource: "menubar", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            img.isTemplate = true
            img.size = NSSize(width: 18, height: 18)
            return img
        }
        return nil
    }()
}

struct MascotView: View {
    var size: CGFloat = 80
    var body: some View {
        Group {
            if let img = Assets.mascot {
                Image(nsImage: img).resizable().scaledToFit()
            } else {
                Image(systemName: "leaf.fill").resizable().scaledToFit()
                    .foregroundStyle(Theme.accent)
            }
        }
        .frame(width: size, height: size)
    }
}

// The waving "Hi!" sprout — wider than it is tall, so it's framed by width.
struct HiMascotView: View {
    var width: CGFloat = 180
    var body: some View {
        Group {
            if let img = Assets.mascotHi {
                Image(nsImage: img).resizable().scaledToFit()
            } else {
                MascotView(size: width * 0.8)
            }
        }
        .frame(width: width)
    }
}
