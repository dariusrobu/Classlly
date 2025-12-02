import SwiftUI
import Combine
import SwiftData

// MARK: - SHARED MODELS
enum CalendarEvent: Identifiable {
    case task(StudyTask)
    case `class`(subject: Subject, isCourse: Bool, date: Date)
    
    var id: String {
        switch self {
        case .task(let task):
            return "task-\(task.id.uuidString)"
        case .class(let subject, let isCourse, let date):
            let type = isCourse ? "course" : "seminar"
            return "class-\(subject.id.uuidString)-\(type)-\(date.timeIntervalSince1970)"
        }
    }
    
    var icon: String {
        switch self {
        case .task: return "checkmark.circle"
        case .class(_, let isCourse, _): return isCourse ? "book.fill" : "person.2.fill"
        }
    }
    
    var startTime: Date {
        switch self {
        case .task(let task): return task.dueDate ?? Date()
        case .class(let subject, let isCourse, _): return isCourse ? subject.courseStartTime : subject.seminarStartTime
        }
    }
    
    var endTime: Date {
        switch self {
        case .task: return startTime
        case .class(let subject, let isCourse, _): return isCourse ? subject.courseEndTime : subject.seminarEndTime
        }
    }
    
    var title: String {
        switch self {
        case .task(let task): return task.title
        case .class(let subject, let isCourse, _):
            let type = isCourse ? "Course" : "Seminar"
            return "\(subject.title) (\(type))"
        }
    }
    
    var subtitle: String {
        switch self {
        case .task(let task): return task.subject?.title ?? "No Subject"
        case .class(let subject, let isCourse, _):
            let teacher = isCourse ? subject.courseTeacher : subject.seminarTeacher
            let room = isCourse ? subject.courseClassroom : subject.seminarClassroom
            return "\(teacher) • \(room)"
        }
    }
    
    var color: Color {
        switch self {
        case .task: return .themeWarning
        case .class(_, let isCourse, _): return isCourse ? .themePrimary : .themeSuccess
        }
    }
    
    var frequencyInfo: String? {
        switch self {
        case .task: return nil
        case .class(let subject, let isCourse, _):
            return isCourse ? subject.courseFrequencyString : subject.seminarFrequencyString
        }
    }
}

