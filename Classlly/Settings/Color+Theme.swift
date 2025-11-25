import SwiftUI
import UIKit

extension Color {
    init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { traits in
            return traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

extension Color {
    static let themeBackground = Color(light: .systemGroupedBackground, dark: .systemGroupedBackground)
    static let themeSurface = Color(light: .secondarySystemGroupedBackground, dark: .secondarySystemGroupedBackground)
    static let themeTextPrimary = Color(light: .label, dark: .label)
    static let themeTextSecondary = Color(light: .secondaryLabel, dark: .secondaryLabel)
    static let themePrimary = Color.blue
    static let themeSecondary = Color.purple
    static let themeAccent = Color.blue
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
    
    static let themeBlue = Color.blue
    static let themeGreen = Color.green
    static let themeOrange = Color.orange
    static let themePurple = Color.purple
    static let themeRed = Color.red
}

struct AdaptiveCard: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var themeManager: AppTheme
    var color: Color?
    
    func body(content: Content) -> some View {
        if themeManager.isGamified {
            if let highlightColor = color {
                content
                    .background(GameGradient.linear(base: highlightColor))
                    .cornerRadius(24)
                    .shadow(color: highlightColor.opacity(0.4), radius: 12, x: 0, y: 6)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.2), lineWidth: 1))
                    .foregroundColor(.white)
            } else {
                content
                    .background(GameColor.darkSurface)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 5)
                    .foregroundColor(.white)
            }
        } else {
            content
                .background(Color.adaptiveSecondaryBackground)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.adaptiveBorder.opacity(0.3), lineWidth: 1))
                .shadow(color: colorScheme == .dark ? .black.opacity(0.4) : .black.opacity(0.08), radius: 6, x: 0, y: 3)
        }
    }
}

struct AdaptiveListRow: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var themeManager: AppTheme

    func body(content: Content) -> some View {
        content
            .listRowBackground(themeManager.isGamified ? GameColor.darkSurface : Color.adaptiveSecondaryBackground)
            .foregroundColor(themeManager.isGamified ? .white : .primary)
    }
}

extension View {
    func adaptiveCard(color: Color? = nil) -> some View {
        self.modifier(AdaptiveCard(color: color))
    }
    
    func adaptiveListRow() -> some View {
        self.modifier(AdaptiveListRow())
    }
}
