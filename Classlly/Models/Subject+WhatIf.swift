//
//  Subject+WhatIf.swift
//  Classlly
//
//  Created by Robu Darius on 11.12.2025.
//


import Foundation

extension Subject {
    
    /// Calculates the grade required on a new assignment to reach a target average.
    /// - Parameters:
    ///   - targetGrade: The overall average the student wants to achieve (e.g., 9.5).
    ///   - newItemWeight: The weight of the upcoming exam/assignment (e.g., 40.0 for 40%).
    /// - Returns: The specific grade required (e.g., 8.7). Returns nil if inputs are invalid.
    func calculateRequiredGrade(targetGrade: Double, newItemWeight: Double) -> Double? {
        // Guard against zero weight division
        guard newItemWeight > 0 else { return nil }
        
        // 1. Calculate Current State
        let grades = gradeHistory ?? []
        
        // If there are no grades yet, the required grade is simply the target
        // (Assuming the new item is the only thing that matters, or mathematically treating past weight as 0)
        if grades.isEmpty {
            return targetGrade
        }
        
        let currentWeightedSum = grades.reduce(0.0) { $0 + ($1.grade * $1.weight) }
        let currentTotalWeight = grades.reduce(0.0) { $0 + $1.weight }
        
        // 2. The Formula
        // (CurrentSum + (Required * NewWeight)) / (CurrentTotalWeight + NewWeight) = Target
        // CurrentSum + (Required * NewWeight) = Target * (CurrentTotalWeight + NewWeight)
        // Required * NewWeight = (Target * (CurrentTotalWeight + NewWeight)) - CurrentSum
        // Required = ((Target * (CurrentTotalWeight + NewWeight)) - CurrentSum) / NewWeight
        
        let numerator = (targetGrade * (currentTotalWeight + newItemWeight)) - currentWeightedSum
        let requiredGrade = numerator / newItemWeight
        
        return requiredGrade
    }
}