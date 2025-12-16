import SwiftUI
import Combine
import SwiftData

// MARK: - CALENDAR EVENT MODEL
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

// MARK: - MAIN SWITCHER
struct CalendarView: View {
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .rainbow:
                RainbowCalendarView()
            case .arcade:
                ArcadeCalendarView()
            case .none:
                StandardCalendarView()
            }
        }
    }
}

// MARK: - 🌈 RAINBOW CALENDAR
struct RainbowCalendarView: View {
    @State private var currentDate = Date()
    @State private var selectedDate = Date()
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @EnvironmentObject var themeManager: AppTheme
    @Environment(\.colorScheme) var colorScheme
    
    @Query var subjects: [Subject]
    @Query var tasks: [StudyTask]
    
    @State private var selectedTask: StudyTask?
    @State private var selectedSubject: Subject?
    @State private var showingTaskDetail = false
    @State private var showingSubjectDetail = false
    @State private var showingAddTask = false
    
    var body: some View {
        let accentColor = themeManager.selectedTheme.primaryColor
        
        VStack(spacing: 0) {
            // 1. CUSTOM HEADER
            RainbowHeader(
                title: "Calendar",
                accentColor: accentColor,
                showBackButton: false,
                backAction: nil,
                trailingIcon: "plus",
                trailingAction: { showingAddTask = true }
            )
            
            ZStack(alignment: .top) {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // 2. Week Info & Date Controls
                    VStack(spacing: 16) {
                        // Week Label
                        if let currentWeek = calendarManager.currentTeachingWeek {
                            HStack {
                                Text("Week \(currentWeek)")
                                    .font(.title2).fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("•")
                                    .foregroundColor(.gray)
                                Text(calendarManager.currentSemester.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        
                        // Arrows + Date Range
                        HStack {
                            Button(action: previousWeek) {
                                Image(systemName: "chevron.left")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(RainbowColors.darkCard)
                                    .clipShape(Circle())
                            }
                            
                            Spacer()
                            
                            VStack(spacing: 4) {
                                Text(weekRangeString)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text(currentDate, formatter: monthYearFormatter)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(accentColor)
                            }
                            
                            Spacer()
                            
                            Button(action: nextWeek) {
                                Image(systemName: "chevron.right")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(RainbowColors.darkCard)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // 3. Calendar Grid
                    RainbowContainer {
                        RainbowWeeklyCalendarGrid(currentDate: $currentDate, selectedDate: $selectedDate, accentColor: accentColor)
                    }
                    .padding(.horizontal)
                    
                    // 4. Events List
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Events")
                                .font(.title3).bold()
                                .foregroundColor(.white)
                            Text(formattedSelectedDate)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        if eventsForSelectedDate.isEmpty {
                            Spacer()
                            VStack(spacing: 16) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 50))
                                    .foregroundColor(RainbowColors.darkCard.opacity(2))
                                Text("No events today")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            Spacer()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(eventsForSelectedDate) { event in
                                        RainbowEventRow(event: event)
                                            .onTapGesture { handleEventTap(event) }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 20)
                            }
                        }
                    }
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showingTaskDetail) { if let t = selectedTask { EditTaskView(task: t) } }
        .sheet(isPresented: $showingSubjectDetail) { if let s = selectedSubject { SubjectDetailView(subject: s) } }
        .sheet(isPresented: $showingAddTask) { AddTaskView() }
    }
    
    // Logic Helpers
    private var eventsForSelectedDate: [CalendarEvent] {
        let tasksOnDate = tasks.filter { task in guard let d = task.dueDate else { return false }; return Calendar.current.isDate(d, inSameDayAs: selectedDate) }
        var classEvents: [CalendarEvent] = []
        let weekday = Calendar.current.component(.weekday, from: selectedDate)
        let academicWeek = calendarManager.currentTeachingWeek
        
        for subject in subjects {
            if subject.courseDays.contains(weekday) && subject.occursThisWeek(academicWeek: academicWeek, isCourse: true) {
                classEvents.append(.class(subject: subject, isCourse: true, date: selectedDate))
            }
            if subject.seminarDays.contains(weekday) && subject.occursThisWeek(academicWeek: academicWeek, isCourse: false) {
                classEvents.append(.class(subject: subject, isCourse: false, date: selectedDate))
            }
        }
        let taskEvents = tasksOnDate.map { CalendarEvent.task($0) }
        return (taskEvents + classEvents).sorted { $0.startTime < $1.startTime }
    }
    
    private var weekRangeString: String {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: currentDate) else { return "This Week" }
        let end = calendar.date(byAdding: .day, value: 6, to: interval.start) ?? interval.start
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return "\(f.string(from: interval.start)) - \(f.string(from: end))"
    }
    
    private var formattedSelectedDate: String { let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: selectedDate) }
    private func previousWeek() { if let d = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentDate) { currentDate = d } }
    private func nextWeek() { if let d = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDate) { currentDate = d } }
    
    private func handleEventTap(_ event: CalendarEvent) {
        switch event {
        case .task(let t): selectedTask = t; showingTaskDetail = true
        case .class(let s, _, _): selectedSubject = s; showingSubjectDetail = true
        }
    }
}

