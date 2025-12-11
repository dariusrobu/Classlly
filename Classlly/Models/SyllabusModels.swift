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
    var id: UUID = UUID()
    var title: String = ""
    var date: Date = Date()
    var type: String = "General"
    var isCompleted: Bool = false
    var courseName: String? = nil
    
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
        dateFormatter.timeZone = TimeZone.current
        
        return events.compactMap { event in
            guard let validDate = dateFormatter.date(from: event.date) else {
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
