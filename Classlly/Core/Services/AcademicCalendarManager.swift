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
    
    let availableTemplates: [CalendarTemplate] = [
        CalendarTemplate(universityName: "Universitatea Babeș-Bolyai (UBB)", academicYear: "2025-2026", sem1StartStr: "2025-09-29", sem1EndStr: "2026-02-22", sem2StartStr: "2026-02-23", sem2EndStr: "2026-07-12")
    ]
    
    enum SemesterType {
        case semester1, semester2
        var displayName: String {
            switch self {
            case .semester1: return "Semester 1"
            case .semester2: return "Semester 2"
            }
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    init() {
        loadDemoData()
    }
    
    func loadDemoData() {
        // Simple default if empty
        if currentAcademicYear == nil {
            let defaultCal = AcademicCalendarData(academicYear: "2025-2026", universityName: "Default")
            self.currentAcademicYear = defaultCal
        }
    }
    
    func getSemesterEvents(_ semester: SemesterType) -> [AcademicEventData] {
        guard let calendar = currentAcademicYear else { return [] }
        return semester == .semester1 ? calendar.semester1.events : calendar.semester2.events
    }
    
    func getCurrentEvent(for date: Date) -> AcademicEventData? {
        // Simplified lookup logic
        return nil
    }
    
    func setCurrentCalendar(_ calendar: AcademicCalendarData) {
        self.currentAcademicYear = calendar
    }
    
    func addCustomCalendar(_ calendar: AcademicCalendarData) {
        availableCalendars.append(calendar)
        setCurrentCalendar(calendar)
    }
    
    func updateCalendar(_ calendar: AcademicCalendarData) {
        // Update logic
        self.currentAcademicYear = calendar
    }
    
    func deleteCalendar(_ calendar: AcademicCalendarData) {
        availableCalendars.removeAll { $0.academicYear == calendar.academicYear }
    }
    
    func createNewCalendar(year: String, universityName: String, customName: String) -> AcademicCalendarData {
        return AcademicCalendarData(academicYear: year, universityName: universityName, customName: customName)
    }
    
    func generateAndSaveCalendar(from template: CalendarTemplate) {
        // Generation logic
    }
    
    func generateAndSaveCustomCalendar(year: String, universityName: String, sem1Start: Date, sem1End: Date, sem2Start: Date, sem2End: Date) {
        // Logic
    }
}