// MARK: - RAINBOW CALENDAR COMPONENTS

struct RainbowWeeklyCalendarGrid: View {
    @Binding var currentDate: Date
    @Binding var selectedDate: Date
    let accentColor: Color
    
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .frame(height: 30)
                }
            }
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(getDaysInWeek(), id: \.self) { date in
                    let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                    let isToday = Calendar.current.isDateInToday(date)
                    
                    VStack {
                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isSelected ? .white : (isToday ? accentColor : .white))
                            .frame(width: 40, height: 40)
                            .background(
                                ZStack {
                                    if isSelected {
                                        Circle().fill(accentColor)
                                    } else if isToday {
                                        Circle().stroke(accentColor, lineWidth: 2)
                                    }
                                }
                            )
                    }
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            selectedDate = date
                        }
                    }
                }
            }
        }
    }
    
    private func getDaysInWeek() -> [Date] {
        let c = Calendar.current
        guard let i = c.dateInterval(of: .weekOfYear, for: currentDate) else { return [] }
        return (0..<7).compactMap { c.date(byAdding: .day, value: $0, to: i.start) }
    }
}

struct RainbowEventRow: View {
    let event: CalendarEvent
    
    var body: some View {
        RainbowContainer {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: event.icon)
                        .font(.headline)
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(event.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundColor(iconColor)
                        Text(event.startTime, formatter: timeFormatter)
                            .font(.caption)
                            .foregroundColor(iconColor)
                            .fontWeight(.medium)
                        
                        if let fi = event.frequencyInfo {
                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(fi)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(4)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var iconColor: Color {
        switch event {
        case .task: return RainbowColors.orange
        case .class(_, let isCourse, _): return isCourse ? RainbowColors.blue : RainbowColors.green
        }
    }
    
    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()
}

// MARK: - STANDARD CALENDAR VIEW
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
        NavigationStack {
            VStack(spacing: 0) {
                // Header Info
                VStack(spacing: 8) {
                    if let currentWeek = calendarManager.currentTeachingWeek {
                        HStack {
                            Image(systemName: "clock.badge.checkmark")
                                .foregroundColor(currentWeek % 2 == 1 ? .themeWarning : .themePrimary)
                            Text("Week \(currentWeek) • \(currentWeek % 2 == 1 ? "ODD" : "EVEN")")
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundColor(currentWeek % 2 == 1 ? .themeWarning : .themePrimary)
                            Text("•").foregroundColor(.secondary)
                            Text(calendarManager.currentSemester.displayName)
                                .font(.subheadline).foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }.padding(.horizontal).padding(.top, 8)
                
                // Date Controls
                VStack(spacing: 12) {
                    HStack {
                        Button(action: previousWeek) {
                            Image(systemName: "chevron.left").font(.system(size: 16, weight: .medium)).foregroundColor(.themePrimary)
                                .frame(width: 30, height: 30).background(Color.themePrimary.opacity(0.1)).clipShape(Circle())
                        }
                        Spacer()
                        VStack(spacing: 2) {
                            Text(weekRangeString).font(.title2).fontWeight(.semibold).foregroundColor(.themeTextPrimary)
                            Text(currentDate, formatter: monthYearFormatter).font(.subheadline).foregroundColor(.themeTextSecondary)
                        }
                        Spacer()
                        Button(action: nextWeek) {
                            Image(systemName: "chevron.right").font(.system(size: 16, weight: .medium)).foregroundColor(.themePrimary)
                                .frame(width: 30, height: 30).background(Color.themePrimary.opacity(0.1)).clipShape(Circle())
                        }
                    }.padding(.horizontal, 8)
                }.padding(.vertical, 16).padding(.horizontal)
                
                // Calendar Grid
                WeeklyCalendarGrid(currentDate: $currentDate, selectedDate: $selectedDate).padding(.horizontal)
                
                // Events List
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Events for \(formattedSelectedDate)").font(.headline).fontWeight(.semibold).foregroundColor(.themeTextPrimary)
                        Spacer()
                        Button(action: { showingAddTask = true }) { Image(systemName: "plus.circle.fill").font(.system(size: 20, weight: .medium)).foregroundColor(.themePrimary) }
                    }.padding(.horizontal)
                    
                    if eventsForSelectedDate.isEmpty {
                        CalendarEmptyStateView(icon: "calendar", title: "No Events", message: "No classes or tasks.")
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(eventsForSelectedDate) { event in
                                    EventRow(event: event).onTapGesture { handleEventTap(event) }
                                }
                            }.padding(.horizontal)
                        }
                    }
                }.padding(.vertical)
                Spacer()
            }
            .navigationTitle("Calendar").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingTaskDetail) { if let t = selectedTask { EditTaskView(task: t) } }
            .sheet(isPresented: $showingSubjectDetail) { if let s = selectedSubject { SubjectDetailView(subject: s) } }
            .sheet(isPresented: $showingAddTask) { AddTaskView() }
        }
    }
    
    // Logic Helpers
    private var eventsForSelectedDate: [CalendarEvent] {
        let tasksOnDate = tasks.filter { task in guard let d = task.dueDate else { return false }; return Calendar.current.isDate(d, inSameDayAs: selectedDate) }
        var classEvents: [CalendarEvent] = []
        let weekday = Calendar.current.component(.weekday, from: selectedDate)
        let academicWeek = calendarManager.currentTeachingWeek
        
        for subject in subjects {
            if subject.courseDays.contains(weekday) && subject.occursThisWeek(academicWeek: academicWeek, isCourse: true) {
                classEvents.append(.class(subject: subject, isCourse: true, date: selectedDate))
            }
            if subject.seminarDays.contains(weekday) && subject.occursThisWeek(academicWeek: academicWeek, isCourse: false) {
                classEvents.append(.class(subject: subject, isCourse: false, date: selectedDate))
            }
        }
        let taskEvents = tasksOnDate.map { CalendarEvent.task($0) }
        return (taskEvents + classEvents).sorted { $0.startTime < $1.startTime }
    }
    
    private var weekRangeString: String {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: currentDate) else { return "This Week" }
        let end = calendar.date(byAdding: .day, value: 6, to: interval.start) ?? interval.start
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return "\(f.string(from: interval.start)) - \(f.string(from: end))"
    }
    
    private var formattedSelectedDate: String { let f = DateFormatter(); f.dateStyle = .long; return f.string(from: selectedDate) }
    private func previousWeek() { if let d = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentDate) { currentDate = d } }
    private func nextWeek() { if let d = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDate) { currentDate = d } }
    
    private func handleEventTap(_ event: CalendarEvent) {
        switch event {
        case .task(let t): selectedTask = t; showingTaskDetail = true
        case .class(let s, _, _): selectedSubject = s; showingSubjectDetail = true
        }
    }
}

