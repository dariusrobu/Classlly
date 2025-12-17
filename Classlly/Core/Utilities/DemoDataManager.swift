import Foundation
import SwiftData

class DemoDataManager {
    static let shared = DemoDataManager()
    
    // Standard Demo Data
    func createDemoData(modelContext: ModelContext) {
        // 1. Math
        let math = Subject(
            title: "Advanced Calculus",
            colorHex: "FF3B30",
            ectsCredits: 5,
            courseTeacher: "Dr. Newton",
            courseClassroom: "Hall A",
            courseFrequency: .weekly,
            courseStartTime: Date(),
            courseEndTime: Date().addingTimeInterval(7200),
            courseDays: [1, 3] // Mon, Wed
        )
        
        // 2. Physics
        let physics = Subject(
            title: "Quantum Physics",
            colorHex: "5856D6",
            ectsCredits: 6,
            courseTeacher: "Dr. Bohr",
            courseClassroom: "Lab 4",
            courseFrequency: .weekly,
            courseStartTime: Date(),
            courseEndTime: Date().addingTimeInterval(5400),
            courseDays: [2, 4] // Tue, Thu
        )
        
        modelContext.insert(math)
        modelContext.insert(physics)
        
        // Add Grades
        let mathGrade1 = GradeEntry(title: "Quiz 1", score: 18, maxScore: 20, date: Date().addingTimeInterval(-86400 * 10))
        let mathGrade2 = GradeEntry(title: "Midterm", score: 88, maxScore: 100, date: Date().addingTimeInterval(-86400 * 5))
        
        math.grades.append(mathGrade1)
        math.grades.append(mathGrade2)
        
        // Add Attendance
        for i in 1...5 {
            let entryDate = Date().addingTimeInterval(Double(-i * 86400 * 7))
            let status: AttendanceStatus = (i % 4 == 0) ? .absent : .present
            let note: String? = (status == .absent) ? "Sick leave" : nil
            
            let entry = AttendanceEntry(date: entryDate, status: status, note: note)
            math.attendance.append(entry)
        }
    }
    
    // MARK: - Stress Test Data
    // Creates a "Heavy" schedule with many subjects and entries
    func createHeavyStressData(modelContext: ModelContext) {
        let subjects = [
            ("Data Structures", "007AFF", [1, 3]),
            ("Algorithms", "5856D6", [2, 4]),
            ("Operating Systems", "FF9500", [1, 5]),
            ("Linear Algebra", "FF2D55", [2]),
            ("Software Engineering", "34C759", [3, 5]),
            ("Databases", "AF52DE", [4]),
            ("Web Development", "5AC8FA", [1]),
            ("Mobile Computing", "FFCC00", [5])
        ]
        
        for (name, color, days) in subjects {
            let subject = Subject(
                title: name,
                colorHex: color,
                ectsCredits: Int.random(in: 4...8),
                courseTeacher: "Prof. Simulator",
                courseClassroom: "Room \(Int.random(in: 100...400))",
                courseFrequency: .weekly,
                courseStartTime: Date(), // Times would ideally be staggered
                courseEndTime: Date().addingTimeInterval(5400),
                courseDays: days
            )
            
            modelContext.insert(subject)
            
            // Add 10 random grades per subject
            for j in 1...10 {
                let score = Double.random(in: 50...100)
                let grade = GradeEntry(
                    title: "Assignment \(j)",
                    score: score,
                    maxScore: 100,
                    date: Date().addingTimeInterval(Double(-j * 86400 * 3))
                )
                subject.grades.append(grade)
            }
            
            // Add 20 attendance records
            for k in 1...20 {
                let status: AttendanceStatus = Bool.random() ? .present : .absent
                let att = AttendanceEntry(
                    date: Date().addingTimeInterval(Double(-k * 86400 * 2)),
                    status: status
                )
                subject.attendance.append(att)
            }
        }
    }
}
