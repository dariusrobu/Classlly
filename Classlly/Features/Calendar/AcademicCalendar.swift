import Foundation
import SwiftData

/// The primary model for storing Academic Calendars.
/// Uses @Model for SwiftData persistence.
@Model
final class AcademicCalendar {
    @Attribute(.unique) var id: String
    var name: String
    var lastUpdated: Date
    
    // Storing an array of structs requires the struct to be Codable.
    // SwiftData will treat this as a composite attribute, avoiding NSKeyedUnarchiveFromData
    // as long as `CalendarEvent` is strictly Codable and Value types.
    var events: [CalendarEvent]
    
    init(id: String = UUID().uuidString, name: String, events: [CalendarEvent] = []) {
        self.id = id
        self.name = name
        self.lastUpdated = Date()
        self.events = events
    }
}

// MARK: - Codable Conformance
// Ensure this model conforms to Codable to support JSON decoding from the API
extension AcademicCalendar: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case events
        // Exclude lastUpdated if it's not in the JSON, or map it if it is
    }
    
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        let name = try container.decode(String.self, forKey: .name)
        let events = try container.decode([CalendarEvent].self, forKey: .events)
        
        self.init(id: id, name: name, events: events)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(events, forKey: .events)
    }
}

// MARK: - Supporting Types

/// A lightweight struct for events.
/// MUST be Codable to be stored within a SwiftData @Model array without transformers.
struct CalendarEvent: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var startDate: Date
    var endDate: Date
    var category: String // e.g., "Holiday", "Exam", "Course"
    
    init(id: String = UUID().uuidString, title: String, startDate: Date, endDate: Date, category: String) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.category = category
    }
}
