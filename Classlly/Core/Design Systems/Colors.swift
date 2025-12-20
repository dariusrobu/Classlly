import SwiftUI

// MARK: - App Theme Colors
/// Global extension to Color to support semantic naming used in SharedComponents
extension Color {
    
    // MARK: - Brand & Primary
    static let themePrimary = Color.blue // Change this to your specific Hex if needed
    static let themeSecondary = Color.purple
    static let themeWarning = Color.orange
    static let themeError = Color.red
    static let themeSuccess = Color.green
    
    // MARK: - Surfaces & Backgrounds
    /// Main background color (adapts to light/dark)
    static let themeBackground = Color(UIColor.systemBackground)
    /// Card/Surface background color
    static let themeSurface = Color(UIColor.secondarySystemBackground)
    /// Tertiary background for nested elements
    static let adaptiveTertiaryBackground = Color(UIColor.tertiarySystemBackground)
    
    // MARK: - Text
    static let themeTextPrimary = Color.primary
    static let themeTextSecondary = Color.secondary
    static let themeTextTertiary = Color(UIColor.tertiaryLabel)
    
    // MARK: - Borders & Dividers
    static let adaptiveBorder = Color(UIColor.separator)
    static let adaptiveSeparator = Color(UIColor.opaqueSeparator)
}

// MARK: - Rainbow & Gradient Colors
struct RainbowColors {
    
    // MARK: - Specific Colors (Required by SharedComponents)
    static let blue = Color.blue
    static let purple = Color.purple
    static let pink = Color.pink
    static let orange = Color.orange
    static let yellow = Color.yellow
    static let green = Color.green
    static let red = Color.red
    
    /// A dark card background used for specific high-contrast cards
    static let darkCard = Color(red: 0.11, green: 0.11, blue: 0.12)
    
    // MARK: - Collections
    static let all: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink
    ]
    
    static let pastel: [Color] = [
        Color(red: 1.0, green: 0.8, blue: 0.8),
        Color(red: 1.0, green: 0.9, blue: 0.8),
        Color(red: 1.0, green: 1.0, blue: 0.8),
        Color(red: 0.8, green: 1.0, blue: 0.8),
        Color(red: 0.8, green: 0.9, blue: 1.0),
        Color(red: 0.9, green: 0.8, blue: 1.0)
    ]
}

// MARK: - Helper for Hex Colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
