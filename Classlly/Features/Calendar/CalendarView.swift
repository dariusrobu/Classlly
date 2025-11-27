import SwiftUI
import Combine
import SwiftData

// MARK: - Calendar Event Wrapper
enum CalendarEvent: Identifiable {
    case task(StudyTask)
    case `class`(subject: Subject, isCourse: Bool, date: Date)
    
    var id: String {
        switch self {
        case .task(let task):
            return "task-\(task.id)"
        case .class(let subject, let isCourse, let date):
            let type = isCourse ? "course" : "seminar"
            return "class-\(subject.id)-\(type)-\(date.timeIntervalSince1970)"
        }
    }
    
    var icon: String {
        switch self {
        case .task:
            return "checkmark.circle.fill"
        case .class(_, let isCourse, _):
            return isCourse ? "book.fill" : "person.2.fill"
        }
    }
    
    var startTime: Date {
        switch self {
        case .task(let task):
            return task.dueDate ?? Date()
        case .class(let subject, let isCourse, _):
            return isCourse ? subject.courseStartTime : subject.seminarStartTime
        }
    }
    
    var endTime: Date {
        switch self {
        case .task:
            return startTime
        case .class(let subject, let isCourse, _):
            return isCourse ? subject.courseEndTime : subject.seminarEndTime
        }
    }
    
    var title: String {
        switch self {
        case .task(let task):
            return task.title
        case .class(let subject, let isCourse, _):
            let type = isCourse ? "Course" : "Seminar"
            return "\(subject.title) (\(type))"
        }
    }
    
    var subtitle: String {
        switch self {
        case .task(let task):
            return task.subject?.title ?? "No Subject"
        case .class(let subject, let isCourse, _):
            let teacher = isCourse ? subject.courseTeacher : subject.seminarTeacher
            let room = isCourse ? subject.courseClassroom : subject.seminarClassroom
            return "\(teacher) • \(room)"
        }
    }
    
    var color: Color {
        switch self {
        case .task:
            return .themeWarning
        case .class(_, let isCourse, _):
            return isCourse ? .themePrimary : .themeSuccess
        }
    }
    
    var frequencyInfo: String? {
        switch self {
        case .task:
            return nil
        case .class(let subject, let isCourse, _):
            return isCourse ? subject.courseFrequencyString : subject.seminarFrequencyString
        }
    }
}

// MARK: - Main Calendar View
struct CalendarView: View {
    @State private var currentDate = Date()
    @State private var selectedDate = Date()
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @EnvironmentObject var themeManager: AppTheme
    @AppStorage("isGamifiedMode") private var isGamifiedMode = false
    
    @Environment(\.horizontalSizeClass) var sizeClass
    
    @Query var subjects: [Subject]
    @Query var tasks: [StudyTask]
    
    @State private var selectedTask: StudyTask?
    @State private var selectedSubject: Subject?
    @State private var showingTaskDetail = false
    @State private var showingSubjectDetail = false
    @State private var showingAddTask = false
    
    public init() {}
    
     private var eventsForSelectedDate: [CalendarEvent] {
        let tasksOnDate = tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return Calendar.current.isDate(dueDate, inSameDayAs: selectedDate)
        }
        
        var classEvents: [CalendarEvent] = []
        let weekday = Calendar.current.component(.weekday, from: selectedDate)
        let academicWeek = getAcademicWeek(for: selectedDate)
        
        for subject in subjects {
            // Check Course Days
            if subject.courseDays.contains(weekday) &&
               subject.occursThisWeek(academicWeek: academicWeek, isCourse: true) {
                classEvents.append(.class(subject: subject, isCourse: true, date: selectedDate))
            }
            
            // Check Seminar Days
            if subject.seminarDays.contains(weekday) &&
               subject.occursThisWeek(academicWeek: academicWeek, isCourse: false) {
                classEvents.append(.class(subject: subject, isCourse: false, date: selectedDate))
            }
        }
        
        let taskEvents = tasksOnDate.map { CalendarEvent.task($0) }
        
