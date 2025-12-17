import Foundation
import SwiftUI
import Combine

// MARK: - Event Type
enum EventType: String, CaseIterable, Codable {
    case teaching = "teaching"
    case breakType = "break"
    case exam = "exam"
    case holiday = "holiday"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .teaching: return "Teaching"
        case .breakType: return "Break"
        case .exam: return "Exam Session"
        case .holiday: return "Holiday"
        case .other: return "Other"
        }
    }
    
    var iconName: String {
        switch self {
        case .teaching: return "book.fill"
        case .breakType: return "beach.umbrella.fill"
        case .exam: return "pencil.and.outline"
        case .holiday: return "gift.fill"
        case .other: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .teaching: return .blue
        case .breakType: return .green
        case .exam: return .red
        case .holiday: return .orange
        case .other: return .purple
        }
    }
}

// MARK: - Data Models
struct AcademicEventData: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var start: String
    var end: String
    var type: EventType
    var weeks: Int
    var teachingWeekIndexStart: Int?
    var teachingWeekIndexEnd: Int?
    var customName: String?
}

struct SemesterData: Codable, Equatable {
    var events: [AcademicEventData] = []
}

struct AcademicCalendarData: Codable, Equatable {
    var academicYear: String
    var semester1: SemesterData = SemesterData()
    var semester2: SemesterData = SemesterData()
    var universityName: String?
    var customName: String?
}

struct CalendarTemplate: Identifiable {
    let id = UUID()
    let universityName: String
    let academicYear: String
    let sem1StartStr: String
    let sem1EndStr: String
    let sem2StartStr: String
    let sem2EndStr: String
}

// MARK: - Manager
class AcademicCalendarManager: ObservableObject {
    static let shared = AcademicCalendarManager()
    
    @Published var currentAcademicYear: AcademicCalendarData?
    @Published var availableCalendars: [AcademicCalendarData] = []
    @Published var currentTeachingWeek: Int?
    @Published var currentSemester: SemesterType = .semester1
    
    enum SemesterType {
        case semester1, semester2
        var displayName: String {
            switch self {
            case .semester1: return "Semester 1"
            case .semester2: return "Semester 2"
            }
        }
    }
    
    // Available Templates for Onboarding
    let availableTemplates: [CalendarTemplate] = [
        CalendarTemplate(
            universityName: "Universitatea Babeș-Bolyai (UBB)",
            academicYear: "2025-2026",
            sem1StartStr: "2025-09-29",
            sem1EndStr: "2026-02-22",
            sem2StartStr: "2026-02-23",
            sem2EndStr: "2026-07-12"
        ),
        CalendarTemplate(
            universityName: "Generic University",
            academicYear: "2025-2026",
            sem1StartStr: "2025-09-01",
            sem1EndStr: "2026-01-31",
            sem2StartStr: "2026-02-01",
            sem2EndStr: "2026-06-30"
        )
    ]
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    init() {
        loadDemoData()
        updateCurrentStatus()
    }
    
    // MARK: - Static Templates
    static var ubb2025Template: AcademicCalendarData {
        // We reuse the generator logic for consistency
        return AcademicCalendarManager.shared.createUBB2025_2026()
    }
    
    // MARK: - Core Methods
    
    func loadDemoData() {
        if availableCalendars.isEmpty {
            let ubb = createUBB2025_2026()
            availableCalendars.append(ubb)
            if currentAcademicYear == nil {
                currentAcademicYear = ubb
            }
        }
    }
    
