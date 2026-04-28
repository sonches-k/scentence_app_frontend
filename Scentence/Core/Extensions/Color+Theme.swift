import SwiftUI

// MARK: - AppColor (fully adaptive light/dark)

enum AppColor {
    static let background    = Color.dyn(l: "#F5EFEB", d: "#18263A")
    static let backgroundAlt = Color.dyn(l: "#EDE0EC", d: "#201438")
    static let surface       = Color.dyn(l: "#2F4156", d: "#2F4156")
    static let card          = Color.dyn(l: "#FFFFFF", d: "#1E3148")
    static let cardBorder    = Color.dyn(l: "#A0707E", d: "#C090A0")
    static let accent        = Color.dyn(l: "#A0707E", d: "#E8AABB")
    static let accentLight   = Color.dyn(l: "#F7C9D4", d: "#4A2030")
    static let textPrimary   = Color.dyn(l: "#2F4156", d: "#F0EAE5")
    static let textSecondary = Color.dyn(l: "#4A5E6E", d: "#E8C0C8")
    static let textMuted     = Color.dyn(l: "#6B7D8D", d: "#C8A0AA")
    static let separator     = Color.dyn(l: "#D0B8C0", d: "#4A3040")
    static let error         = Color.dyn(l: "#D4596A", d: "#F08090")
    static let success       = Color.dyn(l: "#6BBF8A", d: "#7AD09A")
}

// MARK: - AppFont

enum AppFont {
    static func display(_ size: CGFloat) -> Font { .system(size: size, weight: .thin, design: .serif) }
    static func title(_ size: CGFloat)   -> Font { .system(size: size, weight: .light, design: .serif) }
    static func body(_ size: CGFloat)    -> Font { .system(size: size, weight: .regular, design: .default) }
    static func caption(_ size: CGFloat) -> Font { .system(size: size, weight: .regular, design: .default) }
    static func mono(_ size: CGFloat)    -> Font { .system(size: size, weight: .regular, design: .monospaced) }
}

// MARK: - URL

extension URL {
    static func robust(_ string: String) -> URL? {
        if let url = URL(string: string) { return url }
        let allowed = CharacterSet.urlFragmentAllowed
        guard let encoded = string.addingPercentEncoding(withAllowedCharacters: allowed) else { return nil }
        return URL(string: encoded)
    }
}

// MARK: - Color

extension Color {
    static func dyn(l light: String, d dark: String) -> Color {
        Color(UIColor(dynamicProvider: { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(Color(hex: dark))
                : UIColor(Color(hex: light))
        }))
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
