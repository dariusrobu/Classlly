import SwiftUI
import SwiftData

class DemoDataManager {
    static let shared = DemoDataManager()
    
    private init() {}
    
    @MainActor
    func createHeavyStressData(modelContext: ModelContext) {
        deleteAllData(modelContext: modelContext)
        print("Starting Heavy Stress Test Data Generation...")
        
        // 1. Create Subjects
        let subjects = [
            Subject(title: "Advanced Calculus", courseTeacher: "Dr. Metric", courseClassroom: "301A", courseDays: [2, 4], seminarTeacher: "Mr. T", seminarClassroom: "301B", seminarDays: [5]),
            Subject(title: "Quantum Physics", courseTeacher: "Prof. Bohr", courseClassroom: "Lab 1", courseDays: [1, 3], seminarTeacher: "Ms. Curie", seminarClassroom: "Lab 2", seminarDays: [3]),
            Subject(title: "Algorithms", courseTeacher: "Prof. Knuth", courseClassroom: "C100", courseDays: [2, 5], seminarTeacher: "Ada", seminarClassroom: "C101", seminarDays: [4]),
            Subject(title: "World History", courseTeacher: "Dr. Time", courseClassroom: "H1", courseDays: [1], seminarTeacher: "Mr. Past", seminarClassroom: "H2", seminarDays: [1]),
            Subject(title: "Organic Chemistry", courseTeacher: "Dr. Bond", courseClassroom: "Chem Lab", courseDays: [3, 5], seminarTeacher: "James", seminarClassroom: "Lab 007", seminarDays: [5]),
            Subject(title: "Literature", courseTeacher: "Ms. Shakespeare", courseClassroom: "L10", courseDays: [2], seminarTeacher: "Mr. Poet", seminarClassroom: "L11", seminarDays: [4]),
            Subject(title: "Microbiology", courseTeacher: "Dr. Cell", courseClassroom: "Bio Lab", courseDays: [1, 4], seminarTeacher: "Ms. Germ", seminarClassroom: "Bio Lab 2", seminarDays: [3]),
            Subject(title: "Graphic Design", courseTeacher: "Prof. Art", courseClassroom: "Studio A", courseDays: [5], seminarTeacher: "Dali", seminarClassroom: "Studio B", seminarDays: [5])
        ]
        
        // Insert Subjects first so they have IDs/Context
        for sub in subjects {
            modelContext.insert(sub)
        }
        
        // 2. Create Tasks
        let calendar = Calendar.current
        let today = Date()
        var dayOffsets = Array(0..<7)
        for _ in 0..<18 { dayOffsets.append(Int.random(in: 0...6)) }
        dayOffsets.shuffle()
        
        for (index, dayOffset) in dayOffsets.enumerated() {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let randomSubject = subjects.randomElement()
            
            let task = StudyTask(
                title: "Stress Task \(index + 1): \(randomSubject?.title ?? "General")",
                isCompleted: Bool.random(),
                dueDate: date,
                priority: TaskPriority.allCases.randomElement() ?? .medium,
                subject: randomSubject,
                reminderTime: .none,
                isFlagged: index % 5 == 0
            )
            modelContext.insert(task)
        }
        
        // 3. Create Grades & Attendance for each Subject
        for sub in subjects {
            // --- Generate Grades ---
            // Create 3 to 6 grades per subject
            let gradesCount = Int.random(in: 3...6)
            for i in 0..<gradesCount {
                // Generate a date in the past 4 months
                let pastDays = Int.random(in: 1...120) * -1
                let gradeDate = calendar.date(byAdding: .day, value: pastDays, to: today) ?? today
                
                // Random grade between 5 and 10
                let score = Double.random(in: 5...10)
                // Random weight mostly 100%, sometimes higher or lower
                let weight = [50.0, 100.0, 100.0, 100.0, 200.0].randomElement() ?? 100.0
                
                let isExam = (i == 0) // Make one an exam
                let description = isExam ? "Midterm Exam" : "Assignment \(i + 1)"
                
                let gradeEntry = GradeEntry(
                    date: gradeDate,
                    grade: (score * 10).rounded() / 10, // Round to 1 decimal
                    weight: weight,
                    description: description,
                    isExam: isExam
                )
                
                // Link relationships
                gradeEntry.subject = sub
                sub.gradeHistory?.append(gradeEntry)
                modelContext.insert(gradeEntry)
            }
            
            // --- Generate Attendance ---
            // Create 10 to 15 attendance records per subject
            let attendanceCount = Int.random(in: 10...15)
            for j in 0..<attendanceCount {
                // Go back 'j' weeks
                let pastDays = (j * 7) * -1
                let attendanceDate = calendar.date(byAdding: .day, value: pastDays, to: today) ?? today
                
                // 80% chance of being present
                let isPresent = Double.random(in: 0...1) < 0.8
                let notes = isPresent ? "" : "Sick leave"
                
                let attendanceEntry = AttendanceEntry(
                    date: attendanceDate,
                    attended: isPresent,
                    notes: notes
                )
                
                // Link relationships
                attendanceEntry.subject = sub
                sub.attendanceHistory?.append(attendanceEntry)
                modelContext.insert(attendanceEntry)
            }
        }
        
        do {
            try modelContext.save()
            print("Heavy stress test data (Subjects, Tasks, Grades, Attendance) created.")
        } catch {
            print("Failed to save stress data: \(error)")
        }
    }
    
    @MainActor
    func deleteAllData(modelContext: ModelContext) {
        do {
            try modelContext.delete(model: Subject.self)
            try modelContext.delete(model: StudyTask.self)
            try modelContext.delete(model: GradeEntry.self)
            try modelContext.delete(model: AttendanceEntry.self)
            try modelContext.delete(model: StudyCalendarEvent.self)
            // Cleanup Profiles and Imported Events too
            try modelContext.delete(model: StudentProfile.self)
            try modelContext.delete(model: ClassEvent.self)
            
            try modelContext.save()
            print("All app data deleted and saved.")
        } catch {
            print("Failed to delete data: \(error)")
        }
    }
}
