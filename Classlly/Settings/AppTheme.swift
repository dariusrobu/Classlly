import SwiftUI
import Combine

enum Theme: String, CaseIterable, Identifiable {
    case blue = "Default Blue"
    case green = "Forest Green"
    case purple = "Deep Purple"
    case orange = "Sunset Orange"
    
    var id: String { self.rawValue }
    
    var accentColor: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .purple: return .purple
        case .orange: return .orange
        }
    }
}

class AppTheme: ObservableObject {
    @AppStorage("selectedTheme") private var selectedThemeRawValue: String = Theme.blue.rawValue
    @AppStorage("isGamified") var isGamified: Bool = false
    
    @Published var selectedTheme: Theme {
        didSet {
            selectedThemeRawValue = selectedTheme.rawValue
        }
    }
    
    init() {
        let storedValue = UserDefaults.standard.string(forKey: "selectedTheme") ?? Theme.blue.rawValue
        let themeFromStorage = Theme(rawValue: storedValue) ?? .blue
        _selectedTheme = Published(initialValue: themeFromStorage)
    }
}
