import SwiftUI

// MARK: - Themed Card Wrapper
// A simple wrapper that applies the global .adaptiveCard() modifier
struct ThemedCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .adaptiveCard() // Uses the new logic from Color+Theme.swift
    }
}

// MARK: - Themed Button
// A button that adapts to the Gamified/Standard mode automatically
struct ThemedButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(.white) // Text is always white for primary buttons
            .background(
                Group {
                    if themeManager.isGamified {
                        // Gamified: Use a cool neon gradient (Electric Blue by default for generic buttons)
                        GameGradient.linear(base: GameColor.electricBlue)
                    } else {
                        // Standard: Use the user's selected theme color
                        themeManager.selectedTheme.accentColor
                    }
                }
            )
            .cornerRadius(16)
            .overlay(
                // Add the neon border in Gamified mode
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(themeManager.isGamified ? 0.2 : 0), lineWidth: 1)
            )
            .shadow(
                color: themeManager.isGamified ? GameColor.electricBlue.opacity(0.4) : Color.black.opacity(0.05),
                radius: themeManager.isGamified ? 8 : 2,
                x: 0,
                y: themeManager.isGamified ? 4 : 1
            )
        }
    }
}

// MARK: - Preview
struct ThemedComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ThemedCard {
                Text("I am an Adaptive Card")
                    .padding()
            }
            
            ThemedButton(title: "Click Me", icon: "star.fill") {}
        }
        .padding()
        .environmentObject(AppTheme())
    }
}
