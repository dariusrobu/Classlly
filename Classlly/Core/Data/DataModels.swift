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

// MARK: - Calendar Data Structures (Moved here for Widget Access)

struct CalendarTemplate: Identifiable, Hashable {
    let id = UUID()
    var universityName: String
    var academicYear: String
    var sem1StartStr: String
    var sem1EndStr: String
    var sem2StartStr: String
    var sem2EndStr: String
}

enum EventType: String, CaseIterable, Codable {
    case teaching = "teaching"
    case breakType = "break"
    case exam = "exam"
    case holiday = "holiday"
    case retake = "retake"
    case practice = "practice"
    case licensure = "licensure"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .teaching: return "Teaching"
        case .breakType: return "Break"
        case .exam: return "Exam Session"
        case .holiday: return "Holiday"
        case .retake: return "Retake Session"
        case .practice: return "Practical Training"
        case .licensure: return "Licensure Exam"
        case .other: return "Other"
        }
    }
    
    var iconName: String {
        switch self {
        case .teaching: return "book.fill"
        case .breakType: return "beach.umbrella.fill"
        case .exam: return "pencil.and.outline"
        case .holiday: return "gift.fill"
        case .retake: return "arrow.triangle.2.circlepath"
        case .practice: return "hammer.fill"
        case .licensure: return "graduationcap.fill"
        case .other: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .teaching: return .themePrimary
        case .breakType: return .themeSuccess
        case .exam: return .themeError
        case .holiday: return .themeAccent
        case .retake: return .orange
        case .practice: return .purple
        case .licensure: return .yellow
        case .other: return .themeSecondary
        }
    }
}

struct AcademicEventData: Identifiable, Codable, Equatable {
    let id: UUID
    var start: String
    var end: String
    var type: EventType
    var weeks: Int
    var teachingWeekIndexStart: Int?
    var teachingWeekIndexEnd: Int?
    var customName: String?
    
    init(id: UUID = UUID(), start: String, end: String, type: EventType, weeks: Int, teachingWeekIndexStart: Int? = nil, teachingWeekIndexEnd: Int? = nil, customName: String? = nil) {
        self.id = id
        self.start = start
        self.end = end
        self.type = type
        self.weeks = weeks
        self.teachingWeekIndexStart = teachingWeekIndexStart
        self.teachingWeekIndexEnd = teachingWeekIndexEnd
        self.customName = customName
    }
}

struct SemesterData: Codable, Equatable {
    var events: [AcademicEventData]
    init(events: [AcademicEventData] = []) { self.events = events }
}

struct AcademicCalendarData: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var academicYear: String
    var semester1: SemesterData
    var semester2: SemesterData
    var universityName: String?
    var customName: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case academicYear = "academic_year"
        case semester1 = "semester_1"
        case semester2 = "semester_2"
        case universityName = "university_name"
        case customName = "custom_name"
    }
    
    init(id: UUID = UUID(), academicYear: String, semester1: SemesterData = SemesterData(), semester2: SemesterData = SemesterData(), universityName: String? = nil, customName: String? = nil) {
        self.id = id
        self.academicYear = academicYear
        self.semester1 = semester1
        self.semester2 = semester2
        self.universityName = universityName
        self.customName = customName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let decodedId = try container.decodeIfPresent(UUID.self, forKey: .id) {
            self.id = decodedId
        } else {
            self.id = UUID()
        }
        self.academicYear = try container.decode(String.self, forKey: .academicYear)
        self.semester1 = try container.decode(SemesterData.self, forKey: .semester1)
        self.semester2 = try container.decode(SemesterData.self, forKey: .semester2)
        self.universityName = try container.decodeIfPresent(String.self, forKey: .universityName)
        self.customName = try container.decodeIfPresent(String.self, forKey: .customName)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(academicYear, forKey: .academicYear)
        try container.encode(semester1, forKey: .semester1)
        try container.encode(semester2, forKey: .semester2)
        try container.encode(universityName, forKey: .universityName)
        try container.encode(customName, forKey: .customName)
    }
}

// MARK: - SwiftData Models

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
        return courseDays.map { daySymbols[$0 - 1] }.joined(separator: ", ")
    }
    
    var courseFrequencyString: String { courseFrequency.rawValue }
    
    var seminarTimeString: String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        return "\(timeFormatter.string(from: seminarStartTime))-\(timeFormatter.string(from: seminarEndTime))"
    }
    
    var seminarDaysString: String {
        let daySymbols = Calendar.current.shortWeekdaySymbols
        return seminarDays.map { daySymbols[$0 - 1] }.joined(separator: ", ")
    }
    
    var seminarFrequencyString: String { seminarFrequency.rawValue }
    
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
        guard let academicWeek = academicWeek else { return false }
        let frequency = isCourse ? courseFrequency : seminarFrequency
        switch frequency {
        case .weekly: return true
        case .biweeklyOdd: return academicWeek % 2 == 1
        case .biweeklyEven: return academicWeek % 2 == 0
        }
    }
}

@Model
final class StudyTask {
    var id: UUID = UUID()
    var title: String = ""
    var isCompleted: Bool = false
    var dueDate: Date?
    var priority: TaskPriority = TaskPriority.medium
    var subject: Subject?
    var reminderTime: TaskReminderTime = TaskReminderTime.none
    var isFlagged: Bool = false

    init(id: UUID = UUID(),
         title: String,
         isCompleted: Bool = false,
         dueDate: Date? = nil,
         priority: TaskPriority = .medium,
         subject: Subject? = nil,
         reminderTime: TaskReminderTime = .hourBefore1,
         isFlagged: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.priority = priority
        self.subject = subject
        self.reminderTime = reminderTime
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
    var eventType: EventType = StudyCalendarEvent.EventType.custom
    
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
