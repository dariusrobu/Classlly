import SwiftUI
import SwiftData

@Model
final class Subject {
    var id: UUID = UUID()
    var title: String = ""
    
    // Course Details
    var courseTeacher: String = ""
    var courseClassroom: String = ""
    var courseDate: Date = Date()
    var courseStartTime: Date = Date()
    var courseEndTime: Date = Date()
    
    var courseDaysRaw: String = ""
    @Transient var courseDays: [Int] {
        get {
            guard !courseDaysRaw.isEmpty else { return [] }
            return courseDaysRaw.split(separator: ",").compactMap { Int($0) }
        }
        set { courseDaysRaw = newValue.map { String($0) }.joined(separator: ",") }
    }
    
    var courseFrequencyRaw: String = ClassFrequency.weekly.rawValue
    @Transient var courseFrequency: ClassFrequency {
        get { ClassFrequency(rawValue: courseFrequencyRaw) ?? .weekly }
        set { courseFrequencyRaw = newValue.rawValue }
    }
    
    // Seminar Details
    var seminarTeacher: String = ""
    var seminarClassroom: String = ""
    var seminarDate: Date = Date()
    var seminarStartTime: Date = Date()
    var seminarEndTime: Date = Date()
    
    var seminarDaysRaw: String = ""
    @Transient var seminarDays: [Int] {
        get {
            guard !seminarDaysRaw.isEmpty else { return [] }
            return seminarDaysRaw.split(separator: ",").compactMap { Int($0) }
        }
        set { seminarDaysRaw = newValue.map { String($0) }.joined(separator: ",") }
    }
    
    var seminarFrequencyRaw: String = ClassFrequency.weekly.rawValue
    @Transient var seminarFrequency: ClassFrequency {
        get { ClassFrequency(rawValue: seminarFrequencyRaw) ?? .weekly }
        set { seminarFrequencyRaw = newValue.rawValue }
    }
    
    // Relationships
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
        self.courseDaysRaw = courseDays.map { String($0) }.joined(separator: ",")
        self.courseFrequencyRaw = courseFrequency.rawValue
        self.seminarTeacher = seminarTeacher
        self.seminarClassroom = seminarClassroom
        self.seminarDate = seminarDate
        self.seminarStartTime = seminarStartTime
        self.seminarEndTime = seminarEndTime
        self.seminarDaysRaw = seminarDays.map { String($0) }.joined(separator: ",")
        self.seminarFrequencyRaw = seminarFrequency.rawValue
        self.gradeHistory = gradeHistory
        self.attendanceHistory = attendanceHistory
    }
    
    // MARK: - Computed Helpers
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
    
    // Points to the weighted average logic
    var currentGrade: Double? {
        return weightedAverage
    }
    
    // The Logic for Weighted Grades
    var weightedAverage: Double? {
        guard let grades = gradeHistory, !grades.isEmpty else { return nil }
        
        let totalWeight = grades.reduce(0.0) { $0 + $1.weight }
        guard totalWeight > 0 else { return nil }
        
        let weightedSum = grades.reduce(0.0) { $0 + ($1.grade * $1.weight) }
        return weightedSum / totalWeight
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
final class GradeEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var grade: Double = 0.0
    var weight: Double = 100.0 // Default weight (e.g. 100%)
    var descriptionText: String = ""
    var isExam: Bool = false // New Property
    var subject: Subject?
    
    init(id: UUID = UUID(), date: Date = Date(), grade: Double, weight: Double = 100.0, description: String = "", isExam: Bool = false) {
        self.id = id
        self.date = date
        self.grade = grade
        self.weight = weight
        self.descriptionText = description
        self.isExam = isExam
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
