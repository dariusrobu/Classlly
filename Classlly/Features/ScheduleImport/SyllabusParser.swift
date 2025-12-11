import Foundation
import PDFKit
import GoogleGenerativeAI

class SyllabusParser {
    
    private let apiKey = "AIzaSyBgevtBBEQzcUtffH11ZC6XltCT4cYzrA8"
    
    // Using Pro model
    private let modelName = "gemini-1.5-pro"
    
    func extractText(from url: URL) -> String {
        guard let pdfDocument = PDFDocument(url: url) else { return "" }
        var fullText = ""
        for i in 0..<pdfDocument.pageCount {
            fullText += (pdfDocument.page(at: i)?.string ?? "") + "\n"
        }
        return fullText
    }
    
    func parseSyllabus(text: String) async throws -> [ClassEvent] {
        let model = GenerativeModel(name: modelName, apiKey: apiKey)
        
        let systemPrompt = """
        You are a Data Extraction API. Extract Course Name and Schedule Events (Exams, Assignments).
        Return ONLY raw JSON. No markdown.
        Dates: YYYY-MM-DD.
        JSON: { 'courseName': String, 'events': [{ 'title': String, 'type': 'Exam|Assignment', 'date': 'YYYY-MM-DD', 'weight': Int }] }
        """
        
        let prompt = "\(systemPrompt)\n\nInput:\n\(text)"
        
        do {
            let response = try await model.generateContent(prompt)
            
            guard let outputText = response.text else { throw ParsingError.noOutput }
            
            let cleanJSON = cleanJSONString(outputText)
            guard let data = cleanJSON.data(using: .utf8) else { throw ParsingError.invalidData }
            
            let decoder = JSONDecoder()
            let syllabusResponse = try decoder.decode(SyllabusResponse.self, from: data)
            
            return syllabusResponse.toSwiftDataModels()
            
        } catch {
            print("Gemini Parsing Error: \(error)")
            throw error
        }
    }
    
    private func cleanJSONString(_ input: String) -> String {
        var clean = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("```json") { clean = clean.replacingOccurrences(of: "```json", with: "") }
        if clean.hasPrefix("```") { clean = clean.replacingOccurrences(of: "```", with: "") }
        if clean.hasSuffix("```") { clean = clean.replacingOccurrences(of: "```", with: "") }
        return clean.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    enum ParsingError: Error {
        case noOutput
        case invalidData
    }
}
