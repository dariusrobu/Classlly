import SwiftUI

struct GlobalAppThemeModifier: ViewModifier {
    @EnvironmentObject var themeManager: AppTheme
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        ZStack {
            // 1. Global Background Layer
            if themeManager.isGamified {
                GameColor.background.ignoresSafeArea()
            } else {
                Color.themeBackground.ignoresSafeArea()
            }
            
            // 2. Content Layer
            content
                // Force the Tint color globally based on mode
                .tint(themeManager.isGamified ? GameColor.accent : themeManager.selectedTheme.accentColor)
                // Force Dark Mode in Gamified Mode (so system text is white)
                .preferredColorScheme(themeManager.isGamified ? .dark : nil)
        }
    }
}

// Extension for easy usage
extension View {
    func applyAppTheme() -> some View {
        self.modifier(GlobalAppThemeModifier())
    }
}
