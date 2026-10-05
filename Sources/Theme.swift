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
