import SwiftUI
import Combine

// MARK: - Game Mode Options
enum GameMode: String, CaseIterable, Identifiable, Codable {
    case none = "Standard"
    case arcade = "Arcade"
    case retro = "Retro" // NEW: Added Retro option
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .none: return "Clean academic focus"
        case .arcade: return "Modern gaming hub with neon vibes"
        case .retro: return "Old-school 8-bit RPG style"
        }
    }
    
    var iconName: String {
        switch self {
        case .none: return "book.closed.fill"
        case .arcade: return "gamecontroller.fill"
        case .retro: return "square.grid.2x2.fill"
        }
    }
}

// MARK: - Theme Options
enum Theme: String, CaseIterable, Identifiable {
    // Blue Nuances
    case classicBlue = "Classic Blue"
    case oceanTeal = "Ocean Teal"
    case navyNight = "Navy Night"
    
    // Green Nuances
    case forestGreen = "Forest Green"
    case mintLeaf = "Mint Leaf"
    
    // Warm Nuances
    case sunsetOrange = "Sunset Orange"
    case coralRed = "Coral Red"
    case berryPink = "Berry Pink"
    
    // Purple Nuances
    case royalPurple = "Royal Purple"
    case lavenderDream = "Lavender Dream"
    
    var id: String { self.rawValue }
    
    // Returns the primary accent color for the theme
    var primaryColor: Color {
        switch self {
        case .classicBlue: return Color.blue
        case .oceanTeal: return Color.teal
        case .navyNight: return Color.indigo
            
        case .forestGreen: return Color.green
        case .mintLeaf: return Color(red: 0.4, green: 0.8, blue: 0.6)
            
        case .sunsetOrange: return Color.orange
        case .coralRed: return Color.red
        case .berryPink: return Color.pink
            
        case .royalPurple: return Color.purple
        case .lavenderDream: return Color(red: 0.6, green: 0.4, blue: 0.8)
        }
    }
    
    var secondaryColor: Color {
        return primaryColor.opacity(0.8)
    }
}

// MARK: - App Theme Manager
class AppTheme: ObservableObject {
    // Singleton instance allows static access in Color+Theme.swift
    static let shared = AppTheme()
    
    // We use @Published with a didSet to save to UserDefaults manually.
    @Published var selectedTheme: Theme {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: "selectedTheme")
        }
    }
    
    // NEW: Game Mode State
    @Published var selectedGameMode: GameMode {
        didSet {
            UserDefaults.standard.set(selectedGameMode.rawValue, forKey: "selectedGameMode")
        }
    }
    
    init() {
        // Load theme from UserDefaults on init
        let storedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? Theme.classicBlue.rawValue
        self.selectedTheme = Theme(rawValue: storedTheme) ?? .classicBlue
        
        // Load Game Mode
        let storedMode = UserDefaults.standard.string(forKey: "selectedGameMode") ?? GameMode.none.rawValue
        self.selectedGameMode = GameMode(rawValue: storedMode) ?? .none
    }
    
    // Call this to change the theme
    func setTheme(_ theme: Theme) {
        self.selectedTheme = theme
        // UI update is triggered automatically by @Published
    }
    
    func setGameMode(_ mode: GameMode) {
        self.selectedGameMode = mode
    }
}
