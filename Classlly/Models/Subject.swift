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
    var courseDays: [Int] // 1=Mon, 2=Tue...
    
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
    
    // Universal Fix: We cast to 'Color?' first.
    // This works whether Color(hex:) returns 'Color' or 'Color?'.
    var color: Color {
        return (Color(hex: colorHex) as Color?) ?? .blue
    }
}
