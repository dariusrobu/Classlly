import Foundation
import SwiftData
import SwiftUI

@Model
final class Subject {
    var id: String = UUID().uuidString
    var title: String = ""
    var code: String = ""
    var colorHex: String = "#0000FF"
    var icon: String = "book.fill"
    var credits: Int = 3
    
    // Course Details
    var courseTeacher: String = ""
    var courseClassroom: String = ""
    var courseDays: [Int] = [] // 1=Sun, 2=Mon...
    var courseFrequency: ClassFrequency = ClassFrequency.weekly
    var courseStartTime: Date? = nil
    var courseEndTime: Date? = nil
    
    // Seminar Details
    var hasSeminar: Bool = false
    var seminarTeacher: String = ""
    var seminarClassroom: String = ""
    var seminarDays: [Int] = []
    var seminarFrequency: ClassFrequency = ClassFrequency.weekly
    var seminarStartTime: Date? = nil
    var seminarEndTime: Date? = nil
    
    // Relationships
    @Relationship(deleteRule: .cascade) var tasks: [StudyTask]? = []
    @Relationship(deleteRule: .cascade) var grades: [GradeEntry]? = []
    @Relationship(deleteRule: .cascade) var attendance: [AttendanceEntry]? = []
    
    // Computed Color
    var color: Color {
        Color(hex: colorHex)
    }
    
    // Computed Helpers
    var courseDaysString: String { daysToString(courseDays) }
    var seminarDaysString: String { daysToString(seminarDays) }
    var courseTimeString: String { timeRangeString(start: courseStartTime, end: courseEndTime) }
    var seminarTimeString: String { timeRangeString(start: seminarStartTime, end: seminarEndTime) }
    
    // Statistics
    var currentGrade: Double? {
        guard let grades = grades, !grades.isEmpty else { return nil }
        let totalWeight = grades.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else { return nil }
        let weightedSum = grades.reduce(0) { $0 + ($1.score * $1.weight) }
        return weightedSum / totalWeight
    }
    
    var attendanceRate: Double {
        guard let attendance = attendance, !attendance.isEmpty else { return 1.0 }
        let total = attendance.count
        let present = attendance.filter { $0.status == .present || $0.status == .late }.count
        return Double(present) / Double(total)
    }
    
    // UI Helpers
    var attendedClasses: Int {
        attendance?.filter { $0.status == .present || $0.status == .late }.count ?? 0
    }
    
    var totalClasses: Int {
        attendance?.count ?? 0
    }

    init(
        id: String = UUID().uuidString,
        title: String,
        code: String = "",
        colorHex: String = "#0000FF",
        icon: String = "book.fill",
        credits: Int = 3,
        courseTeacher: String = "",
        courseClassroom: String = "",
        courseDays: [Int] = [],
        courseFrequency: ClassFrequency = .weekly,
        courseStartTime: Date? = nil,
        courseEndTime: Date? = nil,
        hasSeminar: Bool = false,
        seminarTeacher: String = "",
        seminarClassroom: String = "",
        seminarDays: [Int] = [],
        seminarFrequency: ClassFrequency = .weekly,
        seminarStartTime: Date? = nil,
        seminarEndTime: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.code = code
        self.colorHex = colorHex
        self.icon = icon
        self.credits = credits
        self.courseTeacher = courseTeacher
        self.courseClassroom = courseClassroom
        self.courseDays = courseDays
        self.courseFrequency = courseFrequency
        self.courseStartTime = courseStartTime
        self.courseEndTime = courseEndTime
        self.hasSeminar = hasSeminar
        self.seminarTeacher = seminarTeacher
        self.seminarClassroom = seminarClassroom
        self.seminarDays = seminarDays
        self.seminarFrequency = seminarFrequency
        self.seminarStartTime = seminarStartTime
        self.seminarEndTime = seminarEndTime
    }
    
    private func daysToString(_ days: [Int]) -> String {
        if days.isEmpty { return "TBA" }
        let weekdaySymbols = Calendar.current.shortWeekdaySymbols
        return days.map { weekdaySymbols[($0 - 1) % 7] }.joined(separator: ", ")
    }
    
    private func timeRangeString(start: Date?, end: Date?) -> String {
        guard let s = start, let e = end else { return "TBA" }
        let f = DateFormatter(); f.timeStyle = .short
        return "\(f.string(from: s)) - \(f.string(from: e))"
    }
}
