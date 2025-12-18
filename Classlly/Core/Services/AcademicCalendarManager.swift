import SwiftUI
import Combine

class AcademicCalendarManager: ObservableObject {
    static let shared = AcademicCalendarManager()
    
    // Published Properties
    @Published var currentAcademicYear: AcademicCalendarData?
    @Published var availableCalendars: [AcademicCalendarData] = []
    
    // ✅ FIX: Added templates for OnboardingView
    @Published var availableTemplates: [CalendarTemplate] = [
        CalendarTemplate(
            universityName: "University of Nottingham",
            academicYear: "2024-2025",
            sem1Start: "2024-09-23", sem1End: "2025-01-24",
            sem2Start: "2025-01-27", sem2End: "2025-06-20"
        ),
        CalendarTemplate(
            universityName: "University of Bristol",
            academicYear: "2024-2025",
            sem1Start: "2024-09-16", sem1End: "2025-01-17",
            sem2Start: "2025-01-20", sem2End: "2025-06-06"
        ),
        CalendarTemplate(
            universityName: "University of Manchester",
            academicYear: "2024-2025",
            sem1Start: "2024-09-16", sem1End: "2025-01-24",
            sem2Start: "2025-01-27", sem2End: "2025-06-06"
        )
    ]
    
    // Legacy support
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
        if availableCalendars.isEmpty {
            loadDemoData()
        }
    }
    
    // MARK: - Template Generation (Onboarding Support)
    
    func generateAndSaveCalendar(from template: CalendarTemplate) {
        let newCalendar = AcademicCalendarData(
            academicYear: template.academicYear,
            universityName: template.universityName,
            customName: template.universityName,
            semester1: createSemester(start: template.sem1Start, end: template.sem1End),
            semester2: createSemester(start: template.sem2Start, end: template.sem2End)
        )
        addCustomCalendar(newCalendar)
        setCurrentCalendar(newCalendar)
    }
    
    func generateAndSaveCustomCalendar(year: String, universityName: String, sem1Start: Date, sem1End: Date, sem2Start: Date, sem2End: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let newCalendar = AcademicCalendarData(
            academicYear: year,
            universityName: universityName,
            customName: "\(universityName) Custom",
            semester1: createSemester(start: formatter.string(from: sem1Start), end: formatter.string(from: sem1End)),
            semester2: createSemester(start: formatter.string(from: sem2Start), end: formatter.string(from: sem2End))
        )
        addCustomCalendar(newCalendar)
        setCurrentCalendar(newCalendar)
    }
    
    private func createSemester(start: String, end: String) -> SemesterData {
        // Create a default teaching block for the semester
        let events = [
            AcademicEventData(
                start: start,
                end: end,
                type: .teaching,
                weeks: 12,
                customName: "Teaching Term",
                teachingWeekIndexStart: 1,
                teachingWeekIndexEnd: 12
            )
        ]
        return SemesterData(events: events)
    }
    
    // MARK: - Basic Management
    
    func loadDemoData() {
        let demo = createNewCalendar(year: "2024-2025", universityName: "Demo Uni", customName: "Demo Calendar")
        self.availableCalendars = [demo]
        self.currentAcademicYear = demo
        updateLegacyDates()
    }
    
    func createNewCalendar(year: String, universityName: String, customName: String) -> AcademicCalendarData {
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
    
    private func updateLegacyDates() {
        let now = Date()
        self.startDate = Calendar.current.date(byAdding: .month, value: -2, to: now) ?? now
        self.endDate = Calendar.current.date(byAdding: .month, value: 4, to: now) ?? now
    }
    
    // MARK: - Helpers
    
    func getSemesterEvents(_ type: SemesterType) -> [AcademicEventData] {
        guard let calendar = currentAcademicYear else { return [] }
        switch type {
        case .semester1, .fall: return calendar.semester1.events
        case .semester2, .spring: return calendar.semester2.events
        }
    }
    
    func getCurrentEvent(for date: Date) -> AcademicEventData? {
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
        guard let event = getCurrentEvent(for: Date()), event.type == .teaching, let startIdx = event.teachingWeekIndexStart else { return nil }
        return startIdx
    }
    
    var semesterStartDate: Date { startDate }
    var semesterEndDate: Date { endDate }
}
