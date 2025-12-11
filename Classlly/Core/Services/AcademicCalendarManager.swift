import Foundation
import SwiftUI
import Combine // <-- ADDED THIS to fix the error

class AcademicCalendarManager: ObservableObject {
    @Published var currentTerm: String = "Fall 2024"
    @Published var daysRemaining: Int = 45
    
    // Singleton instance (optional, but good for services)
    static let shared = AcademicCalendarManager()
    
    private init() {}
    
    func fetchCalendar() {
        // Placeholder logic
        print("Fetching academic calendar...")
    }
}

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
        case .exam: return "Exam"
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

// MARK: - Academic Event Data
struct AcademicEventData: Identifiable, Codable, Equatable {
    let id: UUID
    var start: String
    var end: String
    var type: EventType
    var weeks: Int
    var teachingWeekIndexStart: Int?
    var teachingWeekIndexEnd: Int?
    var customName: String?
    
    init(id: UUID = UUID(), start: String, end: String, type: EventType, weeks: Int, teachingWeekIndexStart: Int? = nil, teachingWeekIndexEnd: Int? = nil, customName: String? = nil) {
        self.id = id
        self.start = start
        self.end = end
        self.type = type
        self.weeks = weeks
        self.teachingWeekIndexStart = teachingWeekIndexStart
        self.teachingWeekIndexEnd = teachingWeekIndexEnd
        self.customName = customName
    }
}

// MARK: - Semester Data
struct SemesterData: Codable, Equatable {
    var events: [AcademicEventData]
    
    init(events: [AcademicEventData] = []) {
        self.events = events
    }
}

// MARK: - Academic Calendar Data
struct AcademicCalendarData: Codable, Equatable {
    var academicYear: String
    var semester1: SemesterData
    var semester2: SemesterData
    var universityName: String?
    var customName: String?
    
    init(academicYear: String, semester1: SemesterData = SemesterData(), semester2: SemesterData = SemesterData(), universityName: String? = nil, customName: String? = nil) {
        self.academicYear = academicYear
        self.semester1 = semester1
        self.semester2 = semester2
        self.universityName = universityName
        self.customName = customName
    }
}

// MARK: - Academic Calendar Manager
class AcademicCalendarManager: ObservableObject {
    @Published var currentAcademicYear: AcademicCalendarData?
    @Published var availableCalendars: [AcademicCalendarData] = []
    @Published var currentTeachingWeek: Int?
    @Published var currentSemester: SemesterType = .semester1
    
    let availableTemplates: [CalendarTemplate] = [
        CalendarTemplate(universityName: "Universitatea Babeș-Bolyai (UBB)", academicYear: "2025-2026", sem1StartStr: "2025-09-29", sem1EndStr: "2026-02-22", sem2StartStr: "2026-02-23", sem2EndStr: "2026-07-12"),
        CalendarTemplate(universityName: "University of Example", academicYear: "2025-2026", sem1StartStr: "2025-09-15", sem1EndStr: "2025-12-20", sem2StartStr: "2026-01-11", sem2EndStr: "2026-04-18")
    ]
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    enum SemesterType {
        case semester1, semester2
        var displayName: String {
            switch self {
            case .semester1: return "Semester 1"
            case .semester2: return "Semester 2"
            }
        }
    }
    
    private let userDefaultsKey = "savedAcademicCalendars"
    private let currentCalendarKey = "currentAcademicCalendar"
    
    init() {
        loadCalendars()
        updateCurrentWeekAndSemester()
    }
    
    func loadDemoData() {
        if availableCalendars.isEmpty {
            generateUBBCalendar()
        }
    }
    
    func getSemesterEvents(_ semester: SemesterType) -> [AcademicEventData] {
        guard let calendar = currentAcademicYear else { return [] }
        return semester == .semester1 ? calendar.semester1.events : calendar.semester2.events
    }
    
    func getCurrentEvent(for date: Date) -> AcademicEventData? {
        guard let calendar = currentAcademicYear else { return nil }
        let dateString = formatDate(date)
        let allEvents = calendar.semester1.events + calendar.semester2.events
        return allEvents.first { dateString >= $0.start && dateString <= $0.end }
    }
    
    func setCurrentCalendar(_ calendar: AcademicCalendarData) {
        currentAcademicYear = calendar
        updateCurrentWeekAndSemester()
        saveCalendars()
        if let encoded = try? JSONEncoder().encode(calendar) {
            UserDefaults.standard.set(encoded, forKey: currentCalendarKey)
        }
    }
    
    func addCustomCalendar(_ calendar: AcademicCalendarData) {
        if let index = availableCalendars.firstIndex(where: { $0.academicYear == calendar.academicYear && $0.universityName == calendar.universityName }) {
            availableCalendars[index] = calendar
        } else {
            availableCalendars.append(calendar)
        }
        setCurrentCalendar(calendar)
        saveCalendars()
    }
    
    func updateCalendar(_ calendar: AcademicCalendarData) {
        if let index = availableCalendars.firstIndex(where: { $0.academicYear == calendar.academicYear }) {
            availableCalendars[index] = calendar
        }
        if currentAcademicYear?.academicYear == calendar.academicYear {
            currentAcademicYear = calendar
        }
        updateCurrentWeekAndSemester()
        saveCalendars()
    }
    