// MARK: - MAIN SWITCHER VIEW
struct CalendarView: View {
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        NavigationView {
            Group {
                switch themeManager.selectedGameMode {
                case .arcade:
                    ArcadeCalendarView()
                case .retro:
                    RetroCalendarView()
                case .none:
                    StandardCalendarView()
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }
    
    private var navigationTitle: String {
        switch themeManager.selectedGameMode {
        case .none: return "Calendar"
        case .arcade: return "Mission Log"
        case .retro: return "Time Database"
        }
    }
}

// MARK: - 👔 STANDARD CALENDAR VIEW
struct StandardCalendarView: View {
    @State private var currentDate = Date()
    @State private var selectedDate = Date()
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    
    @Query var subjects: [Subject]
    @Query var tasks: [StudyTask]
    
    @State private var selectedTask: StudyTask?
    @State private var selectedSubject: Subject?
    @State private var showingTaskDetail = false
    @State private var showingSubjectDetail = false
    @State private var showingAddTask = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                if let currentWeek = calendarManager.currentTeachingWeek {
                    HStack {
                        Image(systemName: "clock.badge.checkmark")
                            .foregroundColor(currentWeek % 2 == 1 ? .themeWarning : .themePrimary)
                        Text("Week \(currentWeek) • \(currentWeek % 2 == 1 ? "ODD" : "EVEN")")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(currentWeek % 2 == 1 ? .themeWarning : .themePrimary)
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(calendarManager.currentSemester.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Week Controls
            VStack(spacing: 12) {
                HStack {
                    Button(action: previousWeek) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.themePrimary)
                            .frame(width: 30, height: 30)
                            .background(Color.themePrimary.opacity(0.1))
                            .clipShape(Circle())
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text(weekRangeString)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.themeTextPrimary)
                        Text(currentDate, formatter: monthYearFormatter)
                            .font(.subheadline)
                            .foregroundColor(.themeTextSecondary)
                    }
                    Spacer()
                    Button(action: nextWeek) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.themePrimary)
                            .frame(width: 30, height: 30)
                            .background(Color.themePrimary.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 16)
            .padding(.horizontal)
            
            // Grid
            WeeklyCalendarGrid(
                currentDate: $currentDate,
                selectedDate: $selectedDate
            )
            .padding(.horizontal)
            
            // Events
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Events for \(formattedSelectedDate)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.themeTextPrimary)
                    Spacer()
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.themePrimary)
                    }
                }
                .padding(.horizontal)
                
                if eventsForSelectedDate.isEmpty {
                    CalendarEmptyStateView(
                        icon: "calendar",
                        title: "No Events",
                        message: "No classes or tasks scheduled for this day."
                    )
                    .padding(.horizontal)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(eventsForSelectedDate) { event in
                                EventRow(event: event)
                                    .onTapGesture { handleEventTap(event) }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
            
            Spacer()
        }
        .sheet(isPresented: $showingTaskDetail) {
            if let task = selectedTask { EditTaskView(task: task) }
        }
        .sheet(isPresented: $showingSubjectDetail) {
            if let subject = selectedSubject { SubjectDetailView(subject: subject) }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
        }
    }
    
    // Logic Helpers
    private var eventsForSelectedDate: [CalendarEvent] {
        CommonCalendarLogic.getEvents(
            for: selectedDate,
            subjects: subjects,
            tasks: tasks,
            calendarManager: calendarManager
        )
    }
    
    private var weekRangeString: String {
        CommonCalendarLogic.weekRangeString(for: currentDate)
    }
    
    private var formattedSelectedDate: String {
        CommonCalendarLogic.formatDate(selectedDate)
    }
    
    private func previousWeek() {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentDate) {
            currentDate = newDate
        }
    }
    
    private func nextWeek() {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDate) {
            currentDate = newDate
        }
    }
    
    private func handleEventTap(_ event: CalendarEvent) {
        switch event {
        case .task(let task):
            selectedTask = task
            showingTaskDetail = true
        case .class(let subject, _, _):
            selectedSubject = subject
            showingSubjectDetail = true
        }
    }
}

// MARK: - 🕹️ ARCADE CALENDAR VIEW
struct ArcadeCalendarView: View {
    @State private var currentDate = Date()
    @State private var selectedDate = Date()
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @Query var subjects: [Subject]
    @Query var tasks: [StudyTask]
    
    @State private var selectedTask: StudyTask?
    @State private var selectedSubject: Subject?
    @State private var showingDetail = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Arcade Header
                HStack {
                    Button(action: { currentDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentDate) ?? currentDate }) {
                        Image(systemName: "arrowtriangle.left.fill")
                            .foregroundColor(.cyan)
                    }
                    
                    VStack {
                        Text(CommonCalendarLogic.weekRangeString(for: currentDate).uppercased())
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.black)
                            .foregroundColor(.white)
                            .shadow(color: .cyan, radius: 5)
                        
                        Text("Sector \(calendarManager.currentTeachingWeek ?? 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(4)
                            .background(Color.cyan.opacity(0.2))
                            .cornerRadius(4)
                            .foregroundColor(.cyan)
                    }
                    
