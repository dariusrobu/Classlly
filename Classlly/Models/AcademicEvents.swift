import SwiftUI
import SwiftData

@Model
final class StudyCalendarEvent {
    var id: UUID = UUID()
    var title: String = ""
    var time: String = ""
    var location: String = ""
    var colorName: String = "blue"
    
    var eventTypeRaw: String = EventType.custom.rawValue
    @Transient var eventType: EventType {
        get { EventType(rawValue: eventTypeRaw) ?? .custom }
        set { eventTypeRaw = newValue.rawValue }
    }
    
    var taskId: UUID?
    var subjectId: UUID?
    
    enum EventType: String, Codable {
        case task = "task"
        case classEvent = "class"
        case exam = "exam"
        case custom = "custom"
    }
    
    init(id: UUID = UUID(), title: String, time: String, location: String, colorName: String = "blue", eventType: EventType = .custom, taskId: UUID? = nil, subjectId: UUID? = nil) {
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
        case "blue": return .themePrimary
        case "green": return .themeSuccess
        case "red": return .themeError
        case "orange": return .themeAccent
        case "purple": return .themeSecondary
        case "yellow": return .yellow
        case "pink": return .themeAccent
        case "teal": return .themeSecondary
        default: return .themePrimary
        }
    }
}
