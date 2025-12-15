// MARK: - Game Mode Options
enum GameMode: String, CaseIterable, Identifiable, Codable {
case none = "Standard"
    case rainbow = "Rainbow"
case arcade = "Arcade"
    case retro = "Retro"
    case rainbow = "Rainbow" // NEW

var id: String { self.rawValue }

var description: String {
switch self {
case .none: return "Clean academic focus"
        case .arcade: return "Modern gaming hub with neon vibes"
        case .retro: return "Old-school 8-bit RPG style"
case .rainbow: return "Vibrant gradients based on your theme"
        case .arcade: return "Modern gaming hub with neon vibes"
}
}

var iconName: String {
switch self {
case .none: return "book.closed.fill"
        case .arcade: return "gamecontroller.fill"
        case .retro: return "square.grid.2x2.fill"
case .rainbow: return "paintpalette.fill"
        case .arcade: return "gamecontroller.fill"
}
}
}
@@ -96,6 +93,7 @@ class AppTheme: ObservableObject {
self.selectedTheme = Theme(rawValue: storedTheme) ?? .classicBlue

let storedMode = UserDefaults.standard.string(forKey: "selectedGameMode") ?? GameMode.none.rawValue
        // Fallback to Standard if the stored mode (e.g. Retro) no longer exists
self.selectedGameMode = GameMode(rawValue: storedMode) ?? .none
}
