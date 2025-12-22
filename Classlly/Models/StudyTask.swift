import Foundation
import SwiftData

@Model
final class StudyTask {
    var id: String = UUID().uuidString
    var title: String = ""
    var isCompleted: Bool = false
    var dueDate: Date? = nil
    
    // ⚠️ STORAGE PROPERTIES
    // We use String for persistence because your CloudKit/CoreData history
    // already contains Strings for these fields.
    // Changing these types to Int/Enum without a complex migration plan will crash the app.
    var priorityRaw: String = "1"
    var typeRaw: String = "Homework"
    var reminderTimeRaw: String = "No Reminder"
    
    var isFlagged: Bool = false
    var notes: String = ""
    
    // RELATIONSHIPS
    var subject: Subject?
    
    // ⚙️ COMPUTED ACCESSORS
    // These provide type-safe access to the underlying String storage
    var priority: TaskPriority {
        get {
            if let intValue = Int(priorityRaw), let match = TaskPriority(rawValue: intValue) {
                return match
            }
            return .medium
        }
        set {
            priorityRaw = String(newValue.rawValue)
        }
    }
    
    var type: TaskType {
        get { TaskType(rawValue: typeRaw) ?? .homework }
        set { typeRaw = newValue.rawValue }
    }
    
    var reminderTime: TaskReminderTime {
        get { TaskReminderTime(rawValue: reminderTimeRaw) ?? .none }
        set { reminderTimeRaw = newValue.rawValue }
    }
    
    init(
        id: String = UUID().uuidString,
        title: String,
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        priority: TaskPriority = .medium,
        type: TaskType = .homework,
        reminderTime: TaskReminderTime = .none,
        subject: Subject? = nil,
        isFlagged: Bool = false,
        notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        
        // Initialize the Raw strings
        self.priorityRaw = String(priority.rawValue)
        self.typeRaw = type.rawValue
        self.reminderTimeRaw = reminderTime.rawValue
        
        self.subject = subject
        self.isFlagged = isFlagged
        self.notes = notes
    }
}
