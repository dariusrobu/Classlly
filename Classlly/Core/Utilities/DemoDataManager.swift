import Foundation
import SwiftData
import SwiftUI

class DemoDataManager {
    static let shared = DemoDataManager()
    
    @MainActor
    func deleteAllData(modelContext: ModelContext, includeProfile: Bool = false) {
        do {
            try modelContext.delete(model: Subject.self)
            try modelContext.delete(model: StudyTask.self)
            try modelContext.delete(model: GradeEntry.self)
            try modelContext.delete(model: AttendanceEntry.self)
            
            if includeProfile {
                try modelContext.delete(model: StudentProfile.self)
                try modelContext.delete(model: AppUser.self) // Ensure user record is also deleted
            }
            
            // Explicit save to ensure deletion is committed immediately
            try? modelContext.save()
            
            print("🗑️ All Data Deleted")
        } catch {
            print("❌ Failed to delete data: \(error)")
        }
    }
    
    @MainActor
    func createDemoProfile(modelContext: ModelContext) {
        // 1. Check if user already exists to avoid duplicates
        let demoID = AuthenticationManager.demoUserID
        let descriptor = FetchDescriptor<AppUser>(predicate: #Predicate { $0.id == demoID })
        
        if let count = try? modelContext.fetchCount(descriptor), count > 0 {
            print("⚠️ Demo user already exists, skipping creation.")
            return
        }
        
        print("👤 Creating Demo User Profile...")
        
        // 2. Create the AppUser with the specific ID required by AuthManager
        let demoUser = AppUser(
            id: demoID,
            email: "demo@classlly.com",
            fullName: "Demo Student"
        )
        
        // 3. Pre-fill academic details so ProfileSetupView is skipped
        demoUser.universityName = "Demo University"
        demoUser.facultyName = "Computer Science"
        demoUser.yearOfStudy = "2"
        demoUser.group = "CS-202"
        demoUser.onboardingCompleted = true
        
        modelContext.insert(demoUser)
        
        // 4. Critical: Save immediately so RootView queries find it
        do {
            try modelContext.save()
            print("✅ Demo User Saved Successfully")
        } catch {
            print("❌ Failed to save demo user: \(error)")
        }
    }
    
    @MainActor
    func createHeavyStressData(modelContext: ModelContext, cleanFirst: Bool = true, keepProfile: Bool = true) {
        if cleanFirst {
            deleteAllData(modelContext: modelContext, includeProfile: !keepProfile)
        }
        
        print("🏗️ Generating Heavy Stress Demo Data...")
        
        // 1. Subjects
        let subjectsData: [(String, String, String, String, [Int], String, String, [Int], Color)] = [
            ("Advanced Calculus", "Math 301", "Dr. Archimedes", "Room 304", [2, 4], "10:00 - 11:30", "Main Hall", [], .blue),
            ("Quantum Physics", "Phys 404", "Dr. Feynman", "Lab 1", [1, 3, 5], "14:00 - 15:30", "Lab 1", [], .purple),
            ("World History", "Hist 101", "Prof. Herodotus", "Arts 202", [2, 4], "13:00 - 14:30", "", [], .orange),
            ("Organic Chemistry", "Chem 202", "Dr. Curie", "Lab 4", [1, 3, 5], "09:00 - 10:30", "", [], .green),
            ("Computer Science", "CS 101", "Prof. Turing", "Tech 101", [1, 3, 5], "11:00 - 12:30", "", [], .indigo)
        ]
        
        var subjects: [Subject] = []
        
        for data in subjectsData {
            let s = Subject(
                title: data.0,
                code: data.1,
                colorHex: data.8.toHex() ?? "#0000FF",
                icon: "book.fill",
                credits: 3,
                
                // Course
                courseTeacher: data.2,
                courseClassroom: data.3,
                courseDays: data.4,
                courseFrequency: .weekly,
                courseStartTime: dateFromTime(data.5.components(separatedBy: " - ")[0]),
                courseEndTime: dateFromTime(data.5.components(separatedBy: " - ")[1]),
                
                // Seminar
                hasSeminar: !data.6.isEmpty,
                seminarTeacher: data.6.isEmpty ? "" : "TA Smith",
                seminarClassroom: data.6,
                seminarDays: data.7,
                seminarFrequency: .weekly,
                seminarStartTime: data.7.isEmpty ? Date() : dateFromTime("16:00"),
                seminarEndTime: data.7.isEmpty ? Date() : dateFromTime("17:00")
            )
            
            // Random Grades
            let g1 = GradeEntry(date: Date().addingTimeInterval(-86400 * 10), grade: Double.random(in: 6...10), weight: 20, description: "Quiz 1", isExam: false)
            let g2 = GradeEntry(date: Date().addingTimeInterval(-86400 * 5), grade: Double.random(in: 5...9), weight: 30, description: "Midterm", isExam: true)
            g1.subject = s
            g2.subject = s
            
            // Random Attendance
            let a1 = AttendanceEntry(date: Date().addingTimeInterval(-86400 * 2), status: .present)
            let a2 = AttendanceEntry(date: Date().addingTimeInterval(-86400 * 7), status: .absent, note: "Sick")
            a1.subject = s
            a2.subject = s
            
            modelContext.insert(s)
            subjects.append(s)
        }
        
        // 2. Tasks
        let tasksData: [(String, TaskPriority, Int, TaskType)] = [
            ("Final Calculus Exam", .high, 2, .exam),
            ("Physics Lab Report", .high, 1, .project),
            ("History Essay Draft", .medium, 3, .homework),
            ("Chemistry Quiz Prep", .high, 0, .quiz),
            ("CS Group Project", .medium, 5, .project),
            ("Read Chapter 4-5", .low, 1, .homework),
            ("Register for Next Semester", .high, 4, .task),
            ("Buy Lab Coat", .medium, 2, .task)
        ]
        
        for (index, tData) in tasksData.enumerated() {
            let task = StudyTask(
                title: tData.0,
                isCompleted: false,
                dueDate: Date().addingTimeInterval(TimeInterval(tData.2 * 86400)),
                priority: tData.1,
                type: tData.3,
                reminderTime: .onTime,
                subject: subjects[index % subjects.count],
                isFlagged: tData.1 == .high,
                notes: "Demo task notes."
            )
            modelContext.insert(task)
        }
        
        try? modelContext.save()
        print("✅ Heavy Stress Data Loaded")
    }
    
    @MainActor
    func createPerfectGapScenario(modelContext: ModelContext) {
        deleteAllData(modelContext: modelContext)
        print("🏗️ Creating Perfect Gap Scenario...")
        
        let todayWeekday = Calendar.current.component(.weekday, from: Date())
        
        // Class 1: 08:00 - 10:00
        let s1 = Subject(
            title: "Morning Lecture",
            code: "AM-101",
            colorHex: "#FF0000",
            courseDays: [todayWeekday],
            courseStartTime: dateFromTime("08:00"),
            courseEndTime: dateFromTime("10:00")
        )
        
        // Class 2: 14:00 - 16:00 (Creating a 4-hour gap: 10:00 -> 14:00)
        let s2 = Subject(
            title: "Afternoon Seminar",
            code: "PM-202",
            colorHex: "#00FF00",
            courseDays: [todayWeekday],
            courseStartTime: dateFromTime("14:00"),
            courseEndTime: dateFromTime("16:00")
        )
        
        modelContext.insert(s1)
        modelContext.insert(s2)
        try? modelContext.save()
        print("✅ Gap Scenario Created")
    }
    
    private func dateFromTime(_ timeString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeDate = formatter.date(from: timeString.trimmingCharacters(in: .whitespaces)) ?? Date()
        
        let calendar = Calendar.current
        let timeComps = calendar.dateComponents([.hour, .minute], from: timeDate)
        
        return calendar.date(bySettingHour: timeComps.hour ?? 0, minute: timeComps.minute ?? 0, second: 0, of: Date()) ?? Date()
    }
}
