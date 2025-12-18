import SwiftUI
import Combine

// MARK: - DATA MODELS
struct AcademicEventData: Identifiable, Codable {
    var id = UUID()
    var start: String // Format: "yyyy-MM-dd"
    var end: String
    var type: EventType
    var weeks: Int
    var customName: String?
    
    // Teaching weeks specific
    var teachingWeekIndexStart: Int?
    var teachingWeekIndexEnd: Int?
}

enum EventType: String, Codable, CaseIterable {
    case teaching = "Teaching"
    case holiday = "Holiday"
    case exam = "Exam"
    case assessment = "Assessment"
    case other = "Other"
    
    var iconName: String {
        switch self {
        case .teaching: return "book.fill"
        case .holiday: return "sun.max.fill"
        case .exam: return "doc.text.fill"
        case .assessment: return "pencil.and.outline"
        case .other: return "calendar"
        }
    }
    
    var color: Color {
        switch self {
        case .teaching: return .blue
        case .holiday: return .green
        case .exam: return .red
        case .assessment: return .orange
        case .other: return .gray
        }
    }
}

struct SemesterData: Codable {
    var events: [AcademicEventData]
}

struct AcademicCalendarData: Identifiable, Codable {
    var id = UUID()
    var academicYear: String // e.g., "2024-2025"
    var universityName: String?
    var customName: String?
    var semester1: SemesterData
    var semester2: SemesterData
}

enum CalendarTemplate: String, CaseIterable, Identifiable {
    case ukStandard = "UK Standard (Sep-Jun)"
    case usStandard = "US Standard (Aug-May)"
    case ausStandard = "Australian (Feb-Nov)"
    case custom = "Empty Template"
    
    var id: String { self.rawValue }
}

// MARK: - MANAGER
class AcademicCalendarManager: ObservableObject {
    // ✅ Singleton Instance (Fixes ClassllyApp error)
    static let shared = AcademicCalendarManager()
    
    // Published Properties
    @Published var currentAcademicYear: AcademicCalendarData?
    @Published var availableCalendars: [AcademicCalendarData] = []
    
    // Legacy support for older views using direct dates
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Date()
    @Published var currentSemester: SemesterType = .fall
    
    enum SemesterType: String {
        case fall = "Fall Semester"
        case spring = "Spring Semester"
        case semester1 = "Semester 1"
        case semester2 = "Semester 2"
        var displayName: String { self.rawValue }
    }
    
    init() {
        // Load demo data if empty
        if availableCalendars.isEmpty {
            loadDemoData()
        }
    }
    
    // ✅ HELPER FUNCTIONS
    
    func loadDemoData() {
        let demo = createNewCalendar(year: "2024-2025", universityName: "Demo Uni", customName: "Demo Calendar")
        self.availableCalendars = [demo]
        self.currentAcademicYear = demo
        updateLegacyDates()
    }
    
    func createNewCalendar(year: String, universityName: String, customName: String) -> AcademicCalendarData {
        // Create basic structure
        return AcademicCalendarData(
            academicYear: year,
            universityName: universityName,
            customName: customName,
            semester1: SemesterData(events: []),
            semester2: SemesterData(events: [])
        )
    }
    
    func addCustomCalendar(_ calendar: AcademicCalendarData) {
        availableCalendars.append(calendar)
    }
    
    func setCurrentCalendar(_ calendar: AcademicCalendarData) {
        currentAcademicYear = calendar
        updateLegacyDates()
    }
    
    func deleteCalendar(_ calendar: AcademicCalendarData) {
        availableCalendars.removeAll { $0.id == calendar.id }
        if currentAcademicYear?.id == calendar.id {
            currentAcademicYear = availableCalendars.first
        }
    }
    
    func updateCalendar(_ calendar: AcademicCalendarData) {
        if let index = availableCalendars.firstIndex(where: { $0.id == calendar.id }) {
            availableCalendars[index] = calendar
            if currentAcademicYear?.id == calendar.id {
                currentAcademicYear = calendar
            }
        }
    }
    
    // Legacy support updater
    private func updateLegacyDates() {
        // Set generic dates based on current calendar or defaults
        let now = Date()
        self.startDate = Calendar.current.date(byAdding: .month, value: -2, to: now) ?? now
        self.endDate = Calendar.current.date(byAdding: .month, value: 4, to: now) ?? now
    }
    
    // Helper to get events for specific semester enum
    func getSemesterEvents(_ type: SemesterType) -> [AcademicEventData] {
        guard let calendar = currentAcademicYear else { return [] }
        switch type {
        case .semester1, .fall: return calendar.semester1.events
        case .semester2, .spring: return calendar.semester2.events
        }
    }
    
    // Helper to find which event is active today
    func getCurrentEvent(for date: Date) -> AcademicEventData? {
        // Simplified logic: checks all events in current calendar
        guard let calendar = currentAcademicYear else { return nil }
        let allEvents = calendar.semester1.events + calendar.semester2.events
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        return allEvents.first { event in
            guard let start = formatter.date(from: event.start),
                  let end = formatter.date(from: event.end) else { return false }
            return date >= start && date <= end
        }
    }
    
    var currentTeachingWeek: Int? {
        // Logic to calculate week based on current event
        guard let event = getCurrentEvent(for: Date()), event.type == .teaching, let startIdx = event.teachingWeekIndexStart else { return nil }
        // Simple calculation for demo
        return startIdx
    }
    
    // Specific helpers needed for Onboarding
    var semesterStartDate: Date { startDate }
    var semesterEndDate: Date { endDate }
}