    func deleteCalendar(_ calendar: AcademicCalendarData) {
        availableCalendars.removeAll { $0.academicYear == calendar.academicYear }
        if currentAcademicYear?.academicYear == calendar.academicYear {
            currentAcademicYear = availableCalendars.first
        }
        saveCalendars()
    }
    
    func createNewCalendar(year: String, universityName: String, customName: String) -> AcademicCalendarData {
        return AcademicCalendarData(
            academicYear: year,
            universityName: universityName,
            customName: customName.isEmpty ? "\(universityName) \(year)" : customName
        )
    }

    func generateAndSaveCalendar(from template: CalendarTemplate) {
        if template.universityName.contains("Babeș-Bolyai") {
            generateUBBCalendar()
            return
        }
        guard let s1S = dateFormatter.date(from: template.sem1StartStr),
              let s1E = dateFormatter.date(from: template.sem1EndStr),
              let s2S = dateFormatter.date(from: template.sem2StartStr),
              let s2E = dateFormatter.date(from: template.sem2EndStr) else { return }
        
        generateAndSaveCustomCalendar(year: template.academicYear, universityName: template.universityName, sem1Start: s1S, sem1End: s1E, sem2Start: s2S, sem2End: s2E)
    }

    // MARK: - UBB 2025-2026 Calendar Generation
    // Matches the provided official structure
    private func generateUBBCalendar() {
        let year = "2025-2026"
        let university = "Universitatea Babeș-Bolyai"
        
        // --- SEMESTER 1 ---
        // Preparation: 25.09.2025 - 26.09.2025
        let s1_prep = AcademicEventData(
            start: "2025-09-25",
            end: "2025-09-26",
            type: .other,
            weeks: 0,
            customName: "Pregătire An Universitar"
        )
        
        // Teaching 1: 29.09.2025 - 21.12.2025 (12 weeks)
        let s1_teaching1 = AcademicEventData(
            start: "2025-09-29",
            end: "2025-12-21",
            type: .teaching,
            weeks: 12,
            teachingWeekIndexStart: 1,
            teachingWeekIndexEnd: 12,
            customName: "Activitate Didactică (12 săpt)"
        )
        
        // Christmas Holiday: 22.12.2025 - 04.01.2026 (2 weeks)
        let s1_holiday1 = AcademicEventData(
            start: "2025-12-22",
            end: "2026-01-04",
            type: .holiday,
            weeks: 2,
            customName: "Vacanță de Crăciun"
        )
        
        // Teaching 2: 05.01.2026 - 18.01.2026 (2 weeks)
        let s1_teaching2 = AcademicEventData(
            start: "2026-01-05",
            end: "2026-01-18",
            type: .teaching,
            weeks: 2,
            teachingWeekIndexStart: 13,
            teachingWeekIndexEnd: 14,
            customName: "Activitate Didactică (2 săpt)"
        )
        
        // Exam Session: 19.01.2026 - 08.02.2026 (3 weeks)
        let s1_exams = AcademicEventData(
            start: "2026-01-19",
            end: "2026-02-08",
            type: .exam,
            weeks: 3,
            customName: "Sesiune de Examene"
        )
        
        // Holiday: 09.02.2026 - 15.02.2026 (1 week)
        let s1_holiday2 = AcademicEventData(
            start: "2026-02-09",
            end: "2026-02-15",
            type: .holiday,
            weeks: 1,
            customName: "Vacanță Intersemestrială"
        )
        
        // Resit Session: 16.02.2026 - 22.02.2026 (1 week)
        let s1_reexams = AcademicEventData(
            start: "2026-02-16",
            end: "2026-02-22",
            type: .exam,
            weeks: 1,
            customName: "Sesiune de Restanțe"
        )
        
        // --- SEMESTER 2 ---
        // Teaching 1: 23.02.2026 - 12.04.2026 (7 weeks)
        let s2_teaching1 = AcademicEventData(
            start: "2026-02-23",
            end: "2026-04-12",
            type: .teaching,
            weeks: 7,
            teachingWeekIndexStart: 1,
            teachingWeekIndexEnd: 7,
            customName: "Activitate Didactică I (7 săpt)"
        )
        
        // Easter Holiday: 13.04.2026 - 19.04.2026 (1 week)
        let s2_holiday1 = AcademicEventData(
            start: "2026-04-13",
            end: "2026-04-19",
            type: .holiday,
            weeks: 1,
            customName: "Vacanță de Paști"
        )
        
        // Teaching 2: 20.04.2026 - 07.06.2026 (7 weeks)
        let s2_teaching2 = AcademicEventData(
            start: "2026-04-20",
            end: "2026-06-07",
            type: .teaching,
            weeks: 7,
            teachingWeekIndexStart: 8,
            teachingWeekIndexEnd: 14,
            customName: "Activitate Didactică II (7 săpt)"
        )
        
        // Exam Session: 08.06.2026 - 28.06.2026 (3 weeks)
        let s2_exams = AcademicEventData(
            start: "2026-06-08",
            end: "2026-06-28",
            type: .exam,
            weeks: 3,
            customName: "Sesiune de Examene"
        )
        
        // Holiday: 29.06.2026 - 05.07.2026 (1 week)
        let s2_holiday2 = AcademicEventData(
            start: "2026-06-29",
            end: "2026-07-05",
            type: .holiday,
            weeks: 1,
            customName: "Vacanță"
        )
        
        // Resit Session: 06.07.2026 - 12.07.2026 (1 week)
        let s2_reexams = AcademicEventData(
            start: "2026-07-06",
            end: "2026-07-12",
            type: .exam,
            weeks: 1,
            customName: "Sesiune de Restanțe"
        )
        
        // Internship: 13.07.2026 - 02.08.2026 (3 weeks)
        let s2_practice = AcademicEventData(
            start: "2026-07-13",
            end: "2026-08-02",
            type: .other,
            weeks: 3,
            customName: "Perioadă de Practică"
        )
        
        // Summer Vacation: 03.08.2026 - 27.09.2026 (8 weeks)
        let s2_summer_holiday = AcademicEventData(
            start: "2026-08-03",
            end: "2026-09-27",
            type: .holiday,
            weeks: 8,
            customName: "Vacanță de Vară"
        )
        
        let ubbCalendar = AcademicCalendarData(
            academicYear: year,
            semester1: SemesterData(events: [
                s1_prep, s1_teaching1, s1_holiday1, s1_teaching2, s1_exams, s1_holiday2, s1_reexams
            ]),
            semester2: SemesterData(events: [
                s2_teaching1, s2_holiday1, s2_teaching2, s2_exams, s2_holiday2, s2_reexams, s2_practice, s2_summer_holiday
            ]),
            universityName: university,
            customName: "UBB Calendar \(year)"
        )
        
        addCustomCalendar(ubbCalendar)
    }

