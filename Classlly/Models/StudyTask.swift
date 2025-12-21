import Foundation
import SwiftData

@Model
final class StudyTask {
    var id: String = UUID().uuidString
    var title: String = ""
    var isCompleted: Bool = false
    var dueDate: Date? = nil
    
    // Properties required by @Model
    var priority: TaskPriority = TaskPriority.medium
    var type: TaskType = TaskType.task
    
    // ✅ NEW: Added Reminder Time (Required for NotificationManager)
    var reminderTime: TaskReminderTime = TaskReminderTime.none
    
    var notes: String = ""
    var isFlagged: Bool = false
    
    // Relationships
    var subject: Subject?
    
    init(
        id: String = UUID().uuidString,
        title: String,
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        priority: TaskPriority = .medium,
        type: TaskType = .task,
        reminderTime: TaskReminderTime = .none, // ✅ Added to Init
        subject: Subject? = nil,
        isFlagged: Bool = false,
        notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.priority = priority
        self.type = type
        self.reminderTime = reminderTime
        self.subject = subject
        self.isFlagged = isFlagged
        self.notes = notes
    }
}
