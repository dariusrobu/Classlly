//
//  GradeEntry.swift
//  Classlly
//
//  Created by Robu Darius on 17.12.2025.
//

import Foundation
import SwiftData

@Model
final class GradeEntry {
    var id: UUID
    var title: String      // "Description" in the UI
    var score: Double      // "Grade" in the UI
    var weight: Double     // New: Weight percentage (e.g., 100 for 100%, 50 for 50%)
    var maxScore: Double   // Standard max score (usually 10)
    var date: Date
    
    // Inverse relationship
    var subject: Subject?

    // Designated Initializer matching HomeView usage
    init(date: Date = Date(), grade: Double, weight: Double = 100.0, description: String) {
        self.id = UUID()
        self.date = date
        self.score = grade
        self.weight = weight
        self.title = description
        self.maxScore = 10.0 // Default to 10 if not specified
    }

    // Standard Initializer
    init(title: String, score: Double, maxScore: Double, date: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.score = score
        self.maxScore = maxScore
        self.date = date
        self.weight = 100.0 // Default weight
    }
    
    var percentage: Double {
        guard maxScore > 0 else { return 0 }
        return (score / maxScore) * 100
    }
}
