// File: Classlly/Models/DataModels.swift
// Note: This is the FINAL corrected file. All custom init() methods
// have been REMOVED. The @Model macro will now correctly
// synthesize the initializers, which resolves all errors.

import SwiftUI
import SwiftData

// (ClassFrequency enum is unchanged)
enum ClassFrequency: String, CaseIterable, Codable {
    case weekly = "Weekly"
    case biweeklyOdd = "Bi-Weekly (Odd Weeks)"
    case biweeklyEven = "Bi-Weekly (Even Weeks)"
    
    var description: String { return self.rawValue }
    
    var iconName: String {
        switch self {
        case .weekly: return "repeat"
        case .biweeklyOdd: return "arrow.2.squarepath"
        case .biweeklyEven: return "arrow.2.squarepath"
        }
    }
}

// (TaskReminderTime enum is unchanged)
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
    
    // (reminderDate func is unchanged)
    func reminderDate(from dueDate: Date) -> Date? {
        switch self {
        case .none:
            return nil
        case .onTime:
            return dueDate
        case .minutesBefore5:
            return Calendar.current.date(byAdding: .minute, value: -5, to: dueDate)
        case .minutesBefore15:
            return Calendar.current.date(byAdding: .minute, value: -15, to: dueDate)
        case .minutesBefore30:
            return Calendar.current.date(byAdding: .minute, value: -30, to: dueDate)
        case .hourBefore1:
            return Calendar.current.date(byAdding: .hour, value: -1, to: dueDate)
        case .hoursBefore2:
            return Calendar.current.date(byAdding: .hour, value: -2, to: dueDate)
        case .dayBefore1:
            return Calendar.current.date(byAdding: .day, value: -1, to: dueDate)
        case .weekBefore1:
            return Calendar.current.date(byAdding: .weekOfYear, value: -1, to: dueDate)
        }
    }
}

@Model
final class GradeEntry {
    @Attribute(.unique) var id: UUID = UUID()
    var date: Date = Date()
    var grade: Double = 0.0
    var descriptionText: String = ""
    @Relationship var subject: Subject?
    
    // --- FIX: REMOVED ALL custom init() methods ---
}

@Model
final class AttendanceEntry {
    @Attribute(.unique) var id: UUID = UUID()
    var date: Date = Date()
    var attended: Bool = false
    var notes: String = ""
    @Relationship var subject: Subject?
    
    // --- FIX: REMOVED ALL custom init() methods ---
}

@Model
final class Subject {
    @Attribute(.unique) var id: UUID = UUID()
    var title: String = ""
    var courseTeacher: String = ""
    var courseClassroom: String = ""
    var courseDate: Date = Date()
    var courseStartTime: Date = Date()
    var courseEndTime: Date = Date()
    var courseDays: [Int] = []
    var courseFrequency: ClassFrequency = ClassFrequency.weekly
    
    var seminarTeacher: String = ""
    var seminarClassroom: String = ""
    var seminarDate: Date = Date()
    var seminarStartTime: Date = Date()
    var seminarEndTime: Date = Date()
    var seminarDays: [Int] = []
    var seminarFrequency: ClassFrequency = ClassFrequency.weekly
    
    @Relationship(deleteRule: .cascade, inverse: \GradeEntry.subject)
    var gradeHistory: [GradeEntry] = []
    
    @Relationship(deleteRule: .cascade, inverse: \AttendanceEntry.subject)
    var attendanceHistory: [AttendanceEntry] = []

    @Relationship(deleteRule: .cascade, inverse: \StudyTask.subject)
    var tasks: [StudyTask] = []
    
    // --- FIX: REMOVED ALL custom init() methods ---
    
    // (Computed properties are unchanged)
    var courseTimeString: String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        return "\(timeFormatter.string(from: courseStartTime))-\(timeFormatter.string(from: courseEndTime))"
    }
    
    var courseDaysString: String {
        let daySymbols = Calendar.current.shortWeekdaySymbols
        return courseDays.map { daySymbols[$0 - 1] }.joined(separator: ", ")
    }
    
    var courseFrequencyString: String {
        return courseFrequency.rawValue
    }
    
    var seminarTimeString: String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        return "\(timeFormatter.string(from: seminarStartTime))-\(timeFormatter.string(from: seminarEndTime))"
    }
    
    var seminarDaysString: String {
        let daySymbols = Calendar.current.shortWeekdaySymbols
        return seminarDays.map { daySymbols[$0 - 1] }.joined(separator: ", ")
    }
        
    var seminarFrequencyString: String {
        return seminarFrequency.rawValue
    }
    
    var currentGrade: Double? {
        gradeHistory.last?.grade
    }
    
    var attendanceRate: Double {
        guard !attendanceHistory.isEmpty else { return 1.0 }
        let attendedCount = attendanceHistory.filter { $0.attended }.count
        return Double(attendedCount) / Double(attendanceHistory.count)
    }
    
    var totalClasses: Int {
        attendanceHistory.count
    }
    
    var attendedClasses: Int {
        attendanceHistory.filter { $0.attended }.count
    }
    
    func occursThisWeek(academicWeek: Int?, isCourse: Bool = true) -> Bool {
        guard let academicWeek = academicWeek else {
            return false
        }
        let frequency = isCourse ? courseFrequency : seminarFrequency
        switch frequency {
        case .weekly:
            return true
        case .biweeklyOdd:
            return academicWeek % 2 == 1
        case .biweeklyEven:
            return academicWeek % 2 == 0
        }
    }
}

// MARK: - StudyTask Model
@Model
final class StudyTask {
    @Attribute(.unique) var id: UUID = UUID()
    var title: String = ""
    var isCompleted: Bool = false
    var dueDate: Date?
    var priority: TaskPriority = TaskPriority.medium
    @Relationship var subject: Subject?
    var reminderTime: TaskReminderTime = TaskReminderTime.none
    var isFlagged: Bool = false

    // --- FIX: REMOVED ALL custom init() methods ---
}

// MARK: - TaskPriority Enum
enum TaskPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var color: Color {
        switch self {
        case .low:
            return .themeSuccess
        case .medium:
            return .themeAccent
        case .high:
            return .themeError
        }
    }
    
    var iconName: String {
        switch self {
        case .low: return "arrow.down"
        case .medium: return "minus"
        case .high: return "exclamationmark"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .low: return "arrow.down.circle.fill"
        case .medium: return "minus.circle.fill"
        case .high: return "exclamationmark.circle.fill"
        }
    }
}

// MARK: - StudyCalendarEvent Model
@Model
final class StudyCalendarEvent {
    @Attribute(.unique) var id: UUID = UUID()
    var title: String = ""
    var time: String = ""
    var location: String = ""
    var colorName: String = "blue"
    var eventType: EventType = StudyCalendarEvent.EventType.custom
    
    var taskId: UUID?
    var subjectId: UUID?
    
    enum EventType: String, Codable {
        case task = "task"
        case classEvent = "class"
        case exam = "exam"
        case custom = "custom"
    }
    
    // --- FIX: REMOVED ALL custom init() methods ---

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
