import SwiftUI
import Combine

// 1. Define the Theme options
enum Theme: String, CaseIterable, Identifiable {
    case blue = "Default Blue"
    case green = "Forest Green"
    case purple = "Deep Purple"
    case orange = "Sunset Orange"
    
    var id: String { self.rawValue }
    
    // 2. Define the primary accent color for each theme
    var accentColor: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .purple: return .purple
        case .orange: return .orange
        }
    }
}

// 3. Create an ObservableObject to manage the theme
class AppTheme: ObservableObject {
    @AppStorage("selectedTheme") private var selectedThemeRawValue: String = Theme.blue.rawValue
    
    @Published var selectedTheme: Theme
    
    init() {
        let storedValue = UserDefaults.standard.string(forKey: "selectedTheme") ?? Theme.blue.rawValue
        let themeFromStorage = Theme(rawValue: storedValue) ?? .blue
        _selectedTheme = Published(initialValue: themeFromStorage)
    }
    
    func updateTheme(_ theme: Theme) {
        selectedTheme = theme
        selectedThemeRawValue = theme.rawValue
    }
}
