import SwiftUI
import Foundation
import Combine

struct CalendarTemplate: Identifiable, Hashable {
    let id = UUID()
    var universityName: String
    var academicYear: String
    var sem1StartStr: String
    var sem1EndStr: String
    var sem2StartStr: String
    var sem2EndStr: String
}

enum EventType: String, CaseIterable, Codable {
    case teaching = "teaching"
    case breakType = "break"
    case exam = "exam"
    case holiday = "holiday"
    case retake = "retake"
    case practice = "practice"
    case licensure = "licensure"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .teaching: return "Teaching"
        case .breakType: return "Break"
        case .exam: return "Exam Session"
        case .holiday: return "Holiday"
        case .retake: return "Retake Session"
        case .practice: return "Practical Training"
        case .licensure: return "Licensure Exam"
        case .other: return "Other"
        }
    }
    
    var iconName: String {
        switch self {
        case .teaching: return "book.fill"
        case .breakType: return "beach.umbrella.fill"
        case .exam: return "pencil.and.outline"
        case .holiday: return "gift.fill"
        case .retake: return "arrow.triangle.2.circlepath"
        case .practice: return "hammer.fill"
        case .licensure: return "graduationcap.fill"
        case .other: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .teaching: return .themePrimary
        case .breakType: return .themeSuccess
        case .exam: return .themeError
        case .holiday: return .themeAccent
        case .retake: return .orange
        case .practice: return .purple
        case .licensure: return .yellow
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
    init(events: [AcademicEventData] = []) { self.events = events }
}

struct AcademicCalendarData: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var academicYear: String
    var semester1: SemesterData
    var semester2: SemesterData
    var universityName: String?
    var customName: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case academicYear = "academic_year"
        case semester1 = "semester_1"
        case semester2 = "semester_2"
        case universityName = "university_name"
        case customName = "custom_name"
    }
    
    init(id: UUID = UUID(), academicYear: String, semester1: SemesterData = SemesterData(), semester2: SemesterData = SemesterData(), universityName: String? = nil, customName: String? = nil) {
        self.id = id
        self.academicYear = academicYear
        self.semester1 = semester1
        self.semester2 = semester2
        self.universityName = universityName
        self.customName = customName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let decodedId = try container.decodeIfPresent(UUID.self, forKey: .id) {
            self.id = decodedId
        } else {
            self.id = UUID()
        }
        self.academicYear = try container.decode(String.self, forKey: .academicYear)
        self.semester1 = try container.decode(SemesterData.self, forKey: .semester1)
        self.semester2 = try container.decode(SemesterData.self, forKey: .semester2)
        self.universityName = try container.decodeIfPresent(String.self, forKey: .universityName)
        self.customName = try container.decodeIfPresent(String.self, forKey: .customName)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(academicYear, forKey: .academicYear)
        try container.encode(semester1, forKey: .semester1)
        try container.encode(semester2, forKey: .semester2)
        try container.encode(universityName, forKey: .universityName)
        try container.encode(customName, forKey: .customName)
    }
}

class AcademicCalendarManager: ObservableObject {
    @Published var currentAcademicYear: AcademicCalendarData?
    @Published var availableCalendars: [AcademicCalendarData] = []
    @Published var currentTeachingWeek: Int?
    @Published var currentSemester: SemesterType = .semester1
    
    private let iCloudStore = NSUbiquitousKeyValueStore.default
    
    // ✅ STABLE IDs
    private let ubbStandardID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private let ubbFinalID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    
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
    
    enum SemesterType {
        case semester1, semester2
        var displayName: String {
            switch self {
            case .semester1: return "Semester 1"
            case .semester2: return "Semester 2"
            }
        }
    }
    
    private let calendarsKey = "savedAcademicCalendars"
    private let currentCalendarKey = "currentAcademicCalendar"
    
    init() {
        // ✅ NEW: Call setup method that handles all loading/cleaning/initializing
        initializeCalendars()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(storeDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore
        )
        iCloudStore.synchronize()
    }
    
    @objc private func storeDidChange(notification: NSNotification) {
        DispatchQueue.main.async {
            self.initializeCalendars()
        }
    }
    
    // MARK: - Core Initialization Function
    private func initializeCalendars() {
        loadCalendars()
        removeLegacyUBBCalendars()
        setupUBBCalendarsIfNeeded()
        ensureSelectionValidity()
        updateCurrentWeekAndSemester()
    }
    
