//
//  SyllabusResponse.swift
//  Classlly
//
//  Created by Robu Darius on 11.12.2025.
//


import Foundation
import SwiftData

// MARK: - AI Response Models (Codable)

struct SyllabusResponse: Codable {
    let courseName: String
    let events: [SyllabusEvent]
}

struct SyllabusEvent: Codable {
    let title: String
    let type: String
    let date: String // Format: YYYY-MM-DD
    let weight: Int?
}

// MARK: - SwiftData Model

@Model
final class ClassEvent {
    var id: UUID
    var title: String
    var date: Date
    var type: String // e.g., "Exam", "Assignment", "Quiz"
    var isCompleted: Bool
    var courseName: String? // Optional: Track which course this belongs to
    
    init(title: String, date: Date, type: String, courseName: String? = nil, isCompleted: Bool = false) {
        self.id = UUID()
        self.title = title
        self.date = date
        self.type = type
        self.courseName = courseName
        self.isCompleted = isCompleted
    }
}

// MARK: - Mapping Helper

extension SyllabusResponse {
    func toSwiftDataModels() -> [ClassEvent] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        // Ensure lenient parsing if needed, or set specific time zone
        dateFormatter.timeZone = TimeZone.current
        
        return events.compactMap { event in
            // Guard against invalid dates returned by AI
            guard let validDate = dateFormatter.date(from: event.date) else {
                print("Warning: Failed to parse date string: \(event.date)")
                return nil
            }
            
            return ClassEvent(
                title: event.title,
                date: validDate,
                type: event.type,
                courseName: self.courseName,
                isCompleted: false
            )
        }
    }
}