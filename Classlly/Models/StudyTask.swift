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
    
    // MARK: - Storage
    // Changed to String to prevent CloudKit crash (Handles both "1" and "High" legacy data)
    var priorityRaw: String = "1"
    var reminderTimeRaw: String = TaskReminderTime.hourBefore1.rawValue
    
    var isFlagged: Bool = false
    var subject: Subject?

    @Transient var priority: TaskPriority {
        get {
            // 1. Try to initialize from the stored String (if it's a stringified Int like "1")
            if let intValue = Int(priorityRaw), let priority = TaskPriority(rawValue: intValue) {
                return priority
            }
            
            // 2. Fallback for legacy data (if CloudKit has "High", "Medium", "Low")
            switch priorityRaw.lowercased() {
            case "high": return .high
            case "medium": return .medium
            case "low": return .low
            default: return .medium
            }
        }
        set {
            // Store the Int rawValue as a String
            priorityRaw = String(newValue.rawValue)
        }
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
        // Save as String
        self.priorityRaw = String(priority.rawValue)
        self.subject = subject
        self.reminderTimeRaw = reminderTime.rawValue
        self.isFlagged = isFlagged
        self.notes = notes
    }
}
