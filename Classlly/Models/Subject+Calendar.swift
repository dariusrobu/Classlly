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
            let targetDate = isSeminar ? seminarStartTime : courseStartTime
            return calendar.isDate(date, equalTo: targetDate, toGranularity: .weekOfYear)
        }
        
        switch frequency {
        case .weekly:
            return true
        case .biweekly:
            // Occurs every 2 weeks: treat odd weeks as true, even as false (or vice versa as per your original intent)
            return !weekOfYear.isMultiple(of: 2)
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
