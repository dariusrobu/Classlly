import SwiftUI
import Combine

// 1. Define the Theme options with "Fancy" names
enum Theme: String, CaseIterable, Identifiable {
    case cyberBlue = "Cyber Blue"
    case toxicGreen = "Toxic Green"
    case neonPurple = "Neon Purple"
    case solarOrange = "Solar Orange"
    case hotPink = "Hot Pink"
    case electricTeal = "Electric Teal"
    
    var id: String { self.rawValue }
    
    // 2. Define vibrant, neon accent colors
    var accentColor: Color {
        switch self {
        case .cyberBlue:
            return Color(red: 0.0, green: 0.75, blue: 1.0) // Bright Cyan-Blue
        case .toxicGreen:
            return Color(red: 0.2, green: 0.9, blue: 0.4) // Vibrant Lime
        case .neonPurple:
            return Color(red: 0.7, green: 0.2, blue: 1.0) // Deep Violet
        case .solarOrange:
            return Color(red: 1.0, green: 0.5, blue: 0.0) // Bright Amber
        case .hotPink:
            return Color(red: 1.0, green: 0.2, blue: 0.6) // Magenta
        case .electricTeal:
            return Color(red: 0.0, green: 0.9, blue: 0.8) // Cyan-Teal
        }
    }
    
    // Secondary color for gradients (slightly darker/shifted)
    var secondaryColor: Color {
        switch self {
        case .cyberBlue: return Color(red: 0.0, green: 0.3, blue: 0.8)
        case .toxicGreen: return Color(red: 0.0, green: 0.6, blue: 0.2)
        case .neonPurple: return Color(red: 0.5, green: 0.0, blue: 0.8)
        case .solarOrange: return Color(red: 0.8, green: 0.2, blue: 0.0)
        case .hotPink: return Color(red: 0.8, green: 0.0, blue: 0.4)
        case .electricTeal: return Color(red: 0.0, green: 0.5, blue: 0.6)
        }
    }
}

class AppTheme: ObservableObject {
    private let keyTheme = "selectedTheme"
    private let keyGamified = "isGamified"
    
    @Published var selectedTheme: Theme = .cyberBlue {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: keyTheme)
        }
    }
    
    @Published var isGamified: Bool = false {
        didSet {
            UserDefaults.standard.set(isGamified, forKey: keyGamified)
        }
    }
    
    init() {
        let themeVal = UserDefaults.standard.string(forKey: keyTheme) ?? Theme.cyberBlue.rawValue
        self.selectedTheme = Theme(rawValue: themeVal) ?? .cyberBlue
        self.isGamified = UserDefaults.standard.bool(forKey: keyGamified)
    }
}
