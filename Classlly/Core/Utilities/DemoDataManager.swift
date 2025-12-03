import SwiftUI
import SwiftData

class DemoDataManager {
    static let shared = DemoDataManager()
    
    private init() {}
    
    @MainActor
    func createDemoData(modelContext: ModelContext) {
        // 1. Clear existing data first to avoid duplicates
        deleteAllData(modelContext: modelContext)
        
        // --- SUBJECTS ---
        
        // 1. Mathematics
        let math = Subject(
            title: "Calculus II",
            courseTeacher: "Dr. Alcubierre",
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
        
        // 2. CS
        let cs = Subject(
            title: "Algorithms & Data Structures",
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
        
        // 3. Physics
        let physics = Subject(
            title: "Quantum Physics",
            courseTeacher: "Dr. Feynman",
            courseClassroom: "Hall B",
            courseStartTime: date(hour: 13, minute: 0),
            courseEndTime: date(hour: 15, minute: 0),
            courseDays: [2, 5], // Mon, Thu
            courseFrequency: .weekly,
            seminarTeacher: "Dr. Curie",
            seminarClassroom: "Lab 101",
            seminarStartTime: date(hour: 16, minute: 0),
            seminarEndTime: date(hour: 18, minute: 0),
            seminarDays: [2], // Mon
            seminarFrequency: .biweeklyEven
        )
        
        // 4. History
        let history = Subject(
            title: "World History: 20th Century",
            courseTeacher: "Prof. Hobsbawm",
            courseClassroom: "Room 104",
            courseStartTime: date(hour: 15, minute: 30),
            courseEndTime: date(hour: 17, minute: 0),
            courseDays: [3, 5], // Tue, Thu
            courseFrequency: .weekly,
            seminarTeacher: "",
            seminarClassroom: "",
            seminarDate: Date(),
            seminarStartTime: Date(),
            seminarEndTime: Date(),
            seminarDays: [],
            seminarFrequency: .weekly
        )
        
        // 5. Literature
        let lit = Subject(
            title: "Modern American Literature",
            courseTeacher: "Dr. Morrison",
            courseClassroom: "Library 202",
            courseStartTime: date(hour: 11, minute: 0),
            courseEndTime: date(hour: 12, minute: 30),
            courseDays: [1, 4], // Sun, Wed
            courseFrequency: .weekly,
            seminarTeacher: "Mr. Poe",
            seminarClassroom: "Room 205",
            seminarStartTime: date(hour: 13, minute: 0),
            seminarEndTime: date(hour: 14, minute: 0),
            seminarDays: [4], // Wed
            seminarFrequency: .weekly
        )
        
        // 6. Economics
        let econ = Subject(
            title: "Macroeconomics",
            courseTeacher: "Prof. Keynes",
            courseClassroom: "Lecture Hall 1",
            courseStartTime: date(hour: 8, minute: 30),
            courseEndTime: date(hour: 10, minute: 0),
            courseDays: [2, 5], // Mon, Thu
            courseFrequency: .weekly,
            seminarTeacher: "Ms. Yellen",
            seminarClassroom: "Room 404",
            seminarStartTime: date(hour: 10, minute: 0),
            seminarEndTime: date(hour: 11, minute: 0),
            seminarDays: [5], // Thu
            seminarFrequency: .weekly
        )
        
        // --- GRADES (Updated with Percentage Weights) ---
        // Math: Midterm (30%), Quiz (10%)
        let g1 = GradeEntry(date: daysFromNow(-10), grade: 9.5, weight: 30.0, description: "Midterm Exam")
        let g2 = GradeEntry(date: daysFromNow(-5), grade: 7.0, weight: 10.0, description: "Pop Quiz")
        g1.subject = math; g2.subject = math
        
        // CS: Project (40%), Quiz (15%)
        let g3 = GradeEntry(date: daysFromNow(-20), grade: 10.0, weight: 40.0, description: "Final Project Phase 1")
        let g4 = GradeEntry(date: daysFromNow(-2), grade: 8.5, weight: 15.0, description: "Sorting Quiz")
        g3.subject = cs; g4.subject = cs
        
        // Physics: Lab (20%)
        let g5 = GradeEntry(date: daysFromNow(-15), grade: 7.5, weight: 20.0, description: "Lab Report 1")
        g5.subject = physics
        
        // Lit: Essay (25%)
        let g6 = GradeEntry(date: daysFromNow(-8), grade: 9.2, weight: 25.0, description: "Gatsby Essay")
        g6.subject = lit
        
        // --- TASKS ---
        
        // Math
        let t1 = StudyTask(title: "Calculus P-Set 4", isCompleted: false, dueDate: daysFromNow(2), priority: .high, subject: math, reminderTime: .dayBefore1, isFlagged: true, notes: "Problems 1-15, skip 8")
        let t2 = StudyTask(title: "Review Integration Rules", isCompleted: true, dueDate: daysFromNow(-1), priority: .medium, subject: math)
        
        // CS
        let t3 = StudyTask(title: "Implement Dijkstra's Algo", isCompleted: false, dueDate: daysFromNow(5), priority: .high, subject: cs, reminderTime: .hoursBefore2, isFlagged: true, notes: "Handle edge cases for unconnected graphs")
        let t4 = StudyTask(title: "Debug Binary Search Tree", isCompleted: false, dueDate: daysFromNow(1), priority: .medium, subject: cs)
        let t5 = StudyTask(title: "Read Chapter 5: Hashing", isCompleted: true, dueDate: daysFromNow(-3), priority: .low, subject: cs)
        
        // Physics
        let t6 = StudyTask(title: "Physics Lab Report: Pendulum", isCompleted: false, dueDate: daysFromNow(3), priority: .high, subject: physics, isFlagged: true)
        let t7 = StudyTask(title: "Quantum Mechanics Video Essay", isCompleted: false, dueDate: daysFromNow(10), priority: .medium, subject: physics)
        
        // History
        let t8 = StudyTask(title: "Read 'The Cold War' Ch. 1-3", isCompleted: false, dueDate: daysFromNow(1), priority: .medium, subject: history)
        let t9 = StudyTask(title: "Research Paper Topic Selection", isCompleted: true, dueDate: daysFromNow(-5), priority: .low, subject: history)
        
        // Literature
        let t10 = StudyTask(title: "Read 'Beloved' by T. Morrison", isCompleted: false, dueDate: daysFromNow(7), priority: .medium, subject: lit, notes: "Pages 1-100")
        let t11 = StudyTask(title: "Submit Poetry Analysis", isCompleted: false, dueDate: daysFromNow(0), priority: .high, subject: lit, reminderTime: .hourBefore1, isFlagged: true)
        
        // Econ
        let t12 = StudyTask(title: "Macroeconomics Problem Set", isCompleted: false, dueDate: daysFromNow(4), priority: .medium, subject: econ)
        let t13 = StudyTask(title: "Study for Econ Midterm", isCompleted: false, dueDate: daysFromNow(14), priority: .high, subject: econ)
        
        // General
        let t14 = StudyTask(title: "Buy Textbooks for next semester", isCompleted: false, dueDate: daysFromNow(20), priority: .low, reminderTime: .weekBefore1)
        let t15 = StudyTask(title: "Renew Library Card", isCompleted: true, dueDate: daysFromNow(-10), priority: .low)
        
        // Insert All
        let allItems: [any PersistentModel] = [
            math, cs, physics, history, lit, econ,
            g1, g2, g3, g4, g5, g6,
            t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15
        ]
        
        for item in allItems {
            modelContext.insert(item)
        }
        
        do {
            try modelContext.save()
            print("Expanded demo data created successfully.")
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
    
    private func daysFromNow(_ days: Double) -> Date {
        return Date().addingTimeInterval(days * 86400)
    }
}
