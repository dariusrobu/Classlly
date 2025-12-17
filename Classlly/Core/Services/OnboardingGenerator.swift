import Foundation
import SwiftData

class OnboardingGenerator {
    static func generateSampleData(modelContext: ModelContext) {
        // Create a sample subject: "Introduction to Computer Science"
        let sampleSubject = Subject(
            title: "Intro to CS",
            colorHex: "007AFF",
            ectsCredits: 6,
            
            // Course Details
            courseTeacher: "Prof. Alan Turing",
            courseClassroom: "Lab 301",
            courseFrequency: .weekly,      // <--- Correct order: Frequency first
            courseStartTime: Date(),
            courseEndTime: Date().addingTimeInterval(5400), // 1.5 hours later
            courseDays: [2, 4], // Tue, Thu
            
            // Seminar Details
            hasSeminar: true,
            seminarTeacher: "Dr. Lovelace",
            seminarClassroom: "Room 101",
            seminarFrequency: .weekly,
            seminarStartTime: Date().addingTimeInterval(86400), // Next day
            seminarEndTime: Date().addingTimeInterval(86400 + 3600),
            seminarDays: [3] // Wed
        )
        
        modelContext.insert(sampleSubject)
        
        // Add a sample grade
        // Using the standard initializer that defaults weight to 100%
        let sampleGrade = GradeEntry(title: "Midterm Exam", score: 85, maxScore: 100, date: Date())
        sampleSubject.grades.append(sampleGrade)
    }
    
    static func generateTemplate(context: ModelContext, subjectCount: Int, semesterEnd: Date) {
        // Create a number of demo subjects and add them to context
        let colors = ["FF9500", "FF2D55", "007AFF", "34C759", "AF52DE", "5AC8FA", "FFD60A"]
        for i in 1...subjectCount {
            let subject = Subject(
                title: "Subject \(i)",
                colorHex: colors[(i-1) % colors.count],
                ectsCredits: 6,
                courseTeacher: "Teacher \(i)",
                courseClassroom: "Room \(100+i)",
                courseFrequency: .weekly,
                courseStartTime: Date(),
                courseEndTime: Date().addingTimeInterval(5400),
                courseDays: [2 + ((i-1) % 5)],
                
                hasSeminar: false,
                // Fix: Replaced 'nil' with empty strings and dates because Subject expects non-optionals
                seminarTeacher: "",
                seminarClassroom: "",
                seminarFrequency: .weekly,
                seminarStartTime: Date(),
                seminarEndTime: Date().addingTimeInterval(3600),
                seminarDays: []
            )

            context.insert(subject)
        }
    }
}