                    Button(action: { currentDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate }) {
                        Image(systemName: "arrowtriangle.right.fill")
                            .foregroundColor(.cyan)
                    }
                }
                .padding(.top)
                
                // Arcade Grid
                ArcadeCalendarGrid(currentDate: $currentDate, selectedDate: $selectedDate)
                
                // Mission List
                VStack(alignment: .leading, spacing: 12) {
                    Text("ACTIVE MISSIONS")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.heavy)
                        .foregroundColor(.yellow)
                        .padding(.horizontal)
                    
                    let events = CommonCalendarLogic.getEvents(for: selectedDate, subjects: subjects, tasks: tasks, calendarManager: calendarManager)
                    
                    if events.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "moon.stars.fill")
                                .font(.largeTitle)
                                .foregroundColor(.purple)
                            Text("No missions detected in this sector.")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(events) { event in
                                    ArcadeEventRow(event: event)
                                        .onTapGesture {
                                            // Handle tap logic if needed
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - 👾 RETRO CALENDAR VIEW
struct RetroCalendarView: View {
    @State private var currentDate = Date()
    @State private var selectedDate = Date()
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @Query var subjects: [Subject]
    @Query var tasks: [StudyTask]
    
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.05).ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Retro Header
                HStack {
                    Button(action: { currentDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentDate) ?? currentDate }) {
                        Text("< PREV")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    Spacer()
                    VStack {
                        Text(CommonCalendarLogic.weekRangeString(for: currentDate))
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(.green)
                        Text("WEEK_ID: \(calendarManager.currentTeachingWeek ?? 0)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button(action: { currentDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate }) {
                        Text("NEXT >")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .border(Color.green, width: 1)
                .padding(.horizontal)
                
                // Retro Grid
                RetroCalendarGrid(currentDate: $currentDate, selectedDate: $selectedDate)
                    .padding(.horizontal)
                
                // Encounters
                VStack(alignment: .leading, spacing: 0) {
                    Text("> SCHEDULED_ENCOUNTERS")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    
                    let events = CommonCalendarLogic.getEvents(for: selectedDate, subjects: subjects, tasks: tasks, calendarManager: calendarManager)
                    
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            if events.isEmpty {
                                Text("NO DATA FOUND.")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.gray)
                                    .padding(.top, 40)
                            } else {
                                ForEach(events) { event in
                                    RetroEventRow(event: event)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - SHARED LOGIC HELPER
struct CommonCalendarLogic {
    static func getEvents(for date: Date, subjects: [Subject], tasks: [StudyTask], calendarManager: AcademicCalendarManager) -> [CalendarEvent] {
        let tasksOnDate = tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return Calendar.current.isDate(dueDate, inSameDayAs: date)
        }
        
        var classEvents: [CalendarEvent] = []
        let weekday = Calendar.current.component(.weekday, from: date)
        
        // Helper to estimate academic week based on current date vs selected date
        // This is a simplified version. In a real app, you'd calculate exact week diff.
        let academicWeek = calendarManager.currentTeachingWeek
        
        for subject in subjects {
            if subject.courseDays.contains(weekday) &&
               subject.occursThisWeek(academicWeek: academicWeek, isCourse: true) {
                classEvents.append(.class(subject: subject, isCourse: true, date: date))
            }
            
            if subject.seminarDays.contains(weekday) &&
               subject.occursThisWeek(academicWeek: academicWeek, isCourse: false) {
                classEvents.append(.class(subject: subject, isCourse: false, date: date))
            }
        }
        
        let taskEvents = tasksOnDate.map { CalendarEvent.task($0) }
        return (taskEvents + classEvents).sorted { $0.startTime < $1.startTime }
    }
    
    static func weekRangeString(for date: Date) -> String {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return "This Week"
        }
        let start = weekInterval.start
        let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
    
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

// MARK: - SUB-VIEWS (Grids & Rows)

// 1. STANDARD GRID (Unchanged)
struct WeeklyCalendarGrid: View {
    @Binding var currentDate: Date
    @Binding var selectedDate: Date
    
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day).font(.caption).foregroundColor(.secondary)
                }
            }
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(getDaysInWeek(), id: \.self) { date in
                    let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                    let isToday = Calendar.current.isDateInToday(date)
                    
                    VStack(spacing: 4) {
                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isSelected ? .white : (isToday ? .themePrimary : .primary))
                            .frame(height: 40)
                            .frame(maxWidth: .infinity)
                            .background(
                                ZStack {
                                    if isSelected { Circle().fill(Color.themePrimary) }
                                    else if isToday { Circle().stroke(Color.themePrimary, lineWidth: 2) }
                                }
                            )
                        Text(getDayAbbrev(date)).font(.system(size: 12))
                    }
                    .onTapGesture { selectedDate = date }
                }
            }
        }
        .padding().background(Color.themeSurface).cornerRadius(12)
    }
    
    private func getDaysInWeek() -> [Date] {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentDate) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekInterval.start) }
    }
    
    private func getDayAbbrev(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "E"; return f.string(from: date)
    }
}

