import SwiftUI
import GoogleGenerativeAI
import Combine

class ScheduleScannerService {
    static let shared = ScheduleScannerService()
    
    // 🔴 Your API Key
    private let apiKey = "AIzaSyBgevtBBEQzcUtffH11ZC6XltCT4cYzrA8"
    
    // SWITCHED TO PRO: Flash was returning 404. Pro is more stable for complex OCR.
    private let modelName = "gemini-1.5-pro"
    
    private init() {}
    
    func scanImage(_ image: UIImage) async throws -> [ScannedClassCandidate] {
        let model = GenerativeModel(name: modelName, apiKey: apiKey)
        
        // Compress image to ensure it fits within payload limits
        guard let imageData = image.jpegData(compressionQuality: 0.5),
              let optimizedImage = UIImage(data: imageData) else {
            throw ScannerError.invalidImage
        }
        
        let prompt = """
        You are a Data Extraction AI. Analyze this academic timetable image.
        Extract every class event into a JSON Array.
        
        Rules:
        1. Identify the Day (e.g., Luni/Monday).
        2. Identify Start/End Times (format: HH:mm).
        3. Identify Subject Title.
        4. Identify Type (Course, Seminar, Lab).
        5. Identify Room.
        6. Identify Teacher Name.
        7. Identify Frequency: "Odd", "Even", or "Weekly".
        
        Return ONLY raw JSON. No markdown (no ```json).
        
        JSON Structure:
        [
          { "day": "Monday", "start": "08:00", "end": "10:00", "title": "Math", "type": "Course", "room": "101", "teacher": "Prof. X", "frequency": "Weekly" }
        ]
        """
        
        do {
            let response = try await model.generateContent(prompt, optimizedImage)
            
            guard let text = response.text else {
                throw ScannerError.noOutput
            }
            
            let cleanJSON = cleanJSONString(text)
            guard let data = cleanJSON.data(using: .utf8) else {
                throw ScannerError.invalidData
            }
            
            let decoder = JSONDecoder()
            let rawEvents = try decoder.decode([GeminiTimetableEvent].self, from: data)
            
            return mapToCandidates(rawEvents)
            
        } catch {
            print("Gemini Error: \(error)")
            throw error
        }
    }
    
    // MARK: - Helpers
    
    private func cleanJSONString(_ input: String) -> String {
        var clean = input.trimmingCharacters(in: .whitespacesAndNewlines)
        clean = clean.replacingOccurrences(of: "```json", with: "")
        clean = clean.replacingOccurrences(of: "```", with: "")
        return clean
    }
    
    private func mapToCandidates(_ events: [GeminiTimetableEvent]) -> [ScannedClassCandidate] {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.defaultDate = Calendar.current.startOfDay(for: Date())
        
        return events.compactMap { event in
            guard let startTime = timeFormatter.date(from: event.start),
                  let endTime = timeFormatter.date(from: event.end) else { return nil }
            
            var classType: ClassType = .course
            let lowerType = event.type.lowercased()
            if lowerType.contains("sem") { classType = .seminar }
            else if lowerType.contains("lab") { classType = .lab }
            
            return ScannedClassCandidate(
                day: event.day,
                startTime: startTime,
                endTime: endTime,
                title: event.title,
                room: event.room,
                teacher: event.teacher,
                type: classType,
                weekRestriction: event.frequency
            )
        }
    }
    
    enum ScannerError: Error {
        case invalidImage
        case noOutput
        case invalidData
    }
}

struct GeminiTimetableEvent: Codable {
    let day: String
    let start: String
    let end: String
    let title: String
    let type: String
    let room: String
    let teacher: String
    let frequency: String
}
