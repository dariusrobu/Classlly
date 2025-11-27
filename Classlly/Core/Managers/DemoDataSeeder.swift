//
//  DemoDataSeeder.swift
//  Classlly
//
//  Created by Robu Darius on 25.11.2025.
//


import SwiftUI
import SwiftData

@MainActor
class DemoDataSeeder {
    static func seed(context: ModelContext) {
        // 1. Check if data already exists to prevent duplicates
        // We fetch subjects to see if the DB is empty
        let descriptor = FetchDescriptor<Subject>()
        if let existingCount = try? context.fetchCount(descriptor), existingCount > 0 {
            print("Data already exists. Skipping seed.")
            return
        }
        
        print("Seeding demo data...")
        
        // --- 2. Create Subjects ---
        
        // Subject 1: Mathematics (Weekly)
        let math = Subject(
            title: "Mathematics",
            courseTeacher: "Dr. Alan Turing",
            courseClassroom: "Room 101",
            courseDate: Date(),
            courseStartTime: date(hour: 9, minute: 0),
            courseEndTime: date(hour: 10, minute: 30),
            courseDays: [2, 4], // Mon, Wed
            courseFrequency: .weekly,
            seminarTeacher: "Mrs. Lovelace",
            seminarClassroom: "Lab A",
            seminarStartTime: date(hour: 11, minute: 0),
            seminarEndTime: date(hour: 12, minute: 0),
            seminarDays: [5], // Thu
            seminarFrequency: .weekly
        )
        
        // Subject 2: Computer Science (Bi-weekly)
        let cs = Subject(
            title: "Computer Science",
            courseTeacher: "Prof. Grace Hopper",
            courseClassroom: "Tech Hub",
            courseDate: Date(),
            courseStartTime: date(hour: 14, minute: 0),
            courseEndTime: date(hour: 16, minute: 0),
            courseDays: [1, 3], // Sun, Tue
            courseFrequency: .biweeklyOdd,
            seminarTeacher: "",
            seminarClassroom: "",
            seminarDays: [],
            seminarFrequency: .weekly
        )
        
        // Subject 3: History (Weekly)
        let history = Subject(
            title: "World History",
            courseTeacher: "Mr. Herodotus",
            courseClassroom: "Hall B",
            courseDate: Date(),
            courseStartTime: date(hour: 10, minute: 0),
            courseEndTime: date(hour: 11, minute: 30),
            courseDays: [2, 5], // Mon, Thu
            courseFrequency: .weekly,
            seminarTeacher: "Ms. Clio",
            seminarClassroom: "Room 202",
            seminarStartTime: date(hour: 13, minute: 0),
            seminarEndTime: date(hour: 14, minute: 0),
            seminarDays: [3], // Tue
            seminarFrequency: .biweeklyEven
        )
        
        context.insert(math)
        context.insert(cs)
        context.insert(history)
        
        // --- 3. Add Grades ---
        
        let grades = [
            GradeEntry(date: daysAgo(10), grade: 9.5, description: "Calculus Midterm"), // Math
            GradeEntry(date: daysAgo(5), grade: 8.0, description: "Algebra Quiz"),      // Math
            GradeEntry(date: daysAgo(15), grade: 10.0, description: "Algorithm Project"), // CS
            GradeEntry(date: daysAgo(2), grade: 7.5, description: "Ancient Rome Essay")   // History
        ]
        
        // Associate grades
        grades[0].subject = math
        grades[1].subject = math
        grades[2].subject = cs
        grades[3].subject = history
        
        grades.forEach { context.insert($0) }
        
        // --- 4. Add Attendance ---
        
        let attendance = [
            AttendanceEntry(date: daysAgo(1), attended: true, notes: "Present"),
            AttendanceEntry(date: daysAgo(3), attended: true, notes: "Present"),
            AttendanceEntry(date: daysAgo(8), attended: false, notes: "Sick leave"),
            AttendanceEntry(date: daysAgo(10), attended: true, notes: "")
        ]
        
        attendance[0].subject = math
        attendance[1].subject = cs
        attendance[2].subject = history
        attendance[3].subject = math
        
        attendance.forEach { context.insert($0) }
        
        // --- 5. Add Tasks ---
        
        let tasks = [
            StudyTask(title: "Complete Math Problem Set", isCompleted: false, dueDate: daysFromNow(1), priority: .high, subject: math),
            StudyTask(title: "Read CS Chapter 4", isCompleted: false, dueDate: daysFromNow(3), priority: .medium, subject: cs),
            StudyTask(title: "History Essay Outline", isCompleted: true, dueDate: daysAgo(1), priority: .low, subject: history),
            StudyTask(title: "Register for Exams", isCompleted: false, dueDate: daysFromNow(7), priority: .high, subject: nil), // General task
            StudyTask(title: "Buy Textbooks", isCompleted: false, dueDate: nil, priority: .medium, subject: nil)
        ]
        
        tasks.forEach { context.insert($0) }
        
        print("✅ Demo data seeded successfully!")
    }
    
    // Helpers
    private static func date(hour: Int, minute: Int) -> Date {
        return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }
    
    private static func daysAgo(_ days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }
    
    private static func daysFromNow(_ days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
    }
}