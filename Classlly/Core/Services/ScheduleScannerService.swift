//
//  ScheduleScannerService.swift
//  Classlly
//
//  Created by Robu Darius on 09.12.2025.
//


import Vision
import UIKit

class ScheduleScannerService {
    static let shared = ScheduleScannerService()
    
    private init() {}
    
    /// Scans an image for text and filters for potential class schedule entries.
    /// - Parameter image: The source image (from camera or library)
    /// - Returns: An array of `ScannedClassCandidate` structs
    func scanImage(_ image: UIImage) async throws -> [ScannedClassCandidate] {
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: NSError(domain: "ScheduleScanner", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Image Format"]))
                return
            }
            
            // Create the Vision request
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                // Process results on a background thread if needed, but the continuation handles the return
                let candidates = self.processObservations(observations)
                continuation.resume(returning: candidates)
            }
            
            // "Accurate" is slower but better for small text in schedules
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Parses raw Vision observations into structured candidates using Regex
    private func processObservations(_ observations: [VNRecognizedTextObservation]) -> [ScannedClassCandidate] {
        var candidates: [ScannedClassCandidate] = []
        
        // REGEX: Looks for time patterns like "10:00", "9:30", "14:00"
        // This helps filter out noise (headers, page numbers, footer text)
        let timePattern = #"(\d{1,2}:\d{2})"#
        
        for observation in observations {
            // Get the best candidate string for this line of text
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            let text = topCandidate.string
            
            // Check if this line contains a time. If so, it's likely a class.
            if let range = text.range(of: timePattern, options: .regularExpression) {
                let timeString = String(text[range])
                
                // Extract the title by removing the time string and trimming whitespace
                // Example Raw: "10:00 Calculus I Room 301" -> Title: "Calculus I Room 301"
                let title = text.replacingOccurrences(of: timeString, with: "")
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Handle edge case where title might be empty
                let cleanTitle = title.isEmpty ? "Detected Class" : title
                
                let candidate = ScannedClassCandidate(
                    rawText: text,
                    detectedTitle: cleanTitle,
                    detectedTime: timeString,
                    isSelected: true
                )
                candidates.append(candidate)
            }
        }
        
        return candidates
    }
}