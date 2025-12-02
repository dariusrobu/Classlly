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
        case .blue:
            return .blue
        case .green:
            return .green
        case .purple:
            return .purple
        case .orange:
            return .orange
        }
    }
}

// 3. Create an ObservableObject to manage the theme
class AppTheme: ObservableObject {
    // 4. @AppStorage works perfectly fine here
    @AppStorage("selectedTheme") private var selectedThemeRawValue: String = Theme.blue.rawValue
    
    // 5. Publish the selected theme
    @Published var selectedTheme: Theme {
        didSet {
            selectedThemeRawValue = selectedTheme.rawValue
        }
    }
    
    // --- THIS IS THE FIX ---
    init() {
        // Manually read the value from UserDefaults to avoid the "self" error
        let storedValue = UserDefaults.standard.string(forKey: "selectedTheme") ?? Theme.blue.rawValue
        let themeFromStorage = Theme(rawValue: storedValue) ?? .blue
        
        // Initialize the @Published property's wrapped value
        _selectedTheme = Published(initialValue: themeFromStorage)
    }
    // --- END OF FIX ---
}
