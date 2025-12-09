import SwiftUI
import SwiftData

class DemoDataManager {
    static let shared = DemoDataManager()
    
    private init() {}
    
    @MainActor
    func createDemoData(modelContext: ModelContext) {
        // Standard small demo data (optional use)
        deleteAllData(modelContext: modelContext)
        
        // ... (Keep existing simple demo logic or leave empty if unused) ...
        // Re-implementing basic subjects for completeness if needed elsewhere
        let math = Subject(title: "Calculus I", courseTeacher: "Dr. Smith", courseClassroom: "Room 301", courseDays: [2, 4], seminarTeacher: "Mr. Johnson", seminarClassroom: "Lab 4B", seminarDays: [5])
        let cs = Subject(title: "CS 101", courseTeacher: "Prof. Turing", courseClassroom: "Auditorium A", courseDays: [1, 3], seminarTeacher: "Ms. Lovelace", seminarClassroom: "Lab 2C", seminarDays: [3])
        
        modelContext.insert(math)
        modelContext.insert(cs)
        try? modelContext.save()
    }
    
    // MARK: - Heavy Stress Test Data
    @MainActor
    func createHeavyStressData(modelContext: ModelContext) {
        deleteAllData(modelContext: modelContext)
        print("Starting Heavy Stress Test Data Generation...")
        
        // 1. Create 8 Subjects
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
        
        for sub in subjects {
            modelContext.insert(sub)
        }
        
        // 2. Create 25 Tasks Total (Spread over the week, appearing every day)
        let calendar = Calendar.current
        let today = Date()
        
        // Ensure at least one task per day for the next 7 days (indices 0 to 6)
        var dayOffsets = Array(0..<7)
        
        // Add remaining 18 tasks randomly distributed across the week (25 total)
        for _ in 0..<18 {
            dayOffsets.append(Int.random(in: 0...6))
        }
        
        // Shuffle to randomize creation order
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
        
        do {
            try modelContext.save()
            print("Heavy stress test data created: 8 Subjects, 25 Tasks (spread across 7 days).")
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
