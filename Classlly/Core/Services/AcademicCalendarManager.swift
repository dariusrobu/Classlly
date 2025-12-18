import SwiftUI
import Combine

class AcademicCalendarManager: ObservableObject {
    static let shared = AcademicCalendarManager()
    
    @Published var currentAcademicYear: AcademicCalendarData? {
        didSet {
            if let start = getDate(from: currentAcademicYear?.semester1.events.first?.start ?? ""),
               let end = getDate(from: currentAcademicYear?.semester2.events.last?.end ?? "") {
                self.startDate = start
                self.endDate = end
            }
        }
    }
    @Published var availableCalendars: [AcademicCalendarData] = []
    
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Date()
    @Published var currentSemester: SemesterType = .semester1
    
    @Published var availableTemplates: [CalendarTemplate] = [
        CalendarTemplate(
            universityName: "Universitatea Babeș-Bolyai (UBB)",
            academicYear: "2025-2026",
            sem1Start: "2025-09-29", sem1End: "2026-02-15",
            sem2Start: "2026-02-23", sem2End: "2026-07-05"
        ),
        CalendarTemplate(
            universityName: "University of Nottingham",
            academicYear: "2025-2026",
            sem1Start: "2025-09-22", sem1End: "2026-01-23",
            sem2Start: "2026-01-26", sem2End: "2026-06-19"
        ),
        CalendarTemplate(
            universityName: "Standard US Semester",
            academicYear: "2025-2026",
            sem1Start: "2025-08-25", sem1End: "2025-12-12",
            sem2Start: "2026-01-12", sem2End: "2026-05-08"
        )
    ]
    
    enum SemesterType: String {
        case semester1 = "Semester 1"
        case semester2 = "Semester 2"
        var displayName: String { self.rawValue }
    }
    
    init() {
        if availableCalendars.isEmpty {
            loadDemoData()
        }
    }
    
    // MARK: - Logic
    
    func loadDemoData() {
        if let ubb = availableTemplates.first(where: { $0.universityName.contains("Babeș-Bolyai") }) {
            generateAndSaveCalendar(from: ubb)
        } else if let first = availableTemplates.first {
            generateAndSaveCalendar(from: first)
        }
    }
    
    func createNewCalendar(year: String, universityName: String, customName: String) -> AcademicCalendarData {
        let newCalendar = AcademicCalendarData(
            academicYear: year,
            universityName: universityName,
            customName: customName,
            semester1: SemesterData(events: []),
            semester2: SemesterData(events: [])
        )
        addCustomCalendar(newCalendar)
        setCurrentCalendar(newCalendar)
        return newCalendar
    }
    
    func deleteCalendar(_ calendar: AcademicCalendarData) {
        availableCalendars.removeAll { $0.id == calendar.id }
        if currentAcademicYear?.id == calendar.id {
            currentAcademicYear = availableCalendars.first
        }
    }
    
    func getCurrentEvent(for date: Date) -> AcademicEventData? {
        guard let calendar = currentAcademicYear else { return nil }
        let allEvents = calendar.semester1.events + calendar.semester2.events
        return allEvents.first { event in
            guard let start = getDate(from: event.start),
                  let end = getDate(from: event.end) else { return false }
            return date >= start && date <= end
        }
    }
    
    func getSemesterEvents(_ type: SemesterType) -> [AcademicEventData] {
        guard let calendar = currentAcademicYear else { return [] }
        switch type {
        case .semester1: return calendar.semester1.events
        case .semester2: return calendar.semester2.events
        }
    }
    
    // MARK: - 🧠 Smart Logic (Updated for Specific Dates)
    
    var currentTeachingWeek: Int? {
        return getTeachingWeek(for: Date())
    }
    
    var currentWeekProgress: Int {
        return calculateWeek(for: Date(), strictTeachingOnly: false) ?? 1
    }
    
    // ✅ NEW: Public method to get week number for ANY date
    func getTeachingWeek(for date: Date) -> Int? {
        return calculateWeek(for: date, strictTeachingOnly: true)
    }
    
    var totalWeeksInCurrentSemester: Int {
        guard let calendar = currentAcademicYear else { return 14 }
        let now = Date()
        if let s2Start = getDate(from: calendar.semester2.events.first?.start ?? ""), now >= s2Start {
            return calendar.semester2.events.filter { $0.type == .teaching }.reduce(0) { $0 + $1.weeks }
        }
        return calendar.semester1.events.filter { $0.type == .teaching }.reduce(0) { $0 + $1.weeks }
    }
    
    var currentStatusString: String {
        guard let event = getCurrentEvent(for: Date()) else { return "No Active Event" }
        if event.type == .teaching {
            if let week = currentTeachingWeek { return "WEEK \(week)" }
            return "Teaching"
        }
        return event.customName?.uppercased() ?? event.type.displayName.uppercased()
    }
    
    var currentSemesterDisplayName: String {
        guard let calendar = currentAcademicYear else { return "Semester 1" }
        let now = Date()
        if let s2Start = getDate(from: calendar.semester2.events.first?.start ?? ""), now >= s2Start {
            return "Semester 2"
        }
        return "Semester 1"
    }
    