// MARK: - 🕹️ ARCADE CALENDAR
struct ArcadeCalendarView: View {
    @State private var currentDate = Date(); @State private var selectedDate = Date()
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @Query var subjects: [Subject]; @Query var tasks: [StudyTask]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Button(action: { currentDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentDate) ?? currentDate }) { Image(systemName: "arrowtriangle.left.fill").foregroundColor(.cyan) }
                        VStack {
                            Text(weekRangeString.uppercased()).font(.system(.headline, design: .rounded)).fontWeight(.black).foregroundColor(.white).shadow(color: .cyan, radius: 5)
                            Text("SECTOR \(calendarManager.currentTeachingWeek ?? 1)").font(.caption).fontWeight(.bold).padding(4).background(Color.cyan.opacity(0.2)).cornerRadius(4).foregroundColor(.cyan)
                        }
                        Button(action: { currentDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate }) { Image(systemName: "arrowtriangle.right.fill").foregroundColor(.cyan) }
                    }.padding(.top)
                    
                    // Grid
                    ArcadeCalendarGrid(currentDate: $currentDate, selectedDate: $selectedDate)
                    
                    // List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ACTIVE MISSIONS").font(.system(.title3, design: .rounded)).fontWeight(.heavy).foregroundColor(.yellow).padding(.horizontal)
                        if eventsForSelectedDate.isEmpty {
                            VStack(spacing: 12) { Image(systemName: "moon.stars.fill").font(.largeTitle).foregroundColor(.purple); Text("No missions detected.").font(.system(.body, design: .rounded)).foregroundColor(.gray) }.frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ScrollView { LazyVStack(spacing: 16) { ForEach(eventsForSelectedDate) { event in ArcadeEventRow(event: event) } }.padding(.horizontal) }
                        }
                    }
                    Spacer()
                }
            }
            .navigationTitle("Mission Log").navigationBarTitleDisplayMode(.inline)
        }.preferredColorScheme(.dark)
    }
    
    private var eventsForSelectedDate: [CalendarEvent] {
        let tasksOnDate = tasks.filter { t in guard let d = t.dueDate else { return false }; return Calendar.current.isDate(d, inSameDayAs: selectedDate) }
        var classEvents: [CalendarEvent] = []
        let weekday = Calendar.current.component(.weekday, from: selectedDate)
        let aw = calendarManager.currentTeachingWeek
        for s in subjects {
            if s.courseDays.contains(weekday) && s.occursThisWeek(academicWeek: aw, isCourse: true) { classEvents.append(.class(subject: s, isCourse: true, date: selectedDate)) }
            if s.seminarDays.contains(weekday) && s.occursThisWeek(academicWeek: aw, isCourse: false) { classEvents.append(.class(subject: s, isCourse: false, date: selectedDate)) }
        }
        return (tasksOnDate.map { CalendarEvent.task($0) } + classEvents).sorted { $0.startTime < $1.startTime }
    }
    private var weekRangeString: String {
        let c = Calendar.current; guard let i = c.dateInterval(of: .weekOfYear, for: currentDate) else { return "" }
        let e = c.date(byAdding: .day, value: 6, to: i.start) ?? i.start
        let f = DateFormatter(); f.dateFormat = "MMM d"; return "\(f.string(from: i.start)) - \(f.string(from: e))"
    }
}

