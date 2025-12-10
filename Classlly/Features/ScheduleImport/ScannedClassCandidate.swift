import Foundation
import SwiftUI

enum ClassType: String, Codable, CaseIterable {
    case course = "Course"
    case seminar = "Seminar"
    case lab = "Lab"
    case online = "Online"
}

struct ScannedClassCandidate: Identifiable, Equatable {
    let id = UUID()
    
    // Raw Data
    let rawText: String
    
    // Extracted Fields
    var day: String = "Monday" // Default
    var startTime: Date
    var endTime: Date
    var title: String
    var room: String = ""
    var teacher: String = ""
    var type: ClassType = .course
    var weekRestriction: String = "" // e.g., "Odd Weeks", "S1"
    var isOptional: Bool = false
    
    // State
    var isSelected: Bool = true
    var hasConflict: Bool = false
    
    // Helper for UI
    var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return "\(f.string(from: startTime)) - \(f.string(from: endTime))"
    }
}