        return (taskEvents + classEvents).sorted { $0.startTime < $1.startTime }
    }
    
    private func getAcademicWeek(for date: Date) -> Int? {
        let calendar = Calendar.current
        let today = Date()
        let daysDifference = calendar.dateComponents([.day], from: date, to: today).day ?? 0
        
        if let currentWeek = calendarManager.currentTeachingWeek {
            let weekDifference = daysDifference / 7
            let estimatedWeek = currentWeek - weekDifference
            return max(1, estimatedWeek)
        }
        
        return nil
    }

    var body: some View {
        // Navigation is handled by ContentView, so no NavigationView here
        Group {
            if sizeClass == .regular {
                // iPad Layout (Side-by-Side)
                HStack(alignment: .top, spacing: 24) {
                    VStack(spacing: 20) {
                        calendarContent
                    }
                    .frame(maxWidth: 400)
                    
                    ScrollView {
                        eventsContent
                            .padding(.top)
                    }
                }
                .padding()
            } else {
                // iPhone Layout (Vertical Stack)
                ScrollView {
                    VStack(spacing: 0) {
                        calendarContent
                        eventsContent
                    }
                }
            }
        }
        .background(Color.themeBackground)
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingTaskDetail) {
            if let task = selectedTask {
                EditTaskView(task: task)
            }
        }
        .sheet(isPresented: $showingSubjectDetail) {
            if let subject = selectedSubject {
                SubjectDetailView(subject: subject)
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
        }
    }
    
    // MARK: - Subviews
    
    private var calendarContent: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                if let currentWeek = calendarManager.currentTeachingWeek {
                    HStack {
                        Image(systemName: "clock.badge.checkmark")
                            .foregroundColor(isGamifiedMode ? themeManager.selectedTheme.accentColor : .themePrimary)
                        Text("Week \(currentWeek)")
                            .fontWeight(.semibold)
                            .foregroundColor(isGamifiedMode ? themeManager.selectedTheme.accentColor : .themePrimary)
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
            
            VStack(spacing: 12) {
                HStack {
                    Button(action: previousWeek) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isGamifiedMode ? themeManager.selectedTheme.accentColor : .themePrimary)
                            .frame(width: 30, height: 30)
                            .background(Color.themeSurface)
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
                            .foregroundColor(isGamifiedMode ? themeManager.selectedTheme.accentColor : .themePrimary)
                            .frame(width: 30, height: 30)
                            .background(Color.themeSurface)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 16)
            .padding(.horizontal)
            
            WeeklyCalendarGrid(
                currentDate: $currentDate,
                selectedDate: $selectedDate,
                themeColor: themeManager.selectedTheme.accentColor,
                isGamified: isGamifiedMode
            )
            .padding(.horizontal)
        }
    }
    
    private var eventsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Events for \(formattedSelectedDate)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.themeTextPrimary)
                
                Spacer()
                
                Text("\(eventsForSelectedDate.count) events")
                    .font(.caption)
                    .foregroundColor(.themeTextSecondary)
                
                Button(action: { showingAddTask = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isGamifiedMode ? themeManager.selectedTheme.accentColor : .themePrimary)
                }
            }
            .padding(.horizontal)
            
            if eventsForSelectedDate.isEmpty {
                CalendarEmptyStateView(
                    icon: "calendar",
                    title: "No Events",
                    message: "No classes or tasks scheduled."
                )
                .padding(.horizontal)
            } else {
                LazyVStack(spacing: isGamifiedMode ? 12 : 12) {
                    ForEach(eventsForSelectedDate) { event in
                        if isGamifiedMode {
                            GamifiedEventCard(
                                event: event,
                                themeColor: themeManager.selectedTheme.accentColor
                            )
                            .onTapGesture {
                                handleEventTap(event)
                            }
                        } else {
                            EventRow(event: event)
                                .onTapGesture {
                                    handleEventTap(event)
                                }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .padding(.vertical)
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
    
    private var weekRangeString: String {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentDate) else {
            return "This Week"
        }
        
        let startDate = weekInterval.start
        let endDate = calendar.date(byAdding: .day, value: 6, to: startDate) ?? startDate
        
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return "\(f.string(from: startDate)) - \(f.string(from: endDate))"
    }
    
    private var formattedSelectedDate: String {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f.string(from: selectedDate)
    }
}

// MARK: - Helper Views

struct WeeklyCalendarGrid: View {
    @Binding var currentDate: Date
    @Binding var selectedDate: Date
    let themeColor: Color
    let isGamified: Bool
    
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(height: 30)
                }
            }
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(getDaysInWeek(), id: \.self) { date in
                    WeeklyDayCell(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        isToday: Calendar.current.isDateInToday(date),
                        themeColor: themeColor,
                        isGamified: isGamified
                    )
                    .onTapGesture {
                        selectedDate = date
                    }
                }
            }
        }
        .padding()
        .background(Color.themeSurface)
        .cornerRadius(12)
    }
    
    private func getDaysInWeek() -> [Date] {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentDate) else {
            return []
        }
        
        var days: [Date] = []
        for dayOffset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: weekInterval.start) {
                days.append(date)
            }
        }
        return days
    }
}

struct WeeklyDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let themeColor: Color
    let isGamified: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? .white : (isToday ? themeColor : .primary))
                .frame(height: 40)
                .frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        if isSelected {
                            if isGamified {
                                LinearGradient(
                                    gradient: Gradient(colors: [themeColor, themeColor.opacity(0.7)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .clipShape(Circle())
                            } else {
                                Circle().fill(themeColor)
                            }
                        } else if isToday {
                            Circle().stroke(themeColor, lineWidth: 2)
                        }
                    }
                )
            
            Text(getDateStr())
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
        }
        .frame(height: 60)
    }
    
    func getDateStr() -> String {
        let f = DateFormatter()
        f.dateFormat = "E"
        return f.string(from: date)
    }
}

struct EventRow: View {
    let event: CalendarEvent
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Circle()
                    .fill(event.color)
                    .frame(width: 12, height: 12)
                Rectangle()
                    .fill(event.color)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(event.startTime, formatter: timeFormatter)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(event.color)
                    Spacer()
                }
                
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    Image(systemName: event.icon)
                        .font(.caption)
                    Text(event.subtitle)
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.themeSurface)
        .cornerRadius(12)
    }
}

struct GamifiedEventCard: View {
    let event: CalendarEvent
    let themeColor: Color
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 40, height: 40)
                Image(systemName: event.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(themeColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(event.startTime, formatter: timeFormatter)
                    Text("•")
                    Text(event.subtitle)
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [themeColor, themeColor.opacity(0.7)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(20)
        .shadow(color: themeColor.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

struct CalendarEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

private let timeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "h:mm a"
    return f
}()

private let monthYearFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "MMMM yyyy"
    return f
}()
