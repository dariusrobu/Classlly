//
//  Subject+WhatIf.swift
//  Classlly
//
//  Created by Robu Darius on 15.12.2025.
//


import Foundation

extension Subject {
    /// Calculates the grade required on a new item (e.g. exam) to reach a target average.
    /// - Parameters:
    ///   - targetGrade: The goal average (e.g., 9.5).
    ///   - newItemWeight: The weight of the new item in percentage (e.g., 40 for 40%).
    /// - Returns: The required grade, or nil if calculation is invalid.
    func calculateRequiredGrade(targetGrade: Double, newItemWeight: Double) -> Double? {
        let grades = gradeHistory ?? []
        
        // 1. Calculate current state
        let currentWeightedSum = grades.reduce(0.0) { $0 + ($1.grade * $1.weight) }
        let currentTotalWeight = grades.reduce(0.0) { $0 + $1.weight }
        
        // 2. Prevent division by zero
        guard newItemWeight > 0 else { return nil }
        
        // 3. The Math
        // Formula: (CurrentSum + (Required * NewWeight)) / (CurrentWeight + NewWeight) = Target
        // Rearranged: Required = ((Target * (CurrentWeight + NewWeight)) - CurrentSum) / NewWeight
        
        let newTotalWeight = currentTotalWeight + newItemWeight
        let requiredMetric = (targetGrade * newTotalWeight) - currentWeightedSum
        let requiredGrade = requiredMetric / newItemWeight
        
        return requiredGrade
    }
}