import SwiftUI
import SwiftData

// MARK: - Enums (Codable for CloudKit)

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

enum TaskPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var color: Color {
        switch self {
        case .low: return .themeSuccess
        case .medium: return .themeAccent
        case .high: return .themeError
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

// MARK: - Models

// 1. GradeEntry
@Model
final class GradeEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var grade: Double
    var weight: Double
    var descriptionText: String
    
    @Relationship(inverse: \Subject.gradeHistory)
    var subject: Subject?
    
    init(id: UUID = UUID(), date: Date = Date(), grade: Double, weight: Double = 100.0, description: String = "") {
        self.id = id
        self.date = date
        self.grade = grade
        self.weight = weight
        self.descriptionText = description
    }
}

// 2. AttendanceEntry
@Model
final class AttendanceEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var attended: Bool
    var notes: String
    
    @Relationship(inverse: \Subject.attendanceHistory)
    var subject: Subject?
    
    init(id: UUID = UUID(), date: Date = Date(), attended: Bool, notes: String = "") {
        self.id = id
        self.date = date
        self.attended = attended
        self.notes = notes
    }
}

// 3. Subject
@Model
final class Subject {
    @Attribute(.unique) var id: UUID
    var title: String
    var courseTeacher: String
    var courseClassroom: String
    var courseDate: Date
    var courseStartTime: Date
    var courseEndTime: Date
    var courseDays: [Int]
    var courseFrequency: ClassFrequency
    
    var seminarTeacher: String
    var seminarClassroom: String
    var seminarDate: Date
    var seminarStartTime: Date
    var seminarEndTime: Date
    var seminarDays: [Int]
    var seminarFrequency: ClassFrequency
    
    // Relationships must be optional or have default values for CloudKit
    @Relationship(deleteRule: .cascade)
    var gradeHistory: [GradeEntry]? = []
    
    @Relationship(deleteRule: .cascade)
    var attendanceHistory: [AttendanceEntry]? = []

    @Relationship(deleteRule: .cascade)
    var tasks: [StudyTask]? = []
    
    init(id: UUID = UUID(),
         title: String,
         courseTeacher: String,
         courseClassroom: String,
         courseDate: Date = Date(),
         courseStartTime: Date = Date(),
         courseEndTime: Date = Date(),
         courseDays: [Int] = [],
         courseFrequency: ClassFrequency = .weekly,
         seminarTeacher: String,
         seminarClassroom: String,
         seminarDate: Date = Date(),
         seminarStartTime: Date = Date(),
         seminarEndTime: Date = Date(),
         seminarDays: [Int] = [],
         seminarFrequency: ClassFrequency = .weekly) {
        self.id = id
        self.title = title
        self.courseTeacher = courseTeacher
        self.courseClassroom = courseClassroom
        self.courseDate = courseDate
        self.courseStartTime = courseStartTime
        self.courseEndTime = courseEndTime
        self.courseDays = courseDays
        self.courseFrequency = courseFrequency
        self.seminarTeacher = seminarTeacher
        self.seminarClassroom = seminarClassroom
        self.seminarDate = seminarDate
        self.seminarStartTime = seminarStartTime
        self.seminarEndTime = seminarEndTime
        self.seminarDays = seminarDays
        self.seminarFrequency = seminarFrequency
    }
    
    // Computed properties
    var courseTimeString: String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        return "\(timeFormatter.string(from: courseStartTime))-\(timeFormatter.string(from: courseEndTime))"
    }
    
    var courseDaysString: String {
        let daySymbols = Calendar.current.shortWeekdaySymbols
        // Sort Mon (2) -> Sun (1)
        let sortedDays = courseDays.sorted { ($0 == 1 ? 8 : $0) < ($1 == 1 ? 8 : $1) }
        return sortedDays.map { daySymbols[$0 - 1] }.joined(separator: ", ")
    }
    
    var courseFrequencyString: String { courseFrequency.rawValue }
    
    var seminarTimeString: String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        return "\(timeFormatter.string(from: seminarStartTime))-\(timeFormatter.string(from: seminarEndTime))"
    }
    
    var seminarDaysString: String {
        let daySymbols = Calendar.current.shortWeekdaySymbols
        let sortedDays = seminarDays.sorted { ($0 == 1 ? 8 : $0) < ($1 == 1 ? 8 : $1) }
        return sortedDays.map { daySymbols[$0 - 1] }.joined(separator: ", ")
    }
    
    var seminarFrequencyString: String { seminarFrequency.rawValue }
    
    var currentGrade: Double? { gradeHistory?.last?.grade }
    
    var attendanceRate: Double {
        guard let history = attendanceHistory, !history.isEmpty else { return 1.0 }
        let attendedCount = history.filter { $0.attended }.count
        return Double(attendedCount) / Double(history.count)
    }
    
    var totalClasses: Int { attendanceHistory?.count ?? 0 }
    var attendedClasses: Int { attendanceHistory?.filter { $0.attended }.count ?? 0 }
    
    func occursThisWeek(academicWeek: Int?, isCourse: Bool = true) -> Bool {
        guard let academicWeek = academicWeek else { return false }
        let frequency = isCourse ? courseFrequency : seminarFrequency
        switch frequency {
        case .weekly: return true
        case .biweeklyOdd: return academicWeek % 2 == 1
        case .biweeklyEven: return academicWeek % 2 == 0
        }
    }
}

// 4. StudyTask
@Model
final class StudyTask {
    @Attribute(.unique) var id: UUID
    var title: String
    var isCompleted: Bool
    var dueDate: Date?
    var priority: TaskPriority
    var reminderTime: TaskReminderTime
    var isFlagged: Bool
    var notes: String
    
    @Relationship(inverse: \Subject.tasks)
    var subject: Subject?

    init(id: UUID = UUID(),
         title: String,
         isCompleted: Bool = false,
         dueDate: Date? = nil,
         priority: TaskPriority = .medium,
         subject: Subject? = nil,
         reminderTime: TaskReminderTime = .hourBefore1,
         isFlagged: Bool = false,
         notes: String = "") {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.priority = priority
        self.subject = subject
        self.reminderTime = reminderTime
        self.isFlagged = isFlagged
        self.notes = notes
    }
}

// 5. StudyCalendarEvent
@Model
final class StudyCalendarEvent {
    @Attribute(.unique) var id: UUID
    var title: String
    var time: String
    var location: String
    var colorName: String
    var eventType: EventType
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
        self.eventType = eventType
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

// 6. UserProfile (Now a @Model for Cloud Sync)
@Model
final class UserProfile {
    @Attribute(.unique) var id: String
    var firstName: String
    var lastName: String
    var email: String?
    var schoolName: String
    var gradeLevel: String
    var major: String?
    var academicYear: String
    var profileImageData: Data?
    
    init(id: String, firstName: String, lastName: String, email: String?, schoolName: String, gradeLevel: String, major: String?, academicYear: String, profileImageData: Data?) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.schoolName = schoolName
        self.gradeLevel = gradeLevel
        self.major = major
        self.academicYear = academicYear
        self.profileImageData = profileImageData
    }
    
    var fullName: String { "\(firstName) \(lastName)" }
}
