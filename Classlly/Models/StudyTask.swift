import SwiftUI
import SwiftData

enum TaskReminderTime: String, CaseIterable, Codable, Hashable {
    case none = "No Reminder"
    case onTime = "At time of event"
    case minutesBefore5 = "5 minutes before"
    case minutesBefore15 = "15 minutes before"
    case minutesBefore30 = "30 minutes before"
    case hourBefore1 = "1 hour before"
    case hoursBefore2 = "2 hours before"
    case dayBefore1 = "1 day before"
    case weekBefore1 = "1 week before"
    
    func reminderDate(from dueDate: Date) -> Date? {
        switch self {
        case .none: return nil
        case .onTime: return dueDate
        case .minutesBefore5: return Calendar.current.date(byAdding: .minute, value: -5, to: dueDate)
        case .minutesBefore15: return Calendar.current.date(byAdding: .minute, value: -15, to: dueDate)
        case .minutesBefore30: return Calendar.current.date(byAdding: .minute, value: -30, to: dueDate)
        case .hourBefore1: return Calendar.current.date(byAdding: .hour, value: -1, to: dueDate)
        case .hoursBefore2: return Calendar.current.date(byAdding: .hour, value: -2, to: dueDate)
        case .dayBefore1: return Calendar.current.date(byAdding: .day, value: -1, to: dueDate)
        case .weekBefore1: return Calendar.current.date(byAdding: .weekOfYear, value: -1, to: dueDate)
        }
    }
}

@Model
final class StudyTask {
    var id: UUID = UUID()
    var title: String = ""
    var isCompleted: Bool = false
    var dueDate: Date? = nil
    var notes: String = "" // Added notes field
    
    var priorityRaw: String = TaskPriority.medium.rawValue
    @Transient var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }
    
    var reminderTimeRaw: String = TaskReminderTime.hourBefore1.rawValue
    @Transient var reminderTime: TaskReminderTime {
        get { TaskReminderTime(rawValue: reminderTimeRaw) ?? .hourBefore1 }
        set { reminderTimeRaw = newValue.rawValue }
    }
    
    var isFlagged: Bool = false
    var subject: Subject?

    init(id: UUID = UUID(),
         title: String,
         isCompleted: Bool = false,
         dueDate: Date? = nil,
         priority: TaskPriority = .medium,
         subject: Subject? = nil,
         reminderTime: TaskReminderTime = .hourBefore1,
         isFlagged: Bool = false,
         notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.priorityRaw = priority.rawValue
        self.subject = subject
        self.reminderTimeRaw = reminderTime.rawValue
        self.isFlagged = isFlagged
        self.notes = notes
    }
}
