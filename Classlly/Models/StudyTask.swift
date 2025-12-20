import SwiftUI
import SwiftData

// NOTE: Enums (TaskPriority, TaskReminderTime) are defined in Enums.swift
// Ensure Enums.swift has Target Membership checked for BOTH App and Widget.

@Model
final class StudyTask {
    var id: UUID = UUID()
    var title: String = ""
    var isCompleted: Bool = false
    var dueDate: Date? = nil
    var notes: String = ""
    
    // Storage
    var priorityRaw: Int = TaskPriority.medium.rawValue
    var reminderTimeRaw: String = TaskReminderTime.hourBefore1.rawValue
    
    var isFlagged: Bool = false
    var subject: Subject?

    @Transient var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }
    
    @Transient var reminderTime: TaskReminderTime {
        get { TaskReminderTime(rawValue: reminderTimeRaw) ?? .hourBefore1 }
        set { reminderTimeRaw = newValue.rawValue }
    }
    
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
