//
//  CalendarDataService.swift
//  Classlly
//
//  Created by Robu Darius on 24.12.2025.
//


import Foundation
import OSLog

/// A thread-safe, actor-based service for fetching academic calendar data.
/// Handles network interactions and strictly validates JSON responses.
actor CalendarDataService {
    
    // MARK: - Properties
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "CalendarDataService")
    private let session: URLSession
    private let jsonDecoder: JSONDecoder
    
    // MARK: - Initialization
    init(session: URLSession = .shared) {
        self.session = session
        self.jsonDecoder = JSONDecoder()
        // Configure decoder for specific date formats if necessary
        // self.jsonDecoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Public API
    
    /// Fetches calendar data from the remote API.
    /// - Returns: An array of `AcademicCalendar` objects (DTOs).
    func fetchCalendars() async throws -> [AcademicCalendar] {
        // Updated URL from your logs
        guard let url = URL(string: "https://fsega-4hgketyi6-robus-projects-a31a9e42.vercel.app/api/academic_calendars") else {
            throw CalendarServiceError.invalidURL
        }
        
        logger.info("🌍 Fetching calendars from: \(url.absoluteString)")
        
        let (data, response) = try await session.data(from: url)
        
        // 1. Validate HTTP Response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CalendarServiceError.invalidResponse
        }
        
        // 2. Handle Status Codes explicitly
        guard (200...299).contains(httpResponse.statusCode) else {
            logger.error("📄 Server returned error code: \(httpResponse.statusCode)")
            
            // Log the raw body for debugging (handles the "NOT_FOUND" HTML case)
            if let responseString = String(data: data, encoding: .utf8) {
                logger.debug("Server Response Body: \(responseString)")
            }
            
            if httpResponse.statusCode == 404 {
                throw CalendarServiceError.resourceNotFound
            } else {
                throw CalendarServiceError.serverError(statusCode: httpResponse.statusCode)
            }
        }
        
        // 3. Attempt Decoding
        do {
            let calendars = try jsonDecoder.decode([AcademicCalendar].self, from: data)
            logger.info("✅ Successfully decoded \(calendars.count) calendars.")
            return calendars
        } catch let decodingError as DecodingError {
            logger.error("❌ JSON Parsing Error: \(decodingError.localizedDescription)")
            
            // Print detailed context for debugging
            switch decodingError {
            case .dataCorrupted(let context):
                logger.error("Context: \(context.debugDescription)")
            case .keyNotFound(let key, let context):
                logger.error("Key '\(key.stringValue)' not found: \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                logger.error("Type '\(type)' mismatch: \(context.debugDescription)")
            case .valueNotFound(let value, let context):
                logger.error("Value '\(value)' not found: \(context.debugDescription)")
            @unknown default:
                break
            }
            throw CalendarServiceError.decodingFailed(decodingError)
        } catch {
            throw error
        }
    }
}

// MARK: - Error Types
enum CalendarServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case resourceNotFound
    case serverError(statusCode: Int)
    case decodingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The URL provided was invalid."
        case .invalidResponse: return "Received an invalid network response."
        case .resourceNotFound: return "The calendar API endpoint could not be found (404)."
        case .serverError(let code): return "Server error occurred with code: \(code)."
        case .decodingFailed: return "Failed to process the data from the server."
        }
    }
}