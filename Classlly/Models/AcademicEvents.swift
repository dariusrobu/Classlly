import SwiftUI
import SwiftData

// MARK: - 🗓️ EVENT TYPE ENUM
// This is the source of truth for event types across the app
enum EventType: String, CaseIterable, Codable, Identifiable {
    case teaching = "Teaching"
    case holiday = "Holiday"
    case exam = "Exam"
    case assessment = "Assessment"
    case social = "Social"
    case administrative = "Administrative" // ✅ ADDED THIS
    case other = "Other"
    
    var id: String { self.rawValue }
    
    var displayName: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .teaching: return "book.fill"
        case .holiday: return "sun.max.fill"
        case .exam: return "doc.text.fill"
        case .assessment: return "pencil.and.outline"
        case .social: return "person.2.fill"
        case .administrative: return "building.columns.fill" // ✅ ADDED THIS
        case .other: return "calendar"
        }
    }
    
    var color: Color {
        switch self {
        case .teaching: return .blue
        case .holiday: return .green
        case .exam: return .red
        case .assessment: return .orange
        case .social: return .purple
        case .administrative: return .indigo // ✅ ADDED THIS
        case .other: return .gray
        }
    }
}

// MARK: - 📦 ACADEMIC EVENT DATA
struct AcademicEventData: Identifiable, Codable {
    var id: UUID
    var start: String // Format: yyyy-MM-dd
    var end: String   // Format: yyyy-MM-dd
    var type: EventType
    var weeks: Int
    var customName: String?
    
    var teachingWeekIndexStart: Int?
    var teachingWeekIndexEnd: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, start, end, type, weeks, customName, teachingWeekIndexStart, teachingWeekIndexEnd
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.start = try container.decode(String.self, forKey: .start)
        self.end = try container.decode(String.self, forKey: .end)
        self.type = try container.decode(EventType.self, forKey: .type)
        self.weeks = try container.decode(Int.self, forKey: .weeks)
        self.customName = try container.decodeIfPresent(String.self, forKey: .customName)
        self.teachingWeekIndexStart = try container.decodeIfPresent(Int.self, forKey: .teachingWeekIndexStart)
        self.teachingWeekIndexEnd = try container.decodeIfPresent(Int.self, forKey: .teachingWeekIndexEnd)
    }
    
    // Manual init for local creation
    init(id: UUID = UUID(), start: String, end: String, type: EventType, weeks: Int, customName: String? = nil, teachingWeekIndexStart: Int? = nil, teachingWeekIndexEnd: Int? = nil) {
        self.id = id
        self.start = start
        self.end = end
        self.type = type
        self.weeks = weeks
        self.customName = customName
        self.teachingWeekIndexStart = teachingWeekIndexStart
        self.teachingWeekIndexEnd = teachingWeekIndexEnd
    }
}

// MARK: - 📅 CALENDAR STRUCTURES
struct SemesterData: Codable {
    var events: [AcademicEventData]
}

struct AcademicCalendarData: Identifiable, Codable {
    var id = UUID()
    var academicYear: String
    var universityName: String?
    var customName: String?
    var semester1: SemesterData
    var semester2: SemesterData
}

struct CalendarTemplate: Identifiable {
    let id: UUID = UUID()
    let universityName: String
    let academicYear: String
    let sem1Start: String
    let sem1End: String
    let sem2Start: String
    let sem2End: String
}

// MARK: - 💾 STUDY CALENDAR EVENT (SwiftData Model)
@Model
final class StudyCalendarEvent {
    var id: UUID = UUID()
    var title: String = ""
    var time: String = ""
    var location: String = ""
    var colorName: String = "blue"
    
    var eventTypeRaw: String = EventType.other.rawValue
    
    @Transient var eventType: EventType {
        get { EventType(rawValue: eventTypeRaw) ?? .other }
        set { eventTypeRaw = newValue.rawValue }
    }
    
    var taskId: UUID?
    var subjectId: UUID?
    
    init(id: UUID = UUID(), title: String, time: String, location: String, colorName: String = "blue", eventType: EventType = .other, taskId: UUID? = nil, subjectId: UUID? = nil) {
        self.id = id
        self.title = title
        self.time = time
        self.location = location
        self.colorName = colorName
        self.eventTypeRaw = eventType.rawValue
        self.taskId = taskId
        self.subjectId = subjectId
    }
    
    var color: Color {
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        case "yellow": return .yellow
        case "teal": return .teal
        default: return .blue
        }
    }
}
