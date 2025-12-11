import SwiftUI
import Combine

// MARK: - Game Mode Options
enum GameMode: String, CaseIterable, Identifiable, Codable {
    case none = "Standard"
    case rainbow = "Rainbow"
    case arcade = "Arcade"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .none: return "Clean academic focus"
        case .rainbow: return "Vibrant gradients based on your theme"
        case .arcade: return "Modern gaming hub with neon vibes"
        }
    }
    
    var iconName: String {
        switch self {
        case .none: return "book.closed.fill"
        case .rainbow: return "paintpalette.fill"
        case .arcade: return "gamecontroller.fill"
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
    static let shared = AppTheme()
    
    @Published var selectedTheme: Theme {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: "selectedTheme")
        }
    }
    
    @Published var selectedGameMode: GameMode {
        didSet {
            UserDefaults.standard.set(selectedGameMode.rawValue, forKey: "selectedGameMode")
        }
    }
    
    init() {
        let storedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? Theme.classicBlue.rawValue
        self.selectedTheme = Theme(rawValue: storedTheme) ?? .classicBlue
        
        let storedMode = UserDefaults.standard.string(forKey: "selectedGameMode") ?? GameMode.none.rawValue
        // Fallback to Standard if the stored mode (e.g. Retro) no longer exists
        self.selectedGameMode = GameMode(rawValue: storedMode) ?? .none
    }
    
    func setTheme(_ theme: Theme) {
        self.selectedTheme = theme
    }
    
    func setGameMode(_ mode: GameMode) {
        self.selectedGameMode = mode
    }
}
