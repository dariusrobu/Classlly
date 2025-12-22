import SwiftUI

// MARK: - Class Frequency
enum ClassFrequency: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case biweeklyOdd = "Bi-Weekly (Odd)"  // Week 1, 3, 5...
    case biweeklyEven = "Bi-Weekly (Even)" // Week 2, 4, 6...
    case oneTime = "One-Time"
}

// MARK: - Task Priority
enum TaskPriority: Int, Codable, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2
    
    var title: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
    
    var color: Color {
        // Safe colors that don't rely on external theme files if those aren't shared
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
}

// MARK: - Reminder Time
enum TaskReminderTime: String, CaseIterable, Codable {
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

// MARK: - Class Type
enum ClassType: String, Codable, CaseIterable {
    case course = "Course"
    case seminar = "Seminar"
    case lab = "Lab"
    case online = "Online"
    
    var displayName: String {
        return self.rawValue
    }
    
    var color: Color {
        switch self {
        case .course: return .blue
        case .seminar: return .orange
        case .lab: return .green
        case .online: return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .course: return "book.fill"
        case .seminar: return "person.2.fill"
        case .lab: return "flask.fill"
        case .online: return "laptopcomputer"
        }
    }
}

// MARK: - Task Type
enum TaskType: String, Codable, CaseIterable {
    case task = "Task"
    case homework = "Homework"
    case project = "Project"
    case quiz = "Quiz"
    case exam = "Exam"
    case presentation = "Presentation"
    
    var icon: String {
        switch self {
        case .task: return "checklist"
        case .homework: return "doc.text.fill"
        case .project: return "folder.fill"
        case .quiz: return "pencil.and.outline"
        case .exam: return "graduationcap.fill"
        case .presentation: return "person.wave.2.fill"
        }
    }
    
    // Logic for what appears in Exam Radar
    var isExamRadar: Bool {
        return self == .exam || self == .quiz
    }
}