// 2. ARCADE GRID
struct ArcadeCalendarGrid: View {
    @Binding var currentDate: Date
    @Binding var selectedDate: Date
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(getDaysInWeek(), id: \.self) { date in
                    let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                    
                    VStack {
                        Text(getDayAbbrev(date).uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.cyan.opacity(0.7))
                        
                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(isSelected ? .black : .white)
                            .frame(width: 40, height: 40)
                            .background(
                                ZStack {
                                    if isSelected {
                                        Circle().fill(Color.cyan)
                                            .shadow(color: .cyan, radius: 8)
                                    } else {
                                        Circle().fill(Color.white.opacity(0.1))
                                    }
                                }
                            )
                    }
                    .onTapGesture { selectedDate = date }
                }
            }
        }
        .padding()
        .background(Color(white: 0.05))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.cyan.opacity(0.3), lineWidth: 1))
        .padding(.horizontal)
    }
    
    private func getDaysInWeek() -> [Date] {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentDate) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekInterval.start) }
    }
    
    private func getDayAbbrev(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "E"; return f.string(from: date)
    }
}

// 3. RETRO GRID
struct RetroCalendarGrid: View {
    @Binding var currentDate: Date
    @Binding var selectedDate: Date
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(getDaysInWeek(), id: \.self) { date in
                let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                
                VStack(spacing: 8) {
                    Text(getDayAbbrev(date))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.green)
                    
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(isSelected ? .black : .green)
                        .frame(width: 30, height: 30)
                        .background(isSelected ? Color.green : Color.clear)
                        .overlay(Rectangle().stroke(Color.green, lineWidth: 1))
                }
                .padding(.vertical, 8)
                .onTapGesture { selectedDate = date }
            }
        }
        .border(Color.green.opacity(0.5), width: 1)
    }
    
    private func getDaysInWeek() -> [Date] {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentDate) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekInterval.start) }
    }
    
    private func getDayAbbrev(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "E"; return f.string(from: date)
    }
}

// 4. ARCADE EVENT ROW
struct ArcadeEventRow: View {
    let event: CalendarEvent
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(event.color)
                .frame(width: 4, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(timeString)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Image(systemName: event.icon)
                .font(.title2)
                .foregroundColor(event.color)
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(event.color.opacity(0.3), lineWidth: 1))
    }
    
    var timeString: String {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f.string(from: event.startTime)
    }
}

// 5. RETRO EVENT ROW
struct RetroEventRow: View {
    let event: CalendarEvent
    
    var body: some View {
        HStack {
            Text("[ ]")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.green)
            
            VStack(alignment: .leading) {
                Text(event.title.uppercased())
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.green)
                Text(event.subtitle.uppercased())
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.gray)
            }
            Spacer()
            Text(timeString)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.green)
        }
        .padding()
        .border(Color.green.opacity(0.3), width: 1)
        .background(Color.black)
    }
    
    var timeString: String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: event.startTime)
    }
}

// 6. STANDARD EVENT ROW & EMPTY STATE (Unchanged but included)
struct EventRow: View {
    let event: CalendarEvent
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Circle().fill(event.color).frame(width: 12, height: 12)
                Rectangle().fill(event.color).frame(width: 2).frame(maxHeight: .infinity)
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(event.startTime, formatter: timeFormatter).font(.subheadline).fontWeight(.medium).foregroundColor(event.color)
                    Spacer()
                }
                Text(event.title).font(.headline).foregroundColor(.themeTextPrimary)
                HStack {
                    Image(systemName: event.icon).font(.caption).foregroundColor(.themeTextSecondary)
                    Text(event.subtitle).font(.subheadline).foregroundColor(.themeTextSecondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.secondary)
        }
        .padding().background(Color.themeSurface).cornerRadius(12)
    }
    
    private let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f
    }()
}

struct CalendarEmptyStateView: View {
    let icon: String; let title: String; let message: String
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon).font(.system(size: 48)).foregroundColor(.secondary)
            VStack(spacing: 8) {
                Text(title).font(.headline).foregroundColor(.themeTextPrimary)
                Text(message).font(.subheadline).foregroundColor(.themeTextSecondary).multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 40)
    }
}

private let monthYearFormatter: DateFormatter = {
    let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f
}()
