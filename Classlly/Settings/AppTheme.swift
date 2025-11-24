import SwiftUI
import Combine

// 1. Define the Theme options
enum Theme: String, CaseIterable, Identifiable {
    case blue = "Default Blue"
    case green = "Forest Green"
    case purple = "Deep Purple"
    case orange = "Sunset Orange"
    
    var id: String { self.rawValue }
    
    // Primary accent for Buttons/Tabs (Single Color)
    var accentColor: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .purple: return .purple
        case .orange: return .orange
        }
    }
    
    // --- NEW: Curated Gradients for Gamified Mode ---
    // These are softer and more pleasing to the eye
    var gamifiedGradient: [Color] {
        switch self {
        case .blue:
            return [Color.blue, Color.cyan] // Ocean Breeze
        case .green:
            return [Color.green, Color.mint] // Fresh Mint
        case .purple:
            return [Color.purple, Color.pink] // Neon Vapor
        case .orange:
            return [Color.orange, Color.yellow] // Sunset Glow
        }
    }
}

// 3. Create an ObservableObject to manage the theme
class AppTheme: ObservableObject {
    @AppStorage("selectedTheme") private var selectedThemeRawValue: String = Theme.blue.rawValue
    
    @Published var isGamifiedMode: Bool {
        didSet {
            UserDefaults.standard.set(isGamifiedMode, forKey: "isGamifiedMode")
        }
    }
    
    @Published var selectedTheme: Theme {
        didSet {
            selectedThemeRawValue = selectedTheme.rawValue
        }
    }
    
    init() {
        let storedValue = UserDefaults.standard.string(forKey: "selectedTheme") ?? Theme.blue.rawValue
        let themeFromStorage = Theme(rawValue: storedValue) ?? .blue
        let storedGamified = UserDefaults.standard.bool(forKey: "isGamifiedMode")
        
        self.selectedTheme = themeFromStorage
        self.isGamifiedMode = storedGamified
    }
}
