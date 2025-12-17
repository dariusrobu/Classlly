import Foundation
import SwiftData
import SwiftUI

@Model
final class Subject {
    var id: UUID
    var title: String
    var colorHex: String
    var ectsCredits: Int
    
    // MARK: - Course Details
    var courseTeacher: String
    var courseClassroom: String
    var courseFrequency: ClassFrequency
    var courseStartTime: Date
    var courseEndTime: Date
    var courseDays: [Int] // 1=Sun, 2=Mon... (Standard Calendar)
    
    // MARK: - Seminar Details
    var hasSeminar: Bool
    var seminarTeacher: String
    var seminarClassroom: String
    var seminarFrequency: ClassFrequency
    var seminarStartTime: Date
    var seminarEndTime: Date
    var seminarDays: [Int]
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \GradeEntry.subject)
    var grades: [GradeEntry] = []
    
    @Relationship(deleteRule: .cascade, inverse: \AttendanceEntry.subject)
    var attendance: [AttendanceEntry] = []

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
        guard !grades.isEmpty else { return nil }
        
        let validGrades = grades
        let totalWeight = validGrades.reduce(0.0) { $0 + $1.weight }
        
        guard totalWeight > 0 else { return nil }
        
        let weightedSum = validGrades.reduce(0.0) { $0 + ($1.score * $1.weight) }
        return weightedSum / totalWeight
    }
    
    // MARK: - UI Helpers (Fix for SharedComponents)
    
    var courseDaysString: String {
        let days = courseDays.sorted()
        let symbols = Calendar.current.shortWeekdaySymbols
        // Calendar.component(.weekday) returns 1 for Sunday.
        // Symbols array is 0-indexed: 0=Sun, 1=Mon, etc.
        return days.map { day in
            let index = (day - 1) % 7
            return symbols[safe: index] ?? "?"
        }.joined(separator: ", ")
    }
    
    var courseTimeString: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return "\(f.string(from: courseStartTime)) - \(f.string(from: courseEndTime))"
    }
    
    var attendedClasses: Int {
        return attendance.filter { $0.status == .present || $0.status == .late }.count
    }
    
    var totalClasses: Int {
        return attendance.count
    }
    
    var attendanceRate: Double {
        guard totalClasses > 0 else { return 0.0 }
        return Double(attendedClasses) / Double(totalClasses)
    }
    
    var gradeHistory: [GradeEntry]? {
        return grades.sorted { $0.date > $1.date }
    }
}

// Safe index extension to prevent crashes
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
