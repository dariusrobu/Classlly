import Foundation
import SwiftUI

enum ClassType: String, Codable, CaseIterable {
    case course = "Course"
    case seminar = "Seminar"
    case lab = "Lab"
    case online = "Online"
    
    var color: Color {
        switch self {
        case .course: return .blue
        case .seminar: return .green
        case .lab: return .orange
        case .online: return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .course: return "book.fill"
        case .seminar: return "person.2.fill"
        case .lab: return "flask.fill"
        case .online: return "laptopcomputer"
        }
    }
}

struct ScannedClassCandidate: Identifiable, Equatable {
    let id = UUID()
    
    // Raw Data (Legacy OCR text, unused with Gemini but kept for model compatibility)
    var rawText: String = ""
    
    // Extracted Fields
    var day: String = "Monday"
    var startTime: Date
    var endTime: Date
    var title: String
    var room: String = ""
    var teacher: String = ""
    var type: ClassType = .course
    var weekRestriction: String = "" // e.g., "Odd Weeks", "S1"
    var isOptional: Bool = false
    
    // State for the Review UI
    var isSelected: Bool = true
    var hasConflict: Bool = false
    
    // Helper for UI
    var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return "\(f.string(from: startTime)) - \(f.string(from: endTime))"
    }
}
