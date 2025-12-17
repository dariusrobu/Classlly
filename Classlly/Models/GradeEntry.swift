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
    var title: String
    var score: Double
    var maxScore: Double
    var date: Date
    
    // Inverse relationship (optional, but good practice)
    var subject: Subject?

    init(title: String, score: Double, maxScore: Double, date: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.score = score
        self.maxScore = maxScore
        self.date = date
    }
    
    var percentage: Double {
        guard maxScore > 0 else { return 0 }
        return (score / maxScore) * 100
    }
}