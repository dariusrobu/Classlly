import SwiftUI
import SwiftData

// MARK: - Enums
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

// MARK: - Data Models

@Model
final class StudentProfile {
    var id: String = ""
    var firstName: String = ""
    var lastName: String = ""
    var email: String? = nil
    var schoolName: String = ""
    var gradeLevel: String = ""
    var major: String? = nil
    var academicYear: String = ""
    
    init(id: String, firstName: String, lastName: String, email: String? = nil, schoolName: String = "", gradeLevel: String = "", major: String? = nil, academicYear: String = "") {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.schoolName = schoolName
        self.gradeLevel = gradeLevel
        self.major = major
        self.academicYear = academicYear
    }
    
    func toUserProfile() -> UserProfile {
        UserProfile(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: email,
            schoolName: schoolName,
            gradeLevel: gradeLevel,
            major: major,
            academicYear: academicYear,
            profileImageData: nil
        )
    }
}

@Model
final class GradeEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var grade: Double = 0.0
    var descriptionText: String = ""
    
    var subject: Subject?
    
    init(id: UUID = UUID(), date: Date = Date(), grade: Double, description: String = "") {
        self.id = id
        self.date = date
        self.grade = grade
        self.descriptionText = description
    }
}

@Model
final class AttendanceEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var attended: Bool = false
    var notes: String = ""
    
    var subject: Subject?
    
    init(id: UUID = UUID(), date: Date = Date(), attended: Bool, notes: String = "") {
        self.id = id
        self.date = date
        self.attended = attended
        self.notes = notes
    }
}

@Model
final class Subject {
    var id: UUID = UUID()
    var title: String = ""
    
    var courseTeacher: String = ""
    var courseClassroom: String = ""
    var courseDate: Date = Date()
    var courseStartTime: Date = Date()
    var courseEndTime: Date = Date()
    
    // FIX: Store [Int] as String to avoid Core Data materialization errors
    var courseDaysRaw: String = ""
    
    // FIX: Computed property handles conversion [Int] <-> String
    @Transient
    var courseDays: [Int] {
        get {
            guard !courseDaysRaw.isEmpty else { return [] }
            return courseDaysRaw.split(separator: ",").compactMap { Int($0) }
        }
        set {
            courseDaysRaw = newValue.map { String($0) }.joined(separator: ",")
        }
    }
    
    var courseFrequencyRaw: String = ClassFrequency.weekly.rawValue
    
    @Transient
    var courseFrequency: ClassFrequency {
        get { ClassFrequency(rawValue: courseFrequencyRaw) ?? .weekly }
        set { courseFrequencyRaw = newValue.rawValue }
    }
    
    var seminarTeacher: String = ""
    var seminarClassroom: String = ""
    var seminarDate: Date = Date()
    var seminarStartTime: Date = Date()
    var seminarEndTime: Date = Date()
    
    // FIX: Store [Int] as String
    var seminarDaysRaw: String = ""
    
    // FIX: Computed property handles conversion [Int] <-> String
    @Transient
    var seminarDays: [Int] {
        get {
            guard !seminarDaysRaw.isEmpty else { return [] }
            return seminarDaysRaw.split(separator: ",").compactMap { Int($0) }
        }
        set {
            seminarDaysRaw = newValue.map { String($0) }.joined(separator: ",")
        }
    }
    
    var seminarFrequencyRaw: String = ClassFrequency.weekly.rawValue
    
    @Transient
    var seminarFrequency: ClassFrequency {
        get { ClassFrequency(rawValue: seminarFrequencyRaw) ?? .weekly }
        set { seminarFrequencyRaw = newValue.rawValue }
    }
    
    @Relationship(deleteRule: .cascade, inverse: \GradeEntry.subject)
    var gradeHistory: [GradeEntry]? = []
    
    @Relationship(deleteRule: .cascade, inverse: \AttendanceEntry.subject)
    var attendanceHistory: [AttendanceEntry]? = []

    @Relationship(deleteRule: .cascade, inverse: \StudyTask.subject)
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
         seminarFrequency: ClassFrequency = .weekly,
         gradeHistory: [GradeEntry] = [],
         attendanceHistory: [AttendanceEntry] = []) {
        self.id = id
        self.title = title
        self.courseTeacher = courseTeacher
        self.courseClassroom = courseClassroom
        self.courseDate = courseDate
        self.courseStartTime = courseStartTime
        self.courseEndTime = courseEndTime
        
        // Init raw value for days
        self.courseDaysRaw = courseDays.map { String($0) }.joined(separator: ",")
        
        self.courseFrequencyRaw = courseFrequency.rawValue
        self.seminarTeacher = seminarTeacher
        self.seminarClassroom = seminarClassroom
        self.seminarDate = seminarDate
        self.seminarStartTime = seminarStartTime
        self.seminarEndTime = seminarEndTime
        
        // Init raw value for days
        self.seminarDaysRaw = seminarDays.map { String($0) }.joined(separator: ",")
        
        self.seminarFrequencyRaw = seminarFrequency.rawValue
        self.gradeHistory = gradeHistory
        self.attendanceHistory = attendanceHistory
    }
    
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
        (gradeHistory ?? []).last?.grade
    }
    
    var attendanceRate: Double {
        let history = attendanceHistory ?? []
        guard !history.isEmpty else { return 1.0 }
        let attendedCount = history.filter { $0.attended }.count
        return Double(attendedCount) / Double(history.count)
    }
    
    var totalClasses: Int {
        (attendanceHistory ?? []).count
    }
    
    var attendedClasses: Int {
        (attendanceHistory ?? []).filter { $0.attended }.count
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

@Model
final class StudyTask {
    var id: UUID = UUID()
    var title: String = ""
    var isCompleted: Bool = false
    var dueDate: Date? = nil
    
    var priorityRaw: String = TaskPriority.medium.rawValue
    
    @Transient
    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }
    
    var reminderTimeRaw: String = TaskReminderTime.hourBefore1.rawValue
    
    @Transient
    var reminderTime: TaskReminderTime {
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
         isFlagged: Bool = false
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.priorityRaw = priority.rawValue
        self.subject = subject
        self.reminderTimeRaw = reminderTime.rawValue
        self.isFlagged = isFlagged
    }
}

@Model
final class StudyCalendarEvent {
    var id: UUID = UUID()
    var title: String = ""
    var time: String = ""
    var location: String = ""
    var colorName: String = "blue"
    
    var eventTypeRaw: String = EventType.custom.rawValue
    
    @Transient
    var eventType: EventType {
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
