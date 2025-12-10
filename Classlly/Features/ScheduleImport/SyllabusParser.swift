//
//  SyllabusParser.swift
//  Classlly
//
//  Created by Robu Darius on 11.12.2025.
//


import Foundation
import PDFKit
import GoogleGenerativeAI

class SyllabusParser {
    
    // Replace with your actual API key storage mechanism
    private let apiKey = "YOUR_KEY"
    
    // MARK: - Public Methods
    
    /// Extracts raw text from a PDF file URL.
    func extractText(from url: URL) -> String {
        guard let pdfDocument = PDFDocument(url: url) else {
            return ""
        }
        
        var fullText = ""
        let pageCount = pdfDocument.pageCount
        
        for i in 0..<pageCount {
            if let page = pdfDocument.page(at: i), let pageText = page.string {
                fullText += pageText + "\n"
            }
        }
        
        return fullText
    }
    
    /// Sends text to Gemini and parses the JSON response into SwiftData models.
    func parseSyllabus(text: String) async throws -> [ClassEvent] {
        let model = GenerativeModel(name: "gemini-1.5-flash", apiKey: apiKey)
        
        let systemPrompt = """
        You are a strict Data Extraction API. Analyze the input text. Extract the Course Name, Professor, and all Schedule Events (Exams, Assignments, Quizzes). Rules:
        Return ONLY raw JSON. No markdown.
        Convert all dates to 'YYYY-MM-DD'. If year is missing, infer the next occurrence based on the current academic year.
        JSON Structure: { 'courseName': String, 'events': [{ 'title': String, 'type': 'Exam|Assignment|Quiz', 'date': 'YYYY-MM-DD', 'weight': Int }] }
        """
        
        // Combine prompt with input text
        let prompt = "\(systemPrompt)\n\nInput Syllabus Text:\n\(text)"
        
        do {
            let response = try await model.generateContent(prompt)
            
            guard let outputText = response.text else {
                throw ParsingError.noOutput
            }
            
            // Clean the output (remove ```json and ``` markdown if present)
            let cleanJSON = cleanJSONString(outputText)
            
            guard let data = cleanJSON.data(using: .utf8) else {
                throw ParsingError.invalidData
            }
            
            // Decode
            let decoder = JSONDecoder()
            let syllabusResponse = try decoder.decode(SyllabusResponse.self, from: data)
            
            // Map to SwiftData models
            return syllabusResponse.toSwiftDataModels()
            
        } catch {
            print("Gemini Parsing Error: \(error)")
            throw error
        }
    }
    
    // MARK: - Helpers
    
    private func cleanJSONString(_ input: String) -> String {
        var clean = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove Markdown code block syntax if present
        if clean.hasPrefix("```json") {
            clean = clean.replacingOccurrences(of: "```json", with: "")
        } else if clean.hasPrefix("```") {
            clean = clean.replacingOccurrences(of: "```", with: "")
        }
        
        if clean.hasSuffix("```") {
            clean = clean.replacingOccurrences(of: "```", with: "")
        }
        
        return clean.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    enum ParsingError: Error {
        case noOutput
        case invalidData
    }
}