    // MARK: - Strict Deduplication
    private func removeLegacyUBBCalendars() {
        var keptCalendars: [AcademicCalendarData] = []
        var didChange = false
        let officialIDs: Set<UUID> = [ubbStandardID, ubbFinalID]
        
        for calendar in availableCalendars {
            let isUBBCalendar = calendar.customName?.contains("UBB 2025-2026") == true
            
            if isUBBCalendar && !officialIDs.contains(calendar.id) {
                didChange = true
                continue
            }
            
            keptCalendars.append(calendar)
        }
        
        if didChange || keptCalendars.count != availableCalendars.count {
            let uniqueList = Dictionary(grouping: keptCalendars, by: { $0.id }).compactMap { $0.value.first }
            availableCalendars = uniqueList
            saveCalendars()
        }
    }
    
    private func ensureSelectionValidity() {
        let isSelectionValid = currentAcademicYear != nil && availableCalendars.contains(where: { $0.id == currentAcademicYear!.id })
        
        if !isSelectionValid {
            // Reset to Standard UBB as default
            if let standard = availableCalendars.first(where: { $0.id == ubbStandardID }) {
                setCurrentCalendar(standard)
            } else if let first = availableCalendars.first {
                setCurrentCalendar(first)
            } else {
                currentAcademicYear = nil
            }
        }
    }
    
    // MARK: - UBB Logic
    private func setupUBBCalendarsIfNeeded() {
        var didAdd = false
        
        if !availableCalendars.contains(where: { $0.id == ubbStandardID }) {
            availableCalendars.append(createUBBStandard2025())
            didAdd = true
        }
        
        if !availableCalendars.contains(where: { $0.id == ubbFinalID }) {
            availableCalendars.append(createUBBFinalYear2025())
            didAdd = true
        }
        
        if didAdd {
            saveCalendars()
        }
    }
    
    private func createUBBStandard2025() -> AcademicCalendarData {
        let s1_teach1 = AcademicEventData(start: "2025-09-29", end: "2025-12-21", type: .teaching, weeks: 12, teachingWeekIndexStart: 1, teachingWeekIndexEnd: 12, customName: "Didactic Activity 1")
        let s1_break = AcademicEventData(start: "2025-12-22", end: "2026-01-04", type: .breakType, weeks: 2, customName: "Christmas Holiday")
        let s1_teach2 = AcademicEventData(start: "2026-01-05", end: "2026-01-18", type: .teaching, weeks: 2, teachingWeekIndexStart: 13, teachingWeekIndexEnd: 14, customName: "Didactic Activity 2")
        let s1_exam = AcademicEventData(start: "2026-01-19", end: "2026-02-08", type: .exam, weeks: 3, customName: "Exam Session")
        let s1_holiday = AcademicEventData(start: "2026-02-09", end: "2026-02-15", type: .holiday, weeks: 1, customName: "Inter-semester Break")
        let s1_retake = AcademicEventData(start: "2026-02-16", end: "2026-02-22", type: .retake, weeks: 1, customName: "Retake Session")
        
        let s2_teach1 = AcademicEventData(start: "2026-02-23", end: "2026-04-12", type: .teaching, weeks: 7, teachingWeekIndexStart: 1, teachingWeekIndexEnd: 7, customName: "Didactic Activity 1")
        let s2_break = AcademicEventData(start: "2026-04-13", end: "2026-04-19", type: .breakType, weeks: 1, customName: "Easter Holiday")
        let s2_teach2 = AcademicEventData(start: "2026-04-20", end: "2026-06-07", type: .teaching, weeks: 7, teachingWeekIndexStart: 8, teachingWeekIndexEnd: 14, customName: "Didactic Activity 2")
        let s2_exam = AcademicEventData(start: "2026-06-08", end: "2026-06-28", type: .exam, weeks: 3, customName: "Summer Exam Session")
        let s2_holiday = AcademicEventData(start: "2026-06-29", end: "2026-07-05", type: .holiday, weeks: 1, customName: "Summer Break 1")
        let s2_retake = AcademicEventData(start: "2026-07-06", end: "2026-07-12", type: .retake, weeks: 1, customName: "Summer Retake Session")
        let s2_practice = AcademicEventData(start: "2026-07-13", end: "2026-08-02", type: .practice, weeks: 3, customName: "Practical Training")
        let s2_summer = AcademicEventData(start: "2026-08-03", end: "2026-09-27", type: .holiday, weeks: 8, customName: "Summer Holiday")

        return AcademicCalendarData(
            id: ubbStandardID,
            academicYear: "2025-2026",
            semester1: SemesterData(events: [s1_teach1, s1_break, s1_teach2, s1_exam, s1_holiday, s1_retake]),
            semester2: SemesterData(events: [s2_teach1, s2_break, s2_teach2, s2_exam, s2_holiday, s2_retake, s2_practice, s2_summer]),
            universityName: "UBB Cluj-Napoca",
            customName: "UBB 2025-2026 (Standard)"
        )
    }

