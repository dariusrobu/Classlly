import Foundation
import SwiftUI

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
    
    // ✅ FIX: Uses the shared enum from Enums.swift
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
