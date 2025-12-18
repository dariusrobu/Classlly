import Foundation
import SwiftData

class DemoDataManager {
    static let shared = DemoDataManager()
    
    // MARK: - Stress Test Data
    func createHeavyStressData(modelContext: ModelContext) {
        print("⚡️ Starting Stress Data Generation...")
        deleteAllData(modelContext: modelContext)
        
        let subjectsData = [
            ("Data Structures", "007AFF", [1, 3], true),
            ("Algorithms", "5856D6", [2, 4], false),
            ("Operating Systems", "FF9500", [1, 5], true),
            ("Linear Algebra", "FF2D55", [2], false),
            ("Software Engineering", "34C759", [3, 5], true),
            ("Databases", "AF52DE", [4], true),
            ("Web Development", "5AC8FA", [1], false),
            ("Mobile Computing", "FFCC00", [5], true)
        ]
        
        for (name, color, days, hasSeminar) in subjectsData {
            // 2. Create Subject
            let subject = Subject(
                title: name,
                colorHex: color,
                ectsCredits: Int.random(in: 4...8),
                courseTeacher: "Prof. Simulator",
                courseClassroom: "Room \(Int.random(in: 100...400))",
                courseFrequency: .weekly,
                courseStartTime: Date(),
                courseEndTime: Date().addingTimeInterval(5400),
                courseDays: days,
                
                // Set Seminar Data
                hasSeminar: hasSeminar,
                seminarTeacher: hasSeminar ? "Dr. Assistant" : "",
                seminarClassroom: hasSeminar ? "Lab \(Int.random(in: 1...10))" : "",
                seminarFrequency: .weekly,
                seminarStartTime: Date().addingTimeInterval(7200),
                seminarEndTime: Date().addingTimeInterval(9000),
                seminarDays: hasSeminar ? [days.first! + 1] : []
            )
            
            modelContext.insert(subject)
            
            // 3. Add Grades (Past)
            for j in 1...8 {
                let score = Double.random(in: 5...10)
                // ✅ Fix: Removed 'description', passed 'isExam: false'
                let grade = GradeEntry(
                    title: "Assignment \(j)",
                    score: score,
                    maxScore: 10.0,
                    date: Date().addingTimeInterval(Double(-j * 86400 * 3)),
                    isExam: false
                )
                grade.subject = subject
                modelContext.insert(grade)
            }
            
            // Add Exams
            // ✅ Fix: Removed 'description', passed 'isExam: true'
            let exam = GradeEntry(
                title: "Midterm Exam",
                score: 8.5,
                maxScore: 10.0,
                date: Date().addingTimeInterval(-86400 * 20),
                isExam: true
            )
            exam.subject = subject
            modelContext.insert(exam)
            
            // 4. Add Attendance (Past)
            for k in 1...15 {
                let status: AttendanceStatus = Bool.random() ? .present : .absent
                let att = AttendanceEntry(
                    date: Date().addingTimeInterval(Double(-k * 86400 * 2)),
                    status: status,
                    note: status == .absent ? "Sick" : nil
                )
                att.subject = subject
                modelContext.insert(att)
            }
            
            // 5. 🔥 Add STRESS TASKS
            for t in 1...10 {
                let isExam = (t % 3 == 0)
                let dayOffset = isExam ? Double.random(in: 0...14) : Double.random(in: -5 ... -1)
                let dueDate = Date().addingTimeInterval(dayOffset * 86400)
                
                let task = StudyTask(
                    title: isExam ? "EXAM: \(name) - Unit \(t)" : "Homework: \(name) - Unit \(t)",
                    isCompleted: false,
                    dueDate: dueDate,
                    priority: isExam ? .high : .medium,
                    subject: subject,
                    reminderTime: isExam ? .dayBefore1 : .hourBefore1,
                    isFlagged: isExam,
                    notes: "Generated stress task."
                )
                modelContext.insert(task)
            }
        }
        
        try? modelContext.save()
        print("✅ Heavy Stress Data Loaded")
    }
    
    // MARK: - Destructive Actions
    
    func deleteAllData(modelContext: ModelContext) {
        do {
            try modelContext.delete(model: Subject.self)
            try modelContext.delete(model: StudyTask.self)
            try modelContext.delete(model: GradeEntry.self)
            try modelContext.delete(model: AttendanceEntry.self)
            try? modelContext.save()
        } catch {
            print("Failed to delete data: \(error.localizedDescription)")
        }
    }
}