    private func createUBBFinalYear2025() -> AcademicCalendarData {
        let s1_teach1 = AcademicEventData(start: "2025-09-29", end: "2025-12-21", type: .teaching, weeks: 12, teachingWeekIndexStart: 1, teachingWeekIndexEnd: 12, customName: "Didactic Activity 1")
        let s1_break = AcademicEventData(start: "2025-12-22", end: "2026-01-04", type: .breakType, weeks: 2, customName: "Christmas Holiday")
        let s1_teach2 = AcademicEventData(start: "2026-01-05", end: "2026-01-18", type: .teaching, weeks: 2, teachingWeekIndexStart: 13, teachingWeekIndexEnd: 14, customName: "Didactic Activity 2")
        let s1_exam = AcademicEventData(start: "2026-01-19", end: "2026-02-08", type: .exam, weeks: 3, customName: "Exam Session")
        let s1_holiday = AcademicEventData(start: "2026-02-09", end: "2026-02-15", type: .holiday, weeks: 1, customName: "Inter-semester Break")
        let s1_retake = AcademicEventData(start: "2026-02-16", end: "2026-02-22", type: .retake, weeks: 1, customName: "Retake Session")
        
        let s2_teach1 = AcademicEventData(start: "2026-02-23", end: "2026-04-12", type: .teaching, weeks: 7, teachingWeekIndexStart: 1, teachingWeekIndexEnd: 7, customName: "Didactic Activity 1")
        let s2_break = AcademicEventData(start: "2026-04-13", end: "2026-04-19", type: .breakType, weeks: 1, customName: "Easter Holiday")
        let s2_teach2 = AcademicEventData(start: "2026-04-20", end: "2026-05-24", type: .teaching, weeks: 5, teachingWeekIndexStart: 8, teachingWeekIndexEnd: 12, customName: "Didactic Activity 2")
        let s2_exam = AcademicEventData(start: "2026-05-25", end: "2026-06-07", type: .exam, weeks: 2, customName: "Final Exam Session")
        let s2_retake = AcademicEventData(start: "2026-06-08", end: "2026-06-14", type: .retake, weeks: 1, customName: "Retake Session")
        let s2_prep = AcademicEventData(start: "2026-06-15", end: "2026-06-28", type: .other, weeks: 2, customName: "Licensure Prep")
        let s2_license = AcademicEventData(start: "2026-06-29", end: "2026-07-05", type: .licensure, weeks: 1, customName: "Licensure Exam")

        return AcademicCalendarData(
            id: ubbFinalID,
            academicYear: "2025-2026",
            semester1: SemesterData(events: [s1_teach1, s1_break, s1_teach2, s1_exam, s1_holiday, s1_retake]),
            semester2: SemesterData(events: [s2_teach1, s2_break, s2_teach2, s2_exam, s2_retake, s2_prep, s2_license]),
            universityName: "UBB Cluj-Napoca",
            customName: "UBB 2025-2026 (Final Years)"
        )
    }
    
    // MARK: - Core Persistence
    
    func setCurrentCalendar(_ calendar: AcademicCalendarData) {
        currentAcademicYear = calendar
        updateCurrentWeekAndSemester()
        saveCalendars()
        
        if let encoded = try? JSONEncoder().encode(calendar) {
            iCloudStore.set(encoded, forKey: currentCalendarKey)
            iCloudStore.synchronize()
        }
    }
    
    func addCustomCalendar(_ calendar: AcademicCalendarData) {
        if !availableCalendars.contains(where: { $0.id == calendar.id }) {
            availableCalendars.append(calendar)
            setCurrentCalendar(calendar)
            saveCalendars()
        }
    }
    
    func updateCalendar(_ calendar: AcademicCalendarData) {
        if let index = availableCalendars.firstIndex(where: { $0.id == calendar.id }) {
            availableCalendars[index] = calendar
        }
        if currentAcademicYear?.id == calendar.id {
            currentAcademicYear = calendar
        }
        updateCurrentWeekAndSemester()
        saveCalendars()
    }
    