    func generateAndSaveCustomCalendar(year: String, universityName: String, sem1Start: Date, sem1End: Date, sem2Start: Date, sem2End: Date) {
        var calendar = AcademicCalendarData(
            academicYear: year,
            universityName: universityName,
            customName: universityName
        )
        
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        
        let s1Weeks = Calendar.current.dateComponents([.weekOfYear], from: sem1Start, to: sem1End).weekOfYear ?? 14
        let s2Weeks = Calendar.current.dateComponents([.weekOfYear], from: sem2Start, to: sem2End).weekOfYear ?? 14
        
        calendar.semester1.events.append(AcademicEventData(
            start: f.string(from: sem1Start), end: f.string(from: sem1End),
            type: .teaching, weeks: s1Weeks, teachingWeekIndexStart: 1, teachingWeekIndexEnd: s1Weeks, customName: "Semester 1"
        ))
        
        calendar.semester2.events.append(AcademicEventData(
            start: f.string(from: sem2Start), end: f.string(from: sem2End),
            type: .teaching, weeks: s2Weeks, teachingWeekIndexStart: 1, teachingWeekIndexEnd: s2Weeks, customName: "Semester 2"
        ))
        
        addCustomCalendar(calendar)
    }
    
    func generateAndSaveCalendar(from template: CalendarTemplate) {
        if template.universityName.contains("Babeș-Bolyai") {
            let ubb = createUBB2025_2026()
            addCustomCalendar(ubb)
        } else {
            generateAndSaveCalendar(from: AcademicCalendarData(academicYear: template.academicYear, universityName: template.universityName, customName: template.universityName)) // Minimal version
        }
    }
    
    func generateAndSaveCalendar(from data: AcademicCalendarData) {
        addCustomCalendar(data)
    }
    
    func addCustomCalendar(_ calendar: AcademicCalendarData) {
        // Prevent duplicates
        if !availableCalendars.contains(where: { $0.universityName == calendar.universityName && $0.academicYear == calendar.academicYear }) {
            availableCalendars.append(calendar)
        }
        setCurrentCalendar(calendar)
    }
    
    func setCurrentCalendar(_ calendar: AcademicCalendarData) {
        self.currentAcademicYear = calendar
        updateCurrentStatus()
    }
    
    func updateCalendar(_ calendar: AcademicCalendarData) {
        if let index = availableCalendars.firstIndex(where: { $0.academicYear == calendar.academicYear && $0.universityName == calendar.universityName }) {
            availableCalendars[index] = calendar
        }
        self.currentAcademicYear = calendar
        updateCurrentStatus()
    }
    
    func deleteCalendar(_ calendar: AcademicCalendarData) {
        availableCalendars.removeAll { $0.academicYear == calendar.academicYear && $0.universityName == calendar.universityName }
        if currentAcademicYear?.academicYear == calendar.academicYear {
            currentAcademicYear = availableCalendars.first
        }
    }
    
    func createNewCalendar(year: String, universityName: String, customName: String) -> AcademicCalendarData {
        return AcademicCalendarData(academicYear: year, universityName: universityName, customName: customName)
    }
    
    func getSemesterEvents(_ semester: SemesterType) -> [AcademicEventData] {
        guard let calendar = currentAcademicYear else { return [] }
        return semester == .semester1 ? calendar.semester1.events : calendar.semester2.events
    }
    
    func getCurrentEvent(for date: Date) -> AcademicEventData? {
        let allEvents = getSemesterEvents(.semester1) + getSemesterEvents(.semester2)
        return allEvents.first { event in
            guard let startDate = dateFormatter.date(from: event.start),
                  let endDate = dateFormatter.date(from: event.end) else { return false }
            return date >= startDate && date <= endDate
        }
    }
    
    func updateCurrentStatus() {
        let today = Date()
        guard let calendar = currentAcademicYear else { return }
        
        let s1Events = calendar.semester1.events
        if let s1Start = dateFormatter.date(from: s1Events.first?.start ?? ""),
           let s1End = dateFormatter.date(from: s1Events.last?.end ?? ""),
           today >= s1Start && today <= s1End {
            currentSemester = .semester1
        } else {
            currentSemester = .semester2
        }
        
        if let currentEvent = getCurrentEvent(for: today), currentEvent.type == .teaching,
           let startStr = currentEvent.start as String?,
           let start = dateFormatter.date(from: startStr),
           let weekStart = currentEvent.teachingWeekIndexStart {
            
            let calendar = Calendar.current
            let weekOfYearCurrent = calendar.component(.weekOfYear, from: today)
            let weekOfYearStart = calendar.component(.weekOfYear, from: start)
            
            var diff = weekOfYearCurrent - weekOfYearStart
            if diff < 0 { diff += 52 }
            currentTeachingWeek = weekStart + diff
        } else {
            currentTeachingWeek = nil
        }
    }
    
