//
//  Subject+Calendar.swift
//  Classlly
//
//  Created by Robu Darius on 17.12.2025.
//

import Foundation

extension Subject {
    
    // MARK: - Frequency Strings
    var courseFrequencyString: String {
        return courseFrequency.rawValue
    }
    
    var seminarFrequencyString: String {
        return seminarFrequency.rawValue
    }
    
    // MARK: - Calendar Logic
    
    /// Checks if the subject (Course or Seminar) occurs during the week of the provided date.
    /// Handles Bi-Weekly logic based on Week of Year.
    func occursThisWeek(date: Date, isSeminar: Bool = false) -> Bool {
        let frequency = isSeminar ? seminarFrequency : courseFrequency
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: date)
        
        // If it's a specific "One Time" event, we check if the dates match
        if frequency == .oneTime {
            // Safely unwrap the optional dates
            guard let targetDate = isSeminar ? seminarStartTime : courseStartTime else {
                return false
            }
            return calendar.isDate(date, equalTo: targetDate, toGranularity: .weekOfYear)
        }
        
        switch frequency {
        case .weekly:
            return true
        case .biweeklyOdd:
            // Returns true if week number is ODD (1, 3, 5...)
            return weekOfYear % 2 != 0
        case .biweeklyEven:
            // Returns true if week number is EVEN (2, 4, 6...)
            return weekOfYear % 2 == 0
        case .oneTime:
            return false // Handled above
        }
    }
    
    /// Helper to check if it occurs on a specific Day of Week (e.g., Monday)
    func occursOnDay(day: Int, isSeminar: Bool = false) -> Bool {
        let days = isSeminar ? seminarDays : courseDays
        return days.contains(day)
    }
}