    func deleteCalendar(_ calendar: AcademicCalendarData) {
        availableCalendars.removeAll { $0.id == calendar.id }
        if currentAcademicYear?.id == calendar.id {
            currentAcademicYear = availableCalendars.first
        }
        saveCalendars()
    }
    
    private func loadCalendars() {
        if let data = iCloudStore.data(forKey: calendarsKey),
           let decoded = try? JSONDecoder().decode([AcademicCalendarData].self, from: data) {
            availableCalendars = decoded
        }
        
        if let data = iCloudStore.data(forKey: currentCalendarKey),
           let decoded = try? JSONDecoder().decode(AcademicCalendarData.self, from: data) {
            currentAcademicYear = decoded
        } else {
            currentAcademicYear = availableCalendars.first
        }
    }
    
    private func saveCalendars() {
        if let encoded = try? JSONEncoder().encode(availableCalendars) {
            iCloudStore.set(encoded, forKey: calendarsKey)
            iCloudStore.synchronize()
        }
    }
    
    // MARK: - Utility Methods
    
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
                if let startWeek = event.teachingWeekIndexStart, let startDate = dateFromString(event.start) {
                    currentTeachingWeek = startWeek + (Calendar.current.dateComponents([.weekOfYear], from: startDate, to: today).weekOfYear ?? 0)
                    currentSemester = .semester1
                    return
                }
            }
        }
        for event in calendar.semester2.events {
            if event.type == .teaching, dateString >= event.start && dateString <= event.end {
                if let startWeek = event.teachingWeekIndexStart, let startDate = dateFromString(event.start) {
                    currentTeachingWeek = startWeek + (Calendar.current.dateComponents([.weekOfYear], from: startDate, to: today).weekOfYear ?? 0)
                    currentSemester = .semester2
                    return
                }
            }
        }
        
        currentTeachingWeek = nil
        if let semester1Start = calendar.semester1.events.first?.start, let semester1Date = dateFromString(semester1Start), today >= semester1Date {
            currentSemester = .semester1
        } else {
            currentSemester = .semester2
        }
    }
    
    private func formatDate(_ date: Date) -> String { return dateFormatter.string(from: date) }
    private func dateFromString(_ dateString: String) -> Date? { return dateFormatter.date(from: dateString) }
    
    func getSemesterEvents(_ semester: SemesterType) -> [AcademicEventData] {
        guard let calendar = currentAcademicYear else { return [] }
        switch semester {
        case .semester1: return calendar.semester1.events
        case .semester2: return calendar.semester2.events
        }
    }
    
    func getCurrentEvent(for date: Date) -> AcademicEventData? {
        guard let calendar = currentAcademicYear else { return nil }
        let dateString = formatDate(date)
        let allEvents = calendar.semester1.events + calendar.semester2.events
        return allEvents.first { dateString >= $0.start && dateString <= $0.end }
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
        else { return }
        
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
        
        let winterBreakStart = Calendar.current.date(byAdding: .day, value: 1, to: sem1End)!
        let winterBreakEnd = Calendar.current.date(byAdding: .day, value: -1, to: sem2Start)!
        
        let s1TeachingWeeks = (Calendar.current.dateComponents([.weekOfYear], from: sem1Start, to: sem1End).weekOfYear ?? 0) + 1
        let s2TeachingWeeks = (Calendar.current.dateComponents([.weekOfYear], from: sem2Start, to: sem2End).weekOfYear ?? 0) + 1
        
        let sem1Teaching = AcademicEventData(start: s1StartDate, end: s1EndDate, type: .teaching, weeks: s1TeachingWeeks, teachingWeekIndexStart: 1, teachingWeekIndexEnd: s1TeachingWeeks, customName: "Semester 1")
        let winterBreak = AcademicEventData(start: formatDate(winterBreakStart), end: formatDate(winterBreakEnd), type: .breakType, weeks: (Calendar.current.dateComponents([.weekOfYear], from: winterBreakStart, to: winterBreakEnd).weekOfYear ?? 0) + 1, customName: "Winter Break")
        let sem2Teaching = AcademicEventData(start: s2StartDate, end: s2EndDate, type: .teaching, weeks: s2TeachingWeeks, teachingWeekIndexStart: 1, teachingWeekIndexEnd: s2TeachingWeeks, customName: "Semester 2")

        let newCalendar = AcademicCalendarData(
            academicYear: year,
            semester1: SemesterData(events: [sem1Teaching, winterBreak]),
            semester2: SemesterData(events: [sem2Teaching]),
            universityName: universityName,
            customName: "\(universityName) \(year)"
        )
        
        addCustomCalendar(newCalendar)
    }
}
