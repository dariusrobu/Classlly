//
//  ScannedClassCandidate.swift
//  Classlly
//
//  Created by Robu Darius on 09.12.2025.
//


import Foundation

/// A temporary staging model for classes detected by the OCR scanner.
/// Users can edit this data before committing it to the permanent SwiftData store.
struct ScannedClassCandidate: Identifiable, Equatable {
    let id = UUID()
    
    /// The full line of text recognized by Vision
    let rawText: String
    
    /// The detected subject name (editable by user)
    var detectedTitle: String
    
    /// The detected time string (e.g., "14:30", editable by user)
    var detectedTime: String
    
    /// Whether this class should be imported (default true)
    var isSelected: Bool = true
}