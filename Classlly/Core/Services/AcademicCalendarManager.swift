import SwiftUI
import Combine

// MARK: - API Response Models (V2 Compatible)
struct RemoteCalendarResponse: Codable {
    let version: Int
    let calendars: [RemoteCalendarTemplate]
}

// Updated to match the "Version 2" JSON from your Vercel API
struct RemoteCalendarTemplate: Codable {
    let id: String?
    let universityName: String
    let academicYear: String
    let sem1Start: String
    let sem1End: String
    let sem2Start: String
    let sem2End: String
    
    // The backend now sends a single combined list of events
    let events: [RemoteEventData]
}

// Intermediate struct to handle the backend's "date" format
struct RemoteEventData: Codable {
    let id: String
    let name: String
    let date: String
    let type: String
}

class AcademicCalendarManager: ObservableObject {
    static let shared = AcademicCalendarManager()
    
    // ✅ FIXED: Points to the API endpoint, not a static .json file
    private let remoteCalendarsURL = URL(string: "https://fsega-4hgketyi6-robus-projects-a31a9e42.vercel.app/api/academic_calendars")!
    
    @Published var currentAcademicYear: AcademicCalendarData? {
        didSet {
            // Update master date range when calendar changes
            if let start = getDate(from: currentAcademicYear?.semester1.events.first?.start ?? ""),
               let end = getDate(from: currentAcademicYear?.semester2.events.last?.end ?? "") {
                self.startDate = start
                self.endDate = end
            }
        }
    }
    
    @Published var availableCalendars: [AcademicCalendarData] = []
    @Published var availableTemplates: [CalendarTemplate] = []
    
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Date()
    @Published var currentSemester: SemesterType = .semester1
    @Published var isFetching: Bool = false
    @Published var lastFetchError: String?
    
    // Cache to store the detailed events
    private var cachedRemoteData: [String: RemoteCalendarTemplate] = [:]
    
    enum SemesterType: String {
        case semester1 = "Semester 1"
        case semester2 = "Semester 2"
        var displayName: String { self.rawValue }
    }
    
    init() {
        loadLocalTemplates()
        fetchRemoteCalendars()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.availableCalendars.isEmpty {
                self.loadDemoData()
            }
        }
    }
    
    // MARK: - 🌍 Vercel API Fetching
    
    func fetchRemoteCalendars() {
        isFetching = true
        print("🌍 Fetching calendars from: \(remoteCalendarsURL)")
        
        URLSession.shared.dataTask(with: remoteCalendarsURL) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isFetching = false
                
                if let error = error {
                    print("❌ Vercel Fetch Error: \(error.localizedDescription)")
                    self?.lastFetchError = error.localizedDescription
                    return
                }
                
                guard let data = data else { return }
                
                // Debugging: Print response to console
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Server Response: \(responseString.prefix(500))...")
                }
                
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode(RemoteCalendarResponse.self, from: data)
                    self?.mergeRemoteTemplates(result.calendars)
                    print("✅ Successfully fetched \(result.calendars.count) calendars")
                } catch {
                    print("❌ JSON Parsing Error: \(error)")
                    self?.lastFetchError = "Data Mismatch: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    private func mergeRemoteTemplates(_ remoteTemplates: [RemoteCalendarTemplate]) {
        for remote in remoteTemplates {
            // 1. Create a display template for the list
            let template = CalendarTemplate(
                universityName: remote.universityName,
                academicYear: remote.academicYear,
                sem1Start: remote.sem1Start,
                sem1End: remote.sem1End,
                sem2Start: remote.sem2Start,
                sem2End: remote.sem2End
            )
            
            // 2. Remove duplicates
            availableTemplates.removeAll { $0.universityName == remote.universityName && $0.academicYear == remote.academicYear }
            
            // 3. Add to top
            availableTemplates.insert(template, at: 0)
            
            // 4. Cache data
            let key = remote.universityName + remote.academicYear
            self.cachedRemoteData[key] = remote
        }
    }
    
    // MARK: - Logic & Helpers
    
    func generateAndSaveCalendar(from template: CalendarTemplate) {
        let key = template.universityName + template.academicYear
        var sem1Events: [AcademicEventData] = []
        var sem2Events: [AcademicEventData] = []
        
        if let remoteData = cachedRemoteData[key] {
            // ✅ NEW LOGIC: Convert "Remote Events" to "App Events"
            // The backend sends single dates, we map them to ranges of 1 day (or logic appropriate for your app)
            
            let allConvertedEvents = remoteData.events.map { remoteEvent -> AcademicEventData in
                // Map backend types to local enum
                let mappedType: EventType
                switch remoteEvent.type.lowercased() {
                case "administrative": mappedType = .administrative
                case "holiday": mappedType = .holiday
                case "exam": mappedType = .exam
                default: mappedType = .teaching
                }
                
                return AcademicEventData(
                    id: UUID(), // Generate new local ID
                    start: remoteEvent.date,
                    end: remoteEvent.date, // Single day event
                    type: mappedType,
                    weeks: 1,
                    customName: remoteEvent.name
                )
            }
            
            // Split into semesters based on Sem 1 End Date
            if let s1End = getDate(from: remoteData.sem1End) {
                sem1Events = allConvertedEvents.filter { event in
                    guard let d = getDate(from: event.start) else { return false }
                    return d <= s1End
                }
                sem2Events = allConvertedEvents.filter { event in
                    guard let d = getDate(from: event.start) else { return false }
                    return d > s1End
                }
            }
            
            // Fallback: If no events, create default "Teaching" blocks so week calculation works
            if sem1Events.isEmpty {
                 sem1Events.append(AcademicEventData(start: template.sem1Start, end: template.sem1End, type: .teaching, weeks: 14, customName: "Teaching Semester 1"))
            }
            if sem2Events.isEmpty {
                 sem2Events.append(AcademicEventData(start: template.sem2Start, end: template.sem2End, type: .teaching, weeks: 14, customName: "Teaching Semester 2"))
            }
            
        } else {
            // Offline Fallback
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
    
    private func loadLocalTemplates() {
        availableTemplates = [
            CalendarTemplate(
                universityName: "Standard US Semester",
                academicYear: "2025-2026",
                sem1Start: "2025-08-25", sem1End: "2025-12-12",
                sem2Start: "2026-01-12", sem2End: "2026-05-08"
            )
        ]
    }
    
    func loadDemoData() {
        if let first = availableTemplates.first {
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
    
    // MARK: - 🧠 Week Logic
    
    var currentTeachingWeek: Int? {
        return getTeachingWeek(for: Date())
    }
    
    var currentWeekProgress: Int {
        return calculateWeek(for: Date(), strictTeachingOnly: false) ?? 1
    }
    
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
            
            if date >= start && date <= end {
                if event.type == .teaching {
                    let weeksSinceStart = Calendar.current.dateComponents([.weekOfYear], from: start, to: date).weekOfYear ?? 0
                    return cumulativeWeeks + weeksSinceStart + 1
                } else {
                    return strictTeachingOnly ? nil : cumulativeWeeks
                }
            }
            
            if date > end && event.type == .teaching {
                cumulativeWeeks += event.weeks
            }
        }
        return strictTeachingOnly ? nil : cumulativeWeeks
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
