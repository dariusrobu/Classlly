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

enum GameMode: String, CaseIterable, Identifiable, Codable {
    // ⚠️ Renamed 'none' to 'standard' to avoid conflict with Optional.none
    case standard = "Standard"
    case arcade = "Arcade"
    case rainbow = "Rainbow"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .standard: return "Clean academic focus"
        case .arcade: return "Modern gaming hub with neon vibes"
        case .rainbow: return "Vibrant gradients based on your theme"
        }
    }
    
    var iconName: String {
        switch self {
        case .standard: return "book.closed.fill"
        case .arcade: return "gamecontroller.fill"
        case .rainbow: return "paintpalette.fill"
        }
    }
}

class AppTheme: ObservableObject {
    static let shared = AppTheme()
    
    // ✅ Centralized Dark Mode state
    @Published var darkModeEnabled: Bool = UserDefaults.standard.bool(forKey: "darkModeEnabled") {
        didSet {
            UserDefaults.standard.set(darkModeEnabled, forKey: "darkModeEnabled")
        }
    }
    
    @Published var selectedTheme: Theme = .classicBlue {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: "selectedTheme")
        }
    }
    
    // Default to .standard (was .none)
    @Published var selectedGameMode: GameMode = .standard {
        didSet {
            UserDefaults.standard.set(selectedGameMode.rawValue, forKey: "selectedGameMode")
        }
    }
    
    init() {
        self.darkModeEnabled = UserDefaults.standard.bool(forKey: "darkModeEnabled")
        
        let storedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? Theme.classicBlue.rawValue
        self.selectedTheme = Theme(rawValue: storedTheme) ?? .classicBlue
        
        let storedMode = UserDefaults.standard.string(forKey: "selectedGameMode") ?? GameMode.standard.rawValue
        
        // Handle migration from old names if necessary
        if storedMode == "Retro" || storedMode == "Standard" {
            self.selectedGameMode = .standard
        } else {
            self.selectedGameMode = GameMode(rawValue: storedMode) ?? .standard
        }
    }
    
    func setTheme(_ theme: Theme) {
        selectedTheme = theme
    }
}