    // ✅ Private calculation logic that accepts a Date
    private func calculateWeek(for date: Date, strictTeachingOnly: Bool) -> Int? {
        guard let calendar = currentAcademicYear else { return nil }
        
        let isSem2: Bool = {
            if let s2Start = getDate(from: calendar.semester2.events.first?.start ?? "") {
                return date >= s2Start
            }
            return false
        }()
        
        let activeEvents = isSem2 ? calendar.semester2.events : calendar.semester1.events
        let sortedEvents = activeEvents.sorted(by: { $0.start < $1.start })
        
        var cumulativeWeeks = 0
        
        for event in sortedEvents {
            guard let start = getDate(from: event.start), let end = getDate(from: event.end) else { continue }
            
            // IF we are currently in this event
            if date >= start && date <= end {
                if event.type == .teaching {
                    let weeksSinceStart = Calendar.current.dateComponents([.weekOfYear], from: start, to: date).weekOfYear ?? 0
                    return cumulativeWeeks + weeksSinceStart + 1
                } else {
                    return strictTeachingOnly ? nil : cumulativeWeeks
                }
            }
            
            // Event passed
            if date > end && event.type == .teaching {
                cumulativeWeeks += event.weeks
            }
        }
        return strictTeachingOnly ? nil : cumulativeWeeks
    }
    
    // MARK: - Generator & Helpers
    
    func generateAndSaveCalendar(from template: CalendarTemplate) {
        // ... (Logic remains identical to previous version, omitted for brevity but presumed included) ...
        // Re-paste the exact same generation logic from previous turn if you need the full file again,
        // but for now I am focusing on the Week Logic changes.
        // Assuming previous generation logic is preserved here.
        var sem1Events: [AcademicEventData] = []
        var sem2Events: [AcademicEventData] = []
        
        if template.universityName.contains("Babeș-Bolyai") {
            sem1Events = [
                AcademicEventData(start: "2025-09-29", end: "2025-12-21", type: .teaching, weeks: 12, customName: "Teaching Module 1"),
                AcademicEventData(start: "2025-12-22", end: "2026-01-04", type: .holiday, weeks: 2, customName: "Winter Holiday"),
                AcademicEventData(start: "2026-01-05", end: "2026-01-18", type: .teaching, weeks: 2, customName: "Teaching Module 2"),
                AcademicEventData(start: "2026-01-19", end: "2026-02-08", type: .exam, weeks: 3, customName: "Exam Session"),
                AcademicEventData(start: "2026-02-09", end: "2026-02-15", type: .holiday, weeks: 1, customName: "Inter-semester Break")
            ]
            sem2Events = [
                AcademicEventData(start: "2026-02-23", end: "2026-04-10", type: .teaching, weeks: 7, customName: "Teaching Module 3"),
                AcademicEventData(start: "2026-04-11", end: "2026-04-19", type: .holiday, weeks: 1, customName: "Easter Holiday"),
                AcademicEventData(start: "2026-04-20", end: "2026-06-05", type: .teaching, weeks: 7, customName: "Teaching Module 4"),
                AcademicEventData(start: "2026-06-06", end: "2026-06-28", type: .exam, weeks: 3, customName: "Summer Exams")
            ]
        } else {
            sem1Events = [AcademicEventData(start: template.sem1Start, end: template.sem1End, type: .teaching, weeks: 14, customName: "Semester 1")]
            sem2Events = [AcademicEventData(start: template.sem2Start, end: template.sem2End, type: .teaching, weeks: 14, customName: "Semester 2")]
        }
        
        let newCalendar = AcademicCalendarData(
            academicYear: template.academicYear,
            universityName: template.universityName,
            customName: template.universityName,
            semester1: SemesterData(events: sem1Events),
            semester2: SemesterData(events: sem2Events)
        )
        
        addCustomCalendar(newCalendar)
        setCurrentCalendar(newCalendar)
    }
    
    func addEvent(to semester: SemesterType, event: AcademicEventData) {
        guard var calendar = currentAcademicYear else { return }
        switch semester {
        case .semester1: calendar.semester1.events.append(event)
        case .semester2: calendar.semester2.events.append(event)
        }
        updateCalendar(calendar)
    }
    
    func removeEvent(from semester: SemesterType, eventId: UUID) {
        guard var calendar = currentAcademicYear else { return }
        switch semester {
        case .semester1: calendar.semester1.events.removeAll { $0.id == eventId }
        case .semester2: calendar.semester2.events.removeAll { $0.id == eventId }
        }
        updateCalendar(calendar)
    }
    
    private func getDate(from string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }
    
    func addCustomCalendar(_ calendar: AcademicCalendarData) {
        availableCalendars.append(calendar)
    }
    
    func setCurrentCalendar(_ calendar: AcademicCalendarData) {
        currentAcademicYear = calendar
        objectWillChange.send()
    }
    
    func updateCalendar(_ calendar: AcademicCalendarData) {
        var updatedCalendar = calendar
        updatedCalendar.semester1.events.sort { $0.start < $1.start }
        updatedCalendar.semester2.events.sort { $0.start < $1.start }
        
        if let index = availableCalendars.firstIndex(where: { $0.id == calendar.id }) {
            availableCalendars[index] = updatedCalendar
            if currentAcademicYear?.id == calendar.id {
                currentAcademicYear = updatedCalendar
            }
        }
    }
}