struct ArcadeCalendarGrid: View {
    @Binding var currentDate: Date; @Binding var selectedDate: Date; private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    var body: some View {
        VStack {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(getDaysInWeek(), id: \.self) { date in
                    let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                    VStack {
                        Text(getDayAbbrev(date).uppercased()).font(.system(size: 10, weight: .bold)).foregroundColor(.cyan.opacity(0.7))
                        Text("\(Calendar.current.component(.day, from: date))").font(.system(.title3, design: .rounded)).fontWeight(.bold).foregroundColor(isSelected ? .black : .white).frame(width: 40, height: 40).background(ZStack { if isSelected { Circle().fill(Color.cyan).shadow(color: .cyan, radius: 8) } else { Circle().fill(Color.white.opacity(0.1)) } })
                    }.onTapGesture { selectedDate = date }
                }
            }
        }.padding().background(Color(white: 0.05)).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.cyan.opacity(0.3), lineWidth: 1)).padding(.horizontal)
    }
    private func getDaysInWeek() -> [Date] { let c = Calendar.current; guard let i = c.dateInterval(of: .weekOfYear, for: currentDate) else { return [] }; return (0..<7).compactMap { c.date(byAdding: .day, value: $0, to: i.start) } }
    private func getDayAbbrev(_ date: Date) -> String { let f = DateFormatter(); f.dateFormat = "E"; return f.string(from: date) }
}

struct ArcadeEventRow: View {
    let event: CalendarEvent
    var body: some View {
        HStack(spacing: 16) {
            Circle().fill(event.color).frame(width: 4, height: 40)
            VStack(alignment: .leading, spacing: 4) { Text(event.title).font(.system(.headline, design: .rounded)).fontWeight(.bold).foregroundColor(.white); HStack { Image(systemName: "clock.fill").font(.caption2).foregroundColor(.gray); Text(timeString).font(.caption).foregroundColor(.gray) } }
            Spacer(); Image(systemName: event.icon).font(.title2).foregroundColor(event.color)
        }.padding().background(Color(white: 0.1)).cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(event.color.opacity(0.3), lineWidth: 1))
    }
    var timeString: String { let f = DateFormatter(); f.dateFormat = "h:mm a"; return f.string(from: event.startTime) }
}

