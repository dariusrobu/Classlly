import SwiftUI

// MARK: - Rainbow Colors
struct RainbowColors {
    static let blue = Color(hex: "3B82F6")
    static let purple = Color(hex: "8B5CF6")
    static let green = Color(hex: "10B981")
    static let orange = Color(hex: "F59E0B")
    static let red = Color(hex: "EF4444")
    static let darkCard = Color(red: 0.1, green: 0.1, blue: 0.12)
}

// Helper for Hex
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
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Helper extension for Adaptive Colors (Dark/Light mode)
extension Color {
    init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { traits in
            return traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

// MARK: - Dynamic App Theme Colors
extension Color {
    static let themeBackground = Color(light: .systemGroupedBackground, dark: .systemGroupedBackground)
    static let themeSurface = Color(light: .secondarySystemGroupedBackground, dark: .secondarySystemGroupedBackground)
    static let themeTextPrimary = Color(light: .label, dark: .label)
    static let themeTextSecondary = Color(light: .secondaryLabel, dark: .secondaryLabel)

    static var themePrimary: Color {
        return AppTheme.shared.selectedTheme.primaryColor
    }
    
    static var themeSecondary: Color {
        return AppTheme.shared.selectedTheme.secondaryColor
    }
    
    static var themeAccent: Color {
        return AppTheme.shared.selectedTheme.primaryColor
    }
    
    static let themeSuccess = Color.green
    static let themeError = Color.red
    static let themeWarning = Color.orange

    static let adaptiveBackground = Color(.systemGroupedBackground)
    static let adaptiveSecondaryBackground = Color(.secondarySystemGroupedBackground)
    static let adaptiveTertiaryBackground = Color(.tertiarySystemGroupedBackground)
    static let adaptiveBorder = Color(.separator)
    static let adaptiveTertiary = Color(.tertiaryLabel)
    static let adaptivePrimary = Color.primary
    static let adaptiveSecondary = Color.secondary
}