    func generateAndSaveCustomCalendar(year: String, universityName: String, sem1Start: Date, sem1End: Date, sem2Start: Date, sem2End: Date) {
        let s1StartDate = formatDate(sem1Start)
        let s1EndDate = formatDate(sem1End)
        let s2StartDate = formatDate(sem2Start)
        let s2EndDate = formatDate(sem2End)
        
        let s1Weeks = (Calendar.current.dateComponents([.weekOfYear], from: sem1Start, to: sem1End).weekOfYear ?? 0) + 1
        let s2Weeks = (Calendar.current.dateComponents([.weekOfYear], from: sem2Start, to: sem2End).weekOfYear ?? 0) + 1
        
        let sem1 = AcademicEventData(start: s1StartDate, end: s1EndDate, type: .teaching, weeks: s1Weeks, teachingWeekIndexStart: 1, teachingWeekIndexEnd: s1Weeks, customName: "Semester 1")
        let sem2 = AcademicEventData(start: s2StartDate, end: s2EndDate, type: .teaching, weeks: s2Weeks, teachingWeekIndexStart: 1, teachingWeekIndexEnd: s2Weeks, customName: "Semester 2")
        
        let newCalendar = AcademicCalendarData(academicYear: year, semester1: SemesterData(events: [sem1]), semester2: SemesterData(events: [sem2]), universityName: universityName, customName: "\(universityName) \(year)")
        addCustomCalendar(newCalendar)
    }
    
    private func loadCalendars() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([AcademicCalendarData].self, from: data) {
            availableCalendars = decoded
        }
        if let data = UserDefaults.standard.data(forKey: currentCalendarKey),
           let decoded = try? JSONDecoder().decode(AcademicCalendarData.self, from: data) {
            currentAcademicYear = decoded
        } else {
            currentAcademicYear = availableCalendars.first
        }
    }
    
    private func saveCalendars() {
        if let encoded = try? JSONEncoder().encode(availableCalendars) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func updateCurrentWeekAndSemester() {
        guard let calendar = currentAcademicYear else {
            currentTeachingWeek = nil
            return
        }
        
        let today = Date()
        let todayString = formatDate(today)
        
        let allSem1 = calendar.semester1.events
        let allSem2 = calendar.semester2.events
        
        var foundEvent: AcademicEventData?
        var isSem1 = true
        
        // Find if today falls into any event
        if let event = allSem1.first(where: { todayString >= $0.start && todayString <= $0.end }) {
            foundEvent = event
            isSem1 = true
        } else if let event = allSem2.first(where: { todayString >= $0.start && todayString <= $0.end }) {
            foundEvent = event
            isSem1 = false
        }
        
        currentSemester = isSem1 ? .semester1 : .semester2
        
        if let event = foundEvent, event.type == .teaching {
            if let startDate = dateFormatter.date(from: event.start) {
                // Calculate week difference from start of this event block
                let diff = Calendar.current.dateComponents([.weekOfYear], from: startDate, to: today).weekOfYear ?? 0
                // Add base index (e.g. if this block starts at week 8)
                let baseIndex = event.teachingWeekIndexStart ?? 1
                currentTeachingWeek = baseIndex + diff
            }
        } else {
            currentTeachingWeek = nil
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
}