// MARK: - SHARED HELPERS (Calendar Specific)
struct WeeklyCalendarGrid: View {
    @Binding var currentDate: Date; @Binding var selectedDate: Date; @Environment(\.colorScheme) var colorScheme
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]; private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    var body: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: columns, spacing: 10) { ForEach(daysOfWeek, id: \.self) { day in Text(day).font(.caption).fontWeight(.medium).foregroundColor(.secondary).frame(height: 30) } }
            LazyVGrid(columns: columns, spacing: 8) { ForEach(getDaysInWeek(), id: \.self) { date in WeeklyDayCell(date: date, isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate), isToday: Calendar.current.isDateInToday(date)).onTapGesture { selectedDate = date } } }
        }.padding().background(Color.themeSurface).cornerRadius(12)
    }
    private func getDaysInWeek() -> [Date] { let c = Calendar.current; guard let i = c.dateInterval(of: .weekOfYear, for: currentDate) else { return [] }; return (0..<7).compactMap { c.date(byAdding: .day, value: $0, to: i.start) } }
}

struct WeeklyDayCell: View {
    let date: Date; let isSelected: Bool; let isToday: Bool
    var body: some View { VStack(spacing: 4) { Text("\(Calendar.current.component(.day, from: date))").font(.system(size: 16, weight: .medium)).foregroundColor(isSelected ? .white : (isToday ? .themePrimary : .themeTextPrimary)).frame(height: 40).frame(maxWidth: .infinity).background(ZStack { if isSelected { Circle().fill(Color.themePrimary) } else if isToday { Circle().stroke(Color.themePrimary, lineWidth: 2) } }); Text(getDayAbbrev(date)).font(.system(size: 12, weight: .medium)).foregroundColor(isSelected ? .white.opacity(0.9) : .secondary) }.frame(height: 60) }
    private func getDayAbbrev(_ date: Date) -> String { let f = DateFormatter(); f.dateFormat = "E"; return f.string(from: date) }
}

struct EventRow: View {
    let event: CalendarEvent; @Environment(\.colorScheme) var colorScheme
    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) { Circle().fill(event.color).frame(width: 12, height: 12); Rectangle().fill(event.color).frame(width: 2).frame(maxHeight: .infinity) }
            VStack(alignment: .leading, spacing: 6) {
                HStack { Text(event.startTime, formatter: timeFormatter).font(.subheadline).fontWeight(.medium).foregroundColor(event.color); Spacer(); HStack(spacing: 4) { Text(eventTypeText).font(.caption2).fontWeight(.medium).padding(.horizontal, 6).padding(.vertical, 2).background(event.color.opacity(0.2)).foregroundColor(event.color).cornerRadius(4); if let fi = event.frequencyInfo { Text(fi).font(.caption2).fontWeight(.medium).padding(.horizontal, 6).padding(.vertical, 2).background(Color.themeSecondary.opacity(0.2)).foregroundColor(.themeSecondary).cornerRadius(4) } } }
                Text(event.title).font(.headline).foregroundColor(.themeTextPrimary)
                HStack { Image(systemName: event.icon).font(.caption).foregroundColor(.themeTextSecondary); Text(event.subtitle).font(.subheadline).foregroundColor(.themeTextSecondary); Spacer() }
            }
            Spacer(); Image(systemName: "chevron.right").font(.system(size: 14, weight: .medium)).foregroundColor(.secondary)
        }.padding().background(Color.themeSurface).cornerRadius(12)
    }
    private var eventTypeText: String { switch event { case .task: return "Task"; case .class(_, let isCourse, _): return isCourse ? "Course" : "Seminar" } }
    private let timeFormatter: DateFormatter = { let f = DateFormatter(); f.dateFormat = "h:mm a"; return f }()
}

private let monthYearFormatter: DateFormatter = { let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f }()

struct CalendarEmptyStateView: View {
    let icon: String; let title: String; let message: String; @Environment(\.colorScheme) var colorScheme
    var body: some View { VStack(spacing: 16) { Image(systemName: icon).font(.system(size: 48)).foregroundColor(.secondary); VStack(spacing: 8) { Text(title).font(.headline).foregroundColor(.themeTextPrimary); Text(message).font(.subheadline).foregroundColor(.themeTextSecondary).multilineTextAlignment(.center) } }.frame(maxWidth: .infinity).padding(.vertical, 40) }
}
