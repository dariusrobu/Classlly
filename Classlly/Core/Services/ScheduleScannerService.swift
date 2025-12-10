import Vision
import UIKit

class ScheduleScannerService {
    static let shared = ScheduleScannerService()
    
    private init() {}
    
    // MARK: - 1. OCR Stage
    func scanImage(_ image: UIImage) async throws -> [ScannedClassCandidate] {
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: NSError(domain: "Scanner", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Image"]))
                return
            }
            
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                // Start Pipeline Step 2
                let candidates = self.parseObservations(observations)
                continuation.resume(returning: candidates)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
    
    // MARK: - 2. Parsing Pipeline
    private func parseObservations(_ observations: [VNRecognizedTextObservation]) -> [ScannedClassCandidate] {
        var candidates: [ScannedClassCandidate] = []
        
        // Sort text by vertical position (top to bottom), then horizontal (left to right)
        // This helps reconstruct the visual flow of the timetable.
        let sortedObservations = observations.sorted {
            if abs($0.boundingBox.minY - $1.boundingBox.minY) < 0.02 { // Same line tolerance
                return $0.boundingBox.minX < $1.boundingBox.minX
            }
            return $0.boundingBox.minY > $1.boundingBox.minY // Vision Y is flipped (0 is bottom)
        }
        
        // Working variables for "State Machine" parsing
        var currentDay = "Monday"
        var lastTime: (start: Date, end: Date)? = nil
        
        // Regex Patterns
        let timePattern = #"(\d{1,2}[:.]\d{2})\s*[-–]\s*(\d{1,2}[:.]\d{2})"# // Matches 10:00 - 12:00
        let dayPattern = #"(?i)^(Mon|Tue|Wed|Thu|Fri|Sat|Sun|Luni|Marti|Miercuri|Joi|Vineri)"#
        let roomPattern = #"(?i)(Room|Sala|Amphitheater|Lab)\s*[\w\d]+"#
        
        for obs in sortedObservations {
            guard let candidate = obs.topCandidates(1).first else { continue }
            let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // A. Detect Day Headers
            if let dayMatch = text.range(of: dayPattern, options: .regularExpression) {
                currentDay = String(text[dayMatch]).capitalized
                continue // It's just a header, skip creation
            }
            
            // B. Detect Time Blocks
            if let timeRange = extractTimeRange(from: text, pattern: timePattern) {
                lastTime = timeRange
                
                // If the line ALSO contains text, it's a "One-Liner" (e.g., "10:00 - 12:00 Math")
                let cleanText = text.replacingOccurrences(of: timePattern, with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !cleanText.isEmpty {
                    let parsed = parseClassDetails(rawText: cleanText, day: currentDay, time: timeRange)
                    candidates.append(parsed)
                }
                continue
            }
            
            // C. Contextual Association (No time on this line?)
            // If we have a recent time but no text, THIS line is likely the Subject/Details
            if let activeTime = lastTime, !text.isEmpty {
                // Heuristic: If text is short or looks like metadata, append to previous candidate if possible
                // For now, we treat it as a new class entry for that time slot
                let parsed = parseClassDetails(rawText: text, day: currentDay, time: activeTime)
                
                // Merge logic: If previous candidate has same time but generic title, maybe this is the real title?
                // Simplifying: Just add it. User can delete duplicates.
                candidates.append(parsed)
                
                // Reset time to avoid applying 10:00 to every subsequent line forever
                lastTime = nil
            }
        }
        
        return detectConflicts(candidates)
    }
    
    // MARK: - 3. Detail Extraction Logic
    private func parseClassDetails(rawText: String, day: String, time: (Date, Date)) -> ScannedClassCandidate {
        var subject = rawText
        var room = ""
        var teacher = ""
        var type: ClassType = .course
        var isOptional = false
        var restriction = ""
        
        // 1. Detect Type
        if rawText.localizedCaseInsensitiveContains("Seminar") || rawText.contains("Sem.") { type = .seminar }
        else if rawText.localizedCaseInsensitiveContains("Lab") || rawText.localizedCaseInsensitiveContains("L.") { type = .lab }
        else if rawText.localizedCaseInsensitiveContains("Online") { type = .online }
        
        // 2. Detect Room (Simple heuristic: look for alphanumeric codes at end or specific keywords)
        // This is a naive implementation; in production, use stronger Regex
        let tokens = rawText.components(separatedBy: " ")
        if let roomIndex = tokens.firstIndex(where: { $0.lowercased().contains("room") || $0.lowercased().contains("sala") }) {
            if roomIndex + 1 < tokens.count {
                room = "\(tokens[roomIndex]) \(tokens[roomIndex+1])"
                // Remove room from subject
                subject = subject.replacingOccurrences(of: room, with: "")
            }
        }
        
        // 3. Detect Optional
        if rawText.localizedCaseInsensitiveContains("optional") || rawText.contains("(*)") {
            isOptional = true
        }
        
        // 4. Detect Week Restriction (Odd/Even/SI/SP)
        if rawText.contains("s.i") || rawText.contains("odd") { restriction = "Odd Weeks" }
        if rawText.contains("s.p") || rawText.contains("even") { restriction = "Even Weeks" }
        
        // Clean up Subject Title
        subject = subject
            .replacingOccurrences(of: "Seminar", with: "")
            .replacingOccurrences(of: "Lab", with: "")
            .trimmingCharacters(in: .punctuationCharacters)
            .trimmingCharacters(in: .whitespaces)
        
        return ScannedClassCandidate(
            rawText: rawText,
            day: day,
            startTime: time.0,
            endTime: time.1,
            title: subject.isEmpty ? "Unknown Subject" : subject,
            room: room,
            teacher: teacher,
            type: type,
            weekRestriction: restriction,
            isOptional: isOptional
        )
    }
    
    // MARK: - Helpers
    private func extractTimeRange(from text: String, pattern: String) -> (Date, Date)? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsString = text as NSString
        let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
        
        if let match = results.first {
            let startString = nsString.substring(with: match.range(at: 1))
            let endString = nsString.substring(with: match.range(at: 2))
            
            // Normalize separators (. or :)
            let fmt = DateFormatter()
            fmt.dateFormat = "HH:mm"
            
            let cleanStart = startString.replacingOccurrences(of: ".", with: ":")
            let cleanEnd = endString.replacingOccurrences(of: ".", with: ":")
            
            if let s = fmt.date(from: cleanStart), let e = fmt.date(from: cleanEnd) {
                return (s, e)
            }
        }
        return nil
    }
    
    private func detectConflicts(_ candidates: [ScannedClassCandidate]) -> [ScannedClassCandidate] {
        var processed = candidates
        // Naive O(N^2) check - acceptable for schedule sizes (~20 items)
        for i in 0..<processed.count {
            for j in (i+1)..<processed.count {
                if processed[i].day == processed[j].day {
                    // Check overlap
                    if processed[i].startTime < processed[j].endTime && processed[i].endTime > processed[j].startTime {
                        processed[i].hasConflict = true
                        processed[j].hasConflict = true
                    }
                }
            }
        }
        return processed
    }
}
