import SwiftUI
import Foundation
import Combine

// --- STRUCT FOR TEMPLATES ---
struct CalendarTemplate: Identifiable, Hashable {
    let id = UUID()
    var universityName: String
    var academicYear: String
    
    // Dates are strings to store them easily
    var sem1StartStr: String
    var sem1EndStr: String
    var sem2StartStr: String
    var sem2EndStr: String
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
        case .teaching: return .themePrimary
        case .breakType: return .themeSuccess
        case .exam: return .themeError
        case .holiday: return .themeAccent
        case .other: return .themeSecondary
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
    
    enum CodingKeys: String, CodingKey {
        case academicYear = "academic_year"
        case semester1 = "semester_1"
        case semester2 = "semester_2"
        case universityName = "university_name"
        case customName = "custom_name"
    }
    
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
    
    // --- CALENDAR TEMPLATES ---
    let availableTemplates: [CalendarTemplate] = [
        CalendarTemplate(
            universityName: "Universitatea Babeș-Bolyai (UBB)",
            academicYear: "2025-2026",
            // General start/end dates for reference (logic handled manually below)
            sem1StartStr: "2025-09-29",
            sem1EndStr: "2026-02-22",
            sem2StartStr: "2026-02-23",
            sem2EndStr: "2026-07-12"
        ),
        CalendarTemplate(
            universityName: "University of Example",
            academicYear: "2025-2026",
            sem1StartStr: "2025-09-15",
            sem1EndStr: "2025-12-20",
            sem2StartStr: "2026-01-11",
            sem2EndStr: "2026-04-18"
        )
    ]
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    enum SemesterType {
        case semester1
        case semester2
        
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
    
    // MARK: - Public Methods
    
    func loadDemoData() {
        if availableCalendars.isEmpty {
            generateUBBCalendar()
        }
    }
    
    func getSemesterEvents(_ semester: SemesterType) -> [AcademicEventData] {
        guard let calendar = currentAcademicYear else { return [] }
        
        switch semester {
        case .semester1:
            return calendar.semester1.events
        case .semester2:
            return calendar.semester2.events
        }
    }
    
    func getCurrentEvent(for date: Date) -> AcademicEventData? {
        guard let calendar = currentAcademicYear else { return nil }
        
        let dateString = formatDate(date)
        let allEvents = calendar.semester1.events + calendar.semester2.events
        
        return allEvents.first { event in
            dateString >= event.start && dateString <= event.end
        }
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
        if !availableCalendars.contains(where: { $0.academicYear == calendar.academicYear }) {
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
            semester1: SemesterData(),
            semester2: SemesterData(),
            universityName: universityName,
            customName: customName.isEmpty ? "\(universityName) \(year)" : customName
        )
    }

    // --- MAIN GENERATION ROUTER ---
    func generateAndSaveCalendar(from template: CalendarTemplate) {
        // Detect UBB Template
        if template.universityName.contains("Babeș-Bolyai") {
            generateUBBCalendar()
            return
        }
        
        // Fallback to Generic Generator
        guard let sem1Start = dateFormatter.date(from: template.sem1StartStr),
              let sem1End = dateFormatter.date(from: template.sem1EndStr),
              let sem2Start = dateFormatter.date(from: template.sem2StartStr),
              let sem2End = dateFormatter.date(from: template.sem2EndStr)
        else {
            print("Error: Could not parse dates from template.")
            return
        }
        
        generateAndSaveCustomCalendar(
            year: template.academicYear,
            universityName: template.universityName,
            sem1Start: sem1Start,
            sem1End: sem1End,
            sem2Start: sem2Start,
            sem2End: sem2End
        )
    }

    // --- UBB SPECIFIC GENERATOR ---
    // Source: STRUCTURA ANULUI UNIVERSITAR 2025-2026 (UBB PDF)
    private func generateUBBCalendar() {
        let year = "2025-2026"
        let university = "Universitatea Babeș-Bolyai"
        
        // --- SEMESTER 1 ---
        // 1. Didactic Activity: 29.09.2025 - 21.12.2025 (12 Weeks)
        let s1_teaching_1 = AcademicEventData(
            start: "2025-09-29",
            end: "2025-12-21",
            type: .teaching,
            weeks: 12,
            teachingWeekIndexStart: 1,
            teachingWeekIndexEnd: 12,
            customName: "Activitate Didactică (Part 1)"
        )
        
        // 2. Christmas Break: 22.12.2025 - 04.01.2026 (2 Weeks)
        let s1_winter_break = AcademicEventData(
            start: "2025-12-22",
            end: "2026-01-04",
            type: .breakType,
            weeks: 2,
            customName: "Vacanță de Crăciun"
        )
        
        // 3. Didactic Activity: 05.01.2026 - 18.01.2026 (2 Weeks)
        let s1_teaching_2 = AcademicEventData(
            start: "2026-01-05",
            end: "2026-01-18",
            type: .teaching,
            weeks: 2,
            teachingWeekIndexStart: 13,
            teachingWeekIndexEnd: 14,
            customName: "Activitate Didactică (Part 2)"
        )
        
        // 4. Exam Session: 19.01.2026 - 08.02.2026 (3 Weeks)
        let s1_exams = AcademicEventData(
            start: "2026-01-19",
            end: "2026-02-08",
            type: .exam,
            weeks: 3,
            customName: "Sesiune de Examene"
        )
        
        // 5. Inter-semester Break: 09.02.2026 - 15.02.2026 (1 Week)
        let inter_sem_break = AcademicEventData(
            start: "2026-02-09",
            end: "2026-02-15",
            type: .breakType,
            weeks: 1,
            customName: "Vacanță Intersemestrială"
        )
        
        // 6. Retake Session 1: 16.02.2026 - 22.02.2026 (1 Week)
        let s1_retakes = AcademicEventData(
            start: "2026-02-16",
            end: "2026-02-22",
            type: .exam,
            weeks: 1,
            customName: "Sesiune Restanțe (Sem 1)"
        )
        
        // --- SEMESTER 2 ---
        // 7. Didactic Activity: 23.02.2026 - 12.04.2026 (7 Weeks)
        let s2_teaching_1 = AcademicEventData(
            start: "2026-02-23",
            end: "2026-04-12",
            type: .teaching,
            weeks: 7,
            teachingWeekIndexStart: 1,
            teachingWeekIndexEnd: 7,
            customName: "Activitate Didactică (Part 1)"
        )
        
        // 8. Easter Break: 13.04.2026 - 19.04.2026 (1 Week)
        let s2_easter_break = AcademicEventData(
            start: "2026-04-13",
            end: "2026-04-19",
            type: .breakType,
            weeks: 1,
            customName: "Vacanța de Paști"
        )
        
        // 9. Didactic Activity: 20.04.2026 - 07.06.2026 (7 Weeks)
        let s2_teaching_2 = AcademicEventData(
            start: "2026-04-20",
            end: "2026-06-07",
            type: .teaching,
            weeks: 7,
            teachingWeekIndexStart: 8,
            teachingWeekIndexEnd: 14,
            customName: "Activitate Didactică (Part 2)"
        )
        
        // 10. Exam Session: 08.06.2026 - 28.06.2026 (3 Weeks)
        let s2_exams = AcademicEventData(
            start: "2026-06-08",
            end: "2026-06-28",
            type: .exam,
            weeks: 3,
            customName: "Sesiune de Examene"
        )
        
        // 11. Summer Break: 29.06.2026 - 05.07.2026 (1 Week)
        let s2_summer_break = AcademicEventData(
            start: "2026-06-29",
            end: "2026-07-05",
            type: .breakType,
            weeks: 1,
            customName: "Vacanță"
        )
        
        // 12. Retake Session 2: 06.07.2026 - 12.07.2026 (1 Week)
        let s2_retakes = AcademicEventData(
            start: "2026-07-06",
            end: "2026-07-12",
            type: .exam,
            weeks: 1,
            customName: "Sesiune Restanțe (Sem 2)"
        )
        
        // 13. Practice Period: 13.07.2026 - 02.08.2026 (3 Weeks)
        let s2_practice = AcademicEventData(
            start: "2026-07-13",
            end: "2026-08-02",
            type: .other,
            weeks: 3,
            customName: "Practică (unde este cazul)"
        )
        
        // Build the calendar object
        let ubbCalendar = AcademicCalendarData(
            academicYear: year,
            semester1: SemesterData(events: [s1_teaching_1, s1_winter_break, s1_teaching_2, s1_exams, inter_sem_break, s1_retakes]),
            semester2: SemesterData(events: [s2_teaching_1, s2_easter_break, s2_teaching_2, s2_exams, s2_summer_break, s2_retakes, s2_practice]),
            universityName: university,
            customName: "UBB Calendar \(year)"
        )
        
        // Save logic
        if let index = availableCalendars.firstIndex(where: { $0.universityName == university }) {
            availableCalendars[index] = ubbCalendar
        } else {
            availableCalendars.append(ubbCalendar)
        }
        
        setCurrentCalendar(ubbCalendar)
        saveCalendars()
    }

    // --- GENERIC GENERATOR ---
    func generateAndSaveCustomCalendar(year: String, universityName: String, sem1Start: Date, sem1End: Date, sem2Start: Date, sem2End: Date) {
        
        let s1StartDate = formatDate(sem1Start)
        let s1EndDate = formatDate(sem1End)
        let s2StartDate = formatDate(sem2Start)
        let s2EndDate = formatDate(sem2End)
        
        let winterBreakStart = Calendar.current.date(byAdding: .day, value: 1, to: sem1End)!
        let winterBreakEnd = Calendar.current.date(byAdding: .day, value: -1, to: sem2Start)!
        
        let s1TeachingWeeks = (Calendar.current.dateComponents([.weekOfYear], from: sem1Start, to: sem1End).weekOfYear ?? 0) + 1
        let s2TeachingWeeks = (Calendar.current.dateComponents([.weekOfYear], from: sem2Start, to: sem2End).weekOfYear ?? 0) + 1
        
        let sem1Teaching = AcademicEventData(
            start: s1StartDate,
            end: s1EndDate,
            type: .teaching,
            weeks: s1TeachingWeeks,
            teachingWeekIndexStart: 1,
            teachingWeekIndexEnd: s1TeachingWeeks,
            customName: "Semester 1"
        )
        
        let winterBreak = AcademicEventData(
            start: formatDate(winterBreakStart),
            end: formatDate(winterBreakEnd),
            type: .breakType,
            weeks: (Calendar.current.dateComponents([.weekOfYear], from: winterBreakStart, to: winterBreakEnd).weekOfYear ?? 0) + 1,
            customName: "Winter Break"
        )
        
        let sem2Teaching = AcademicEventData(
            start: s2StartDate,
            end: s2EndDate,
            type: .teaching,
            weeks: s2TeachingWeeks,
            teachingWeekIndexStart: 1,
            teachingWeekIndexEnd: s2TeachingWeeks,
            customName: "Semester 2"
        )

        let newCalendar = AcademicCalendarData(
            academicYear: year,
            semester1: SemesterData(events: [sem1Teaching, winterBreak]),
            semester2: SemesterData(events: [sem2Teaching]),
            universityName: universityName,
            customName: "\(universityName) \(year)"
        )
        
        if let index = availableCalendars.firstIndex(where: { $0.customName == "Default Academic Calendar" }) {
            availableCalendars[index] = newCalendar
        } else {
            availableCalendars.append(newCalendar)
        }
        
        setCurrentCalendar(newCalendar)
        saveCalendars()
    }
    
    // MARK: - Private Methods
    
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
        let today = Date()
        let dateString = formatDate(today)
        
        guard let calendar = currentAcademicYear else {
            currentTeachingWeek = nil
            currentSemester = .semester1
            return
        }
        
        for event in calendar.semester1.events {
            if event.type == .teaching, dateString >= event.start && dateString <= event.end {
                if let startWeek = event.teachingWeekIndexStart,
                   let startDate = dateFromString(event.start) {
                    let weeksDiff = Calendar.current.dateComponents([.weekOfYear], from: startDate, to: today).weekOfYear ?? 0
                    currentTeachingWeek = startWeek + weeksDiff
                    currentSemester = .semester1
                    return
                }
            }
        }
        
        for event in calendar.semester2.events {
            if event.type == .teaching, dateString >= event.start && dateString <= event.end {
                if let startWeek = event.teachingWeekIndexStart,
                   let startDate = dateFromString(event.start) {
                    let weeksDiff = Calendar.current.dateComponents([.weekOfYear], from: startDate, to: today).weekOfYear ?? 0
                    currentTeachingWeek = startWeek + weeksDiff
                    currentSemester = .semester2
                    return
                }
            }
        }
        
        currentTeachingWeek = nil
        
        if let semester1Start = calendar.semester1.events.first?.start,
           let semester1Date = dateFromString(semester1Start),
           today >= semester1Date {
            currentSemester = .semester1
        } else {
            currentSemester = .semester2
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    private func dateFromString(_ dateString: String) -> Date? {
        return dateFormatter.date(from: dateString)
    }
}
