import SwiftUI
import SwiftData

class DemoDataManager {
    static let shared = DemoDataManager()
    
    private init() {}
    
    @MainActor
    func createDemoData(modelContext: ModelContext) {
        // 1. Clear existing data first to avoid duplicates
        deleteAllData(modelContext: modelContext)
        
        // 2. Create Subjects
        let math = Subject(
            title: "Calculus I",
            courseTeacher: "Dr. Smith",
            courseClassroom: "Room 301",
            courseStartTime: date(hour: 10, minute: 0),
            courseEndTime: date(hour: 12, minute: 0),
            courseDays: [2, 4], // Mon, Wed
            courseFrequency: .weekly,
            seminarTeacher: "Mr. Johnson",
            seminarClassroom: "Lab 4B",
            seminarStartTime: date(hour: 14, minute: 0),
            seminarEndTime: date(hour: 16, minute: 0),
            seminarDays: [5], // Fri
            seminarFrequency: .weekly
        )
        
        let cs = Subject(
            title: "Computer Science 101",
            courseTeacher: "Prof. Turing",
            courseClassroom: "Auditorium A",
            courseStartTime: date(hour: 9, minute: 0),
            courseEndTime: date(hour: 10, minute: 30),
            courseDays: [1, 3], // Sun, Tue
            courseFrequency: .weekly,
            seminarTeacher: "Ms. Lovelace",
            seminarClassroom: "Lab 2C",
            seminarStartTime: date(hour: 11, minute: 0),
            seminarEndTime: date(hour: 13, minute: 0),
            seminarDays: [3], // Tue
            seminarFrequency: .biweeklyOdd
        )
        
        // 3. Add Grades
        let mathGrade1 = GradeEntry(date: Date().addingTimeInterval(-86400 * 10), grade: 9.5, description: "Midterm Exam")
        let mathGrade2 = GradeEntry(date: Date().addingTimeInterval(-86400 * 5), grade: 8.0, description: "Quiz 1")
        mathGrade1.subject = math
        mathGrade2.subject = math
        
        // 4. Add Tasks
        let task1 = StudyTask(
            title: "Complete Calculus Problem Set",
            isCompleted: false,
            dueDate: Date().addingTimeInterval(86400 * 2), // Due in 2 days
            priority: .high,
            subject: math,
            reminderTime: .dayBefore1,
            isFlagged: true
        )
        
        let task2 = StudyTask(
            title: "Submit CS Lab Report",
            isCompleted: true,
            dueDate: Date().addingTimeInterval(-86400), // Due yesterday
            priority: .medium,
            subject: cs,
            reminderTime: .hourBefore1,
            isFlagged: false
        )
        
        // 5. Insert and Save
        modelContext.insert(math)
        modelContext.insert(cs)
        modelContext.insert(mathGrade1)
        modelContext.insert(mathGrade2)
        modelContext.insert(task1)
        modelContext.insert(task2)
        
        do {
            try modelContext.save()
            print("Demo data created and saved.")
        } catch {
            print("Failed to save demo data: \(error)")
        }
    }
    
    @MainActor
    func deleteAllData(modelContext: ModelContext) {
        do {
            // Delete all entities
            try modelContext.delete(model: Subject.self)
            try modelContext.delete(model: StudyTask.self)
            try modelContext.delete(model: GradeEntry.self)
            try modelContext.delete(model: AttendanceEntry.self)
            try modelContext.delete(model: StudyCalendarEvent.self)
            // Note: We do NOT delete StudentProfile here, that is handled separately if needed
            
            // Force save to ensure deletion persists immediately
            try modelContext.save()
            print("All app data deleted and saved.")
        } catch {
            print("Failed to delete data: \(error)")
        }
    }
    
    private func date(hour: Int, minute: Int) -> Date {
        return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }
}
