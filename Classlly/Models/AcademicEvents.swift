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
        case .other: return .gray
        }
    }
}

// MARK: - 📦 ACADEMIC EVENT DATA
struct AcademicEventData: Identifiable, Codable {
    var id: UUID = UUID()
    var start: String // Format: yyyy-MM-dd
    var end: String   // Format: yyyy-MM-dd
    var type: EventType
    var weeks: Int
    var customName: String?
    
    var teachingWeekIndexStart: Int?
    var teachingWeekIndexEnd: Int?
    
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
    var academicYear: String // e.g., "2024-2025"
    var universityName: String?
    var customName: String?
    var semester1: SemesterData
    var semester2: SemesterData
}

struct CalendarTemplate: Identifiable {
    let id: UUID = UUID()
    let universityName: String
    let academicYear: String
    let sem1Start: String // yyyy-MM-dd
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
    
    // Stores the raw string value
    var eventTypeRaw: String = EventType.other.rawValue
    
    // ✅ FIXED: Uses the GLOBAL EventType (teaching, holiday, etc.)
    @Transient var eventType: EventType {
        get { EventType(rawValue: eventTypeRaw) ?? .other }
        set { eventTypeRaw = newValue.rawValue }
    }
    
    var taskId: UUID?
    var subjectId: UUID?
    
    // ✅ REMOVED: The conflicting nested 'enum EventType' was deleted.
    // If you need a secondary type, name it 'SourceType' or similar, do not name it EventType.
    
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
