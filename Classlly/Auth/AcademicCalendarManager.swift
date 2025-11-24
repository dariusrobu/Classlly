import SwiftUI
import Foundation
import Combine

// MARK: - Templates
struct CalendarTemplate: Identifiable, Hashable {
    let id = UUID()
    var universityName: String
    var academicYear: String
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

struct SemesterData: Codable, Equatable {
    var events: [AcademicEventData]
    init(events: [AcademicEventData] = []) {
        self.events = events
    }
}

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


class AcademicCalendarManager: ObservableObject {
    @Published var currentAcademicYear: AcademicCalendarData?
    @Published var availableCalendars: [AcademicCalendarData] = []
    @Published var currentTeachingWeek: Int?
    @Published var currentSemester: SemesterType = .semester1
    
    let availableTemplates: [CalendarTemplate] = [
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
    
    // --- FIXED: Force Monday Start Calendar ---
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday
        return cal
    }
    
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
        setupDefaultCalendarIfNeeded()
        updateCurrentWeekAndSemester()
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

    func generateAndSaveCalendar(from template: CalendarTemplate) {
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

    func generateAndSaveCustomCalendar(year: String, universityName: String, sem1Start: Date, sem1End: Date, sem2Start: Date, sem2End: Date) {
        
        let s1StartDate = formatDate(sem1Start)
        let s1EndDate = formatDate(sem1End)
        let s2StartDate = formatDate(sem2Start)
        let s2EndDate = formatDate(sem2End)
        
        // Use self.calendar (Monday start) for calculations
        let winterBreakStart = calendar.date(byAdding: .day, value: 1, to: sem1End)!
        let winterBreakEnd = calendar.date(byAdding: .day, value: -1, to: sem2Start)!
        
        let s1TeachingWeeks = (calendar.dateComponents([.weekOfYear], from: sem1Start, to: sem1End).weekOfYear ?? 0) + 1
        let s2TeachingWeeks = (calendar.dateComponents([.weekOfYear], from: sem2Start, to: sem2End).weekOfYear ?? 0) + 1
        
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
            weeks: (calendar.dateComponents([.weekOfYear], from: winterBreakStart, to: winterBreakEnd).weekOfYear ?? 0) + 1,
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
    
    private func setupDefaultCalendarIfNeeded() {
        if availableCalendars.isEmpty {
            let defaultCalendar = createSampleCalendar()
            availableCalendars = [defaultCalendar]
            currentAcademicYear = defaultCalendar
            saveCalendars()
        }
    }
    
    private func createSampleCalendar() -> AcademicCalendarData {
        // Sample data remains the same, logic uses it as-is
        let semester1Events = [
            AcademicEventData(
                start: "2025-09-15",
                end: "2025-12-20",
                type: .teaching,
                weeks: 14,
                teachingWeekIndexStart: 1,
                teachingWeekIndexEnd: 14,
                customName: "Fall Teaching Period"
            ),
            AcademicEventData(
                start: "2025-12-21",
                end: "2026-01-10",
                type: .breakType,
                weeks: 3,
                customName: "Winter Break"
            )
        ]
        
        let semester2Events = [
            AcademicEventData(
                start: "2026-01-11",
                end: "2026-04-18",
                type: .teaching,
                weeks: 14,
                teachingWeekIndexStart: 1,
                teachingWeekIndexEnd: 14,
                customName: "Spring Teaching Period"
            ),
            AcademicEventData(
                start: "2026-04-19",
                end: "2026-04-25",
                type: .exam,
                weeks: 1,
                customName: "Examination Period"
            )
        ]
        
        return AcademicCalendarData(
            academicYear: "2025-2026",
            semester1: SemesterData(events: semester1Events),
            semester2: SemesterData(events: semester2Events),
            universityName: "University of Example",
            customName: "Default Academic Calendar"
        )
    }
    
    private func updateCurrentWeekAndSemester() {
        let today = Date()
        let dateString = formatDate(today)
        
        guard let calendar = currentAcademicYear else {
            currentTeachingWeek = nil
            currentSemester = .semester1
            return
        }
        
        // Use self.calendar (Monday start) for calculations
        
        for event in calendar.semester1.events {
            if event.type == .teaching, dateString >= event.start && dateString <= event.end {
                if let startWeek = event.teachingWeekIndexStart,
                   let startDate = dateFromString(event.start) {
                    let weeksDiff = self.calendar.dateComponents([.weekOfYear], from: startDate, to: today).weekOfYear ?? 0
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
                    let weeksDiff = self.calendar.dateComponents([.weekOfYear], from: startDate, to: today).weekOfYear ?? 0
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
