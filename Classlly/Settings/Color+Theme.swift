import SwiftUI

// Helper extension
extension Color {
    init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { traits in
            return traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

// MARK: - App Theme Colors
extension Color {
    
    // --- BACKGROUNDS ---
    static let themeBackground = Color(light: .systemGroupedBackground, dark: .systemGroupedBackground)
    static let themeSurface = Color(light: .secondarySystemGroupedBackground, dark: .secondarySystemGroupedBackground)

    // --- TEXT ---
    static let themeTextPrimary = Color(light: .label, dark: .label)
    static let themeTextSecondary = Color(light: .secondaryLabel, dark: .secondaryLabel)

    // --- INTERACTIVE / BRAND ---
    static let themePrimary = Color.blue
    static let themeSecondary = Color.purple
    static let themeAccent = Color.blue
    
    // --- SEMANTIC ---
    static let themeSuccess = Color.green
    static let themeError = Color.red
    static let themeWarning = Color.orange

    // --- ADAPTIVE UTILITIES ---
    static let adaptiveBackground = Color(.systemGroupedBackground)
    static let adaptiveSecondaryBackground = Color(.secondarySystemGroupedBackground)
    static let adaptiveTertiaryBackground = Color(.tertiarySystemGroupedBackground)
    static let adaptiveBorder = Color(.separator)
    static let adaptiveTertiary = Color(.tertiaryLabel)
    static let adaptivePrimary = Color.primary
    static let adaptiveSecondary = Color.secondary
    
    // --- LEGACY ---
    static let themeBlue = Color.blue
    static let themeGreen = Color.green
    static let themeOrange = Color.orange
    static let themePurple = Color.purple
    static let themeRed = Color.red
}

// MARK: - View Modifiers

struct AdaptiveCard: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(Color.themeSurface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.adaptiveBorder.opacity(0.3), lineWidth: 1)
            )
            .shadow(
                color: colorScheme == .dark ? .black.opacity(0.4) : .black.opacity(0.08),
                radius: colorScheme == .dark ? 6 : 3,
                x: 0,
                y: colorScheme == .dark ? 3 : 1
            )
    }
}

struct AdaptiveListRow: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .listRowBackground(Color.themeSurface)
    }
}

extension View {
    func adaptiveCard() -> some View {
        self.modifier(AdaptiveCard())
    }
    
    func adaptiveListRow() -> some View {
        self.modifier(AdaptiveListRow())
    }
}
