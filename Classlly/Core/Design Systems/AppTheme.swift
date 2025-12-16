import SwiftUI
import Combine

// MARK: - Theme Options
enum Theme: String, CaseIterable, Identifiable, Codable {
    case classicBlue = "Classic Blue"
    case sunsetOrange = "Sunset Orange"
    case mintGreen = "Mint Green"
    case royalPurple = "Royal Purple"
    
    var id: String { self.rawValue }
    
    var primaryColor: Color {
        switch self {
        case .classicBlue: return Color.blue
        case .sunsetOrange: return Color.orange
        case .mintGreen: return Color.mint
        case .royalPurple: return Color.purple
        }
    }
    
    var secondaryColor: Color {
        switch self {
        case .classicBlue: return Color.cyan
        case .sunsetOrange: return Color.red
        case .mintGreen: return Color.green
        case .royalPurple: return Color.indigo
        }
    }
}

// MARK: - Game Mode Options (Retro Removed)
enum GameMode: String, CaseIterable, Identifiable, Codable {
    case none = "Standard"
    case arcade = "Arcade"
    case rainbow = "Rainbow"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .none: return "Clean academic focus"
        case .arcade: return "Modern gaming hub with neon vibes"
        case .rainbow: return "Vibrant gradients based on your theme"
        }
    }
    
    var iconName: String {
        switch self {
        case .none: return "book.closed.fill"
        case .arcade: return "gamecontroller.fill"
        case .rainbow: return "paintpalette.fill"
        }
    }
}

// MARK: - App Theme Manager
class AppTheme: ObservableObject {
    static let shared = AppTheme()
    
    @Published var selectedTheme: Theme = .classicBlue {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: "selectedTheme")
        }
    }
    
    @Published var selectedGameMode: GameMode = .none {
        didSet {
            UserDefaults.standard.set(selectedGameMode.rawValue, forKey: "selectedGameMode")
        }
    }
    
    init() {
        let storedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? Theme.classicBlue.rawValue
        self.selectedTheme = Theme(rawValue: storedTheme) ?? .classicBlue
        
        let storedMode = UserDefaults.standard.string(forKey: "selectedGameMode") ?? GameMode.none.rawValue
        // Fallback if 'Retro' was previously selected
        if storedMode == "Retro" {
            self.selectedGameMode = .none
        } else {
            self.selectedGameMode = GameMode(rawValue: storedMode) ?? .none
        }
    }
    
    func setTheme(_ theme: Theme) {
        selectedTheme = theme
    }
}
