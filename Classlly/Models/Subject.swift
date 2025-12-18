import Foundation
import SwiftData
import SwiftUI

@Model
final class Subject {
    var id: UUID = UUID()
    var title: String = ""
    var colorHex: String = "007AFF"
    var ectsCredits: Int = 0
    
    // MARK: - Course Details
    var courseTeacher: String = ""
    var courseClassroom: String = ""
    
    // ✅ FIX: Fully qualified default value for SwiftData macro
    var courseFrequency: ClassFrequency = ClassFrequency.weekly
    
    var courseStartTime: Date = Date()
    var courseEndTime: Date = Date().addingTimeInterval(3600)
    var courseDays: [Int] = []
    
    // MARK: - Seminar Details
    var hasSeminar: Bool = false
    var seminarTeacher: String = ""
    var seminarClassroom: String = ""
    
    // ✅ FIX: Fully qualified default value
    var seminarFrequency: ClassFrequency = ClassFrequency.weekly
    
    var seminarStartTime: Date = Date()
    var seminarEndTime: Date = Date().addingTimeInterval(3600)
    var seminarDays: [Int] = []
    
    // MARK: - Relationships
    @Relationship(deleteRule: .cascade, inverse: \GradeEntry.subject)
    var grades: [GradeEntry]? = []
    
    @Relationship(deleteRule: .cascade, inverse: \AttendanceEntry.subject)
    var attendance: [AttendanceEntry]? = []
    
    @Relationship(deleteRule: .cascade, inverse: \StudyTask.subject)
    var tasks: [StudyTask]? = []

    init(
        title: String,
        colorHex: String = "007AFF",
        ectsCredits: Int = 0,
        
        courseTeacher: String = "",
        courseClassroom: String = "",
        courseFrequency: ClassFrequency = .weekly,
        courseStartTime: Date = Date(),
        courseEndTime: Date = Date().addingTimeInterval(3600),
        courseDays: [Int] = [],
        
        hasSeminar: Bool = false,
        seminarTeacher: String = "",
        seminarClassroom: String = "",
        seminarFrequency: ClassFrequency = .weekly,
        seminarStartTime: Date = Date(),
        seminarEndTime: Date = Date().addingTimeInterval(3600),
        seminarDays: [Int] = []
    ) {
        self.id = UUID()
        self.title = title
        self.colorHex = colorHex
        self.ectsCredits = ectsCredits
        
        self.courseTeacher = courseTeacher
        self.courseClassroom = courseClassroom
        self.courseFrequency = courseFrequency
        self.courseStartTime = courseStartTime
        self.courseEndTime = courseEndTime
        self.courseDays = courseDays
        
        self.hasSeminar = hasSeminar
        self.seminarTeacher = seminarTeacher
        self.seminarClassroom = seminarClassroom
        self.seminarFrequency = seminarFrequency
        self.seminarStartTime = seminarStartTime
        self.seminarEndTime = seminarEndTime
        self.seminarDays = seminarDays
    }
    
    // MARK: - Computed Properties
    var color: Color {
        return (Color(hex: colorHex) as Color?) ?? .blue
    }
    
    var currentGrade: Double? {
        guard let grades = grades, !grades.isEmpty else { return nil }
        let totalWeight = grades.reduce(0.0) { $0 + $1.weight }
        guard totalWeight > 0 else { return nil }
        let weightedSum = grades.reduce(0.0) { $0 + ($1.score * $1.weight) }
        return weightedSum / totalWeight
    }
    
    // MARK: - UI Helpers
    
    // ✅ Added Missing Helpers
    var courseDaysString: String {
        formatDays(courseDays)
    }
    
    var seminarDaysString: String {
        formatDays(seminarDays)
    }
    
    var courseTimeString: String {
        formatTimeRange(start: courseStartTime, end: courseEndTime)
    }
    
    var seminarTimeString: String {
        formatTimeRange(start: seminarStartTime, end: seminarEndTime)
    }
    
    var attendedClasses: Int {
        return attendance?.filter { $0.status == .present || $0.status == .late }.count ?? 0
    }
    
    var totalClasses: Int {
        return attendance?.count ?? 0
    }
    
    var attendanceRate: Double {
        guard totalClasses > 0 else { return 0.0 }
        return Double(attendedClasses) / Double(totalClasses)
    }
    
    var gradeHistory: [GradeEntry]? {
        return grades?.sorted { $0.date > $1.date }
    }
    
    // Helpers
    private func formatDays(_ days: [Int]) -> String {
        let sorted = days.sorted()
        let symbols = Calendar.current.shortWeekdaySymbols
        return sorted.map { day in
            let index = (day - 1) % 7
            return symbols[safe: index] ?? "?"
        }.joined(separator: ", ")
    }
    
    private func formatTimeRange(start: Date, end: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return "\(f.string(from: start)) - \(f.string(from: end))"
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
