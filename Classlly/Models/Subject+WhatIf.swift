import Foundation

extension Subject {
    /// Calculates the current average based on recorded grades
    var currentAverage: Double {
        // Use 'grades', not 'gradeHistory'
        guard !grades.isEmpty else { return 0.0 }
        
        let totalScore = grades.reduce(0) { $0 + $1.score }
        let totalMax = grades.reduce(0) { $0 + $1.maxScore }
        
        guard totalMax > 0 else { return 0.0 }
        return (totalScore / totalMax) * 100
    }
    
    /// Predicts final grade if the user gets specific scores on remaining assignments
    func predictFinalGrade(futureScores: [Double], futureMaxScores: [Double]) -> Double {
        // 1. Calculate current totals using 'grades'
        let currentTotalScore = grades.reduce(0) { $0 + $1.score }
        let currentTotalMax = grades.reduce(0) { $0 + $1.maxScore }
        
        // 2. Add hypothetical future scores
        let futureTotalScore = futureScores.reduce(0, +)
        let futureTotalMax = futureMaxScores.reduce(0, +)
        
        let finalScore = currentTotalScore + futureTotalScore
        let finalMax = currentTotalMax + futureTotalMax
        
        guard finalMax > 0 else { return 0.0 }
        
        return (finalScore / finalMax) * 100
    }
    
    /// Calculates what score is needed on the next exam/assignment to reach a target average
    func scoreNeeded(forTarget target: Double, nextAssignmentMax: Double) -> Double {
        let currentTotalScore = grades.reduce(0) { $0 + $1.score }
        let currentTotalMax = grades.reduce(0) { $0 + $1.maxScore }
        
        // Formula: (CurrentScore + X) / (CurrentMax + NextMax) = Target%
        // Solve for X:
        // X = (Target% * (CurrentMax + NextMax)) - CurrentScore
        
        let targetDecimal = target / 100.0
        let requiredTotalScore = targetDecimal * (currentTotalMax + nextAssignmentMax)
        let scoreNeeded = requiredTotalScore - currentTotalScore
        
        return scoreNeeded
    }
}