    // MARK: - UBB Generator (Private Logic)
    private func createUBB2025_2026() -> AcademicCalendarData {
        var ubb = AcademicCalendarData(
            academicYear: "2025-2026",
            universityName: "Universitatea Babeș-Bolyai (UBB)",
            customName: "UBB 2025-26"
        )
        
        // --- SEMESTER 1 ---
        ubb.semester1.events.append(AcademicEventData(start: "2025-09-29", end: "2025-12-21", type: .teaching, weeks: 12, teachingWeekIndexStart: 1, teachingWeekIndexEnd: 12, customName: "Teaching Module 1"))
        ubb.semester1.events.append(AcademicEventData(start: "2025-12-01", end: "2025-12-01", type: .holiday, weeks: 0, customName: "Great Union Day"))
        ubb.semester1.events.append(AcademicEventData(start: "2025-12-22", end: "2026-01-04", type: .breakType, weeks: 2, customName: "Winter Holiday"))
        ubb.semester1.events.append(AcademicEventData(start: "2026-01-05", end: "2026-01-18", type: .teaching, weeks: 2, teachingWeekIndexStart: 13, teachingWeekIndexEnd: 14, customName: "Teaching Module 2"))
        ubb.semester1.events.append(AcademicEventData(start: "2026-01-06", end: "2026-01-07", type: .holiday, weeks: 0, customName: "Epiphany & St. John"))
        ubb.semester1.events.append(AcademicEventData(start: "2026-01-19", end: "2026-02-08", type: .exam, weeks: 3, customName: "Exam Session"))
        ubb.semester1.events.append(AcademicEventData(start: "2026-01-24", end: "2026-01-24", type: .holiday, weeks: 0, customName: "Unification Day"))
        ubb.semester1.events.append(AcademicEventData(start: "2026-02-09", end: "2026-02-15", type: .breakType, weeks: 1, customName: "Inter-semester Break"))
        ubb.semester1.events.append(AcademicEventData(start: "2026-02-16", end: "2026-02-22", type: .exam, weeks: 1, customName: "Re-examination Session"))
        
        // --- SEMESTER 2 ---
        ubb.semester2.events.append(AcademicEventData(start: "2026-02-23", end: "2026-04-12", type: .teaching, weeks: 7, teachingWeekIndexStart: 1, teachingWeekIndexEnd: 7, customName: "Teaching Module 1"))
        ubb.semester2.events.append(AcademicEventData(start: "2026-04-13", end: "2026-04-19", type: .breakType, weeks: 1, customName: "Easter Holiday (Orthodox)"))
        ubb.semester2.events.append(AcademicEventData(start: "2026-04-20", end: "2026-06-07", type: .teaching, weeks: 7, teachingWeekIndexStart: 8, teachingWeekIndexEnd: 14, customName: "Teaching Module 2"))
        ubb.semester2.events.append(AcademicEventData(start: "2026-05-01", end: "2026-05-01", type: .holiday, weeks: 0, customName: "Labor Day"))
        ubb.semester2.events.append(AcademicEventData(start: "2026-06-01", end: "2026-06-01", type: .holiday, weeks: 0, customName: "Children's Day & Pentecost"))
        ubb.semester2.events.append(AcademicEventData(start: "2026-06-08", end: "2026-06-28", type: .exam, weeks: 3, customName: "Summer Exam Session"))
        ubb.semester2.events.append(AcademicEventData(start: "2026-06-29", end: "2026-07-05", type: .breakType, weeks: 1, customName: "Student Summer Break"))
        ubb.semester2.events.append(AcademicEventData(start: "2026-07-06", end: "2026-07-12", type: .exam, weeks: 1, customName: "Re-examination Session"))
        
        return ubb
    }
}
