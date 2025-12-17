import SwiftUI
import Foundation

enum ClassFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweeklyOdd = "Bi-weekly (Odd Weeks)"   // Added
    case biweeklyEven = "Bi-weekly (Even Weeks)" // Added
    case oneTime = "One Time"
    case custom = "Custom"
}

enum TaskPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var color: Color {
        switch self {
        case .low: return .themeSuccess
        case .medium: return .themeAccent
        case .high: return .themeError
        }
    }
    
    var iconName: String {
        switch self {
        case .low: return "arrow.down"
        case .medium: return "minus"
        case .high: return "exclamationmark"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .low: return "arrow.down.circle.fill"
        case .medium: return "minus.circle.fill"
        case .high: return "exclamationmark.circle.fill"
        }
    }
}
