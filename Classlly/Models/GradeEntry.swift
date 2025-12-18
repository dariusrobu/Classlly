import Foundation
import SwiftData

@Model
final class GradeEntry {
    var id: UUID = UUID()
    var title: String = ""
    var score: Double = 0.0
    var weight: Double = 100.0
    var maxScore: Double = 10.0
    var date: Date = Date()
    var isExam: Bool = false
    
    // Inverse relationship
    var subject: Subject?

    // Initializer 1: Full (Used by UI Sheets)
    init(date: Date = Date(), grade: Double, weight: Double = 100.0, description: String, isExam: Bool = false) {
        self.id = UUID()
        self.date = date
        self.score = grade
        self.weight = weight
        self.title = description
        self.maxScore = 10.0
        self.isExam = isExam
    }

    // Initializer 2: Standard (Used by DemoData)
    // ✅ Fix: Added isExam parameter
    init(title: String, score: Double, maxScore: Double, date: Date = Date(), isExam: Bool = false) {
        self.id = UUID()
        self.title = title
        self.score = score
        self.maxScore = maxScore
        self.date = date
        self.weight = 100.0
        self.isExam = isExam
    }
    
    var percentage: Double {
        guard maxScore > 0 else { return 0 }
        return (score / maxScore) * 100
    }
}
