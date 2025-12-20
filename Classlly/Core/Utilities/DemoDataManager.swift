import Foundation
import SwiftData

class DemoDataManager {
    static let shared = DemoDataManager()
    
    // MARK: - 🧪 1. Perfect Gap Scenario (For Notification Testing)
    func createPerfectGapScenario(modelContext: ModelContext) {
        print("🧪 Injecting Perfect Gap Scenario...")
        // We delete everything but KEEP the profile so you don't get logged out
        deleteAllData(modelContext: modelContext, includeProfile: false)
        
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today) // Get TODAY'S weekday index
        
        // 1. Create "Morning Class" (Starts 9 AM, Ends 10 AM)
        let morningStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today)!
        let morningEnd = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today)!
        
        let subjectA = Subject(
            title: "Morning Math",
            colorHex: "007AFF",
            ectsCredits: 5,
            courseTeacher: "Prof. Early",
            courseClassroom: "Room 101",
            courseFrequency: .weekly,
            courseStartTime: morningStart,
            courseEndTime: morningEnd,
            courseDays: [weekday], // ✅ Force it to occur TODAY
            hasSeminar: false,
            seminarTeacher: "",
            seminarClassroom: "",
            seminarFrequency: .weekly,
            seminarStartTime: Date(),
            seminarEndTime: Date(),
            seminarDays: []
        )
        
        // 2. Create "Afternoon Class" (Starts 2 PM, Ends 3 PM)
        // Gap = 10 AM to 2 PM = 4 Hours ( > 2 hours )
        let afternoonStart = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: today)!
        let afternoonEnd = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: today)!
        
        let subjectB = Subject(
            title: "Afternoon History",
            colorHex: "FF9500",
            ectsCredits: 5,
            courseTeacher: "Prof. Late",
            courseClassroom: "Room 202",
            courseFrequency: .weekly,
            courseStartTime: afternoonStart,
            courseEndTime: afternoonEnd,
            courseDays: [weekday], // ✅ Force it to occur TODAY
            hasSeminar: false,
            seminarTeacher: "",
            seminarClassroom: "",
            seminarFrequency: .weekly,
            seminarStartTime: Date(),
            seminarEndTime: Date(),
            seminarDays: []
        )
        
        // 3. Create a High Priority Task to be suggested
        let task = StudyTask(
            title: "Math Homework",
            isCompleted: false,
            dueDate: Date().addingTimeInterval(86400), // Due tomorrow
            priority: .high,
            subject: subjectA,
            reminderTime: .hourBefore1,
            isFlagged: true,
            notes: "Finish this during the gap."
        )
        
        modelContext.insert(subjectA)
        modelContext.insert(subjectB)
        modelContext.insert(task)
        
        try? modelContext.save()
        print("✅ Data Injected: Morning Math (9-10) & Afternoon History (14-15) on Weekday \(weekday)")
    }
    
    // MARK: - ⚡️ 2. Stress Test Data (For Dashboard Populating)
    func createHeavyStressData(modelContext: ModelContext, cleanFirst: Bool = true, keepProfile: Bool = true) {
        print("⚡️ Starting Stress Data Generation...")
        
        if cleanFirst {
            deleteAllData(modelContext: modelContext, includeProfile: !keepProfile)
        }
        
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
            // Subject
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
                hasSeminar: hasSeminar,
                seminarTeacher: hasSeminar ? "Dr. Assistant" : "",
                seminarClassroom: hasSeminar ? "Lab \(Int.random(in: 1...10))" : "",
                seminarFrequency: .weekly,
                seminarStartTime: Date().addingTimeInterval(7200),
                seminarEndTime: Date().addingTimeInterval(9000),
                seminarDays: hasSeminar ? [days.first! + 1] : []
            )
            modelContext.insert(subject)
            
            // Grades
            for j in 1...8 {
                let grade = GradeEntry(
                    title: "Assignment \(j)",
                    score: Double.random(in: 5...10),
                    maxScore: 10.0,
                    date: Date().addingTimeInterval(Double(-j * 86400 * 3)),
                    isExam: false
                )
                grade.subject = subject
                modelContext.insert(grade)
            }
            
            // Exams
            let exam = GradeEntry(
                title: "Midterm Exam",
                score: 8.5,
                maxScore: 10.0,
                date: Date().addingTimeInterval(-86400 * 20),
                isExam: true
            )
            exam.subject = subject
            modelContext.insert(exam)
            
            // Attendance
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
            
            // Tasks
            for t in 1...10 {
                let isExam = (t % 3 == 0)
                let dayOffset = isExam ? Double.random(in: 0...14) : Double.random(in: -5 ... -1)
                
                let task = StudyTask(
                    title: isExam ? "EXAM: \(name) - Unit \(t)" : "Homework: \(name) - Unit \(t)",
                    isCompleted: false,
                    dueDate: Date().addingTimeInterval(dayOffset * 86400),
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
    
    // MARK: - 🗑️ 3. Destructive Actions
    func deleteAllData(modelContext: ModelContext, includeProfile: Bool = false) {
        do {
            try modelContext.delete(model: Subject.self)
            try modelContext.delete(model: StudyTask.self)
            try modelContext.delete(model: GradeEntry.self)
            try modelContext.delete(model: AttendanceEntry.self)
            
            if includeProfile {
                try modelContext.delete(model: StudentProfile.self)
                print("🗑️ Student Profile Deleted")
            }
            
            try modelContext.save()
            print("🗑️ Academic Data Deleted")
        } catch {
            print("Failed to delete data: \(error.localizedDescription)")
        }
    }
}
