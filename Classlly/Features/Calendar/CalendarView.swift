import SwiftUI
import Combine
import SwiftData

// MARK: - Calendar Event Model
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
        case .task:
            return "checkmark.circle"
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
    
    @AppStorage("isGamified") private var isGamified = false
    
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
            if subject.courseDays.contains(weekday) &&
               subject.occursThisWeek(academicWeek: academicWeek, isCourse: true) {
                classEvents.append(.class(subject: subject, isCourse: true, date: selectedDate))
            }
            
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
    
    private var weekRangeString: String {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentDate) else {
            return "This Week"
        }
        
        let startDate = weekInterval.start
        let endDate = calendar.date(byAdding: .day, value: 6, to: startDate) ?? startDate
        
        let startFormatter = DateFormatter()
        startFormatter.dateFormat = "MMM d"
        
        let endFormatter = DateFormatter()
        endFormatter.dateFormat = "MMM d"
        
        return "\(startFormatter.string(from: startDate)) - \(endFormatter.string(from: endDate))"
    }
    
    private var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: selectedDate)
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
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Info
                VStack(spacing: 8) {
                    if let currentWeek = calendarManager.currentTeachingWeek {
                        HStack {
                            Image(systemName: isGamified ? "flag.checkered.2.crossed" : "clock")
                                .foregroundColor(isGamified ? .themeWarning : .secondary)
                            
                            Text(isGamified ? "Round \(currentWeek)" : "Week \(currentWeek)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(isGamified ? .themeTextPrimary : .secondary)
                            
                            Text("•").foregroundColor(.secondary)
                            
                            Text(calendarManager.currentSemester.displayName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Week Navigation
                VStack(spacing: 12) {
                    HStack {
                        Button(action: previousWeek) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                                .frame(width: 30, height: 30)
                                .background(Color.themeSurface)
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 2) {
                            Text(weekRangeString)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(currentDate, formatter: monthYearFormatter)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                        }
                        
                        Spacer()
                        
                        Button(action: nextWeek) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                                .frame(width: 30, height: 30)
                                .background(Color.themeSurface)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .padding(.vertical, 16)
                .padding(.horizontal)
                
                // Calendar Grid
                WeeklyCalendarGrid(
                    currentDate: $currentDate,
                    selectedDate: $selectedDate,
                    isGamified: isGamified
                )
                .padding(.horizontal)
                
                // Events List
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(isGamified ? "Daily Quests" : "Schedule")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.themeTextPrimary)
                        
                        Spacer()
                        
                        if !eventsForSelectedDate.isEmpty {
                            Text("\(eventsForSelectedDate.count) events")
                                .font(.caption)
                                .foregroundColor(.themeTextSecondary)
                        }
                        
                        Button(action: { showingAddTask = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(isGamified ? .themePrimary : .primary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    if eventsForSelectedDate.isEmpty {
                        CalendarEmptyStateView(
                            icon: "calendar",
                            title: "No Events",
                            message: "No classes or tasks scheduled.",
                            isGamified: isGamified
                        )
                        .padding(.horizontal)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(eventsForSelectedDate) { event in
                                    EventRow(event: event, isGamified: isGamified)
                                        .onTapGesture {
                                            handleEventTap(event)
                                        }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                }
                
                Spacer()
            }
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
    }
}

// MARK: - Subviews

struct WeeklyCalendarGrid: View {
    @Binding var currentDate: Date
    @Binding var selectedDate: Date
    @Environment(\.colorScheme) var colorScheme
    var isGamified: Bool
    
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    private var daysInWeek: [Date] {
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
    
    var body: some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }
            }
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(daysInWeek, id: \.self) { date in
                    WeeklyDayCell(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        isToday: Calendar.current.isDateInToday(date),
                        isGamified: isGamified
                    )
                    .onTapGesture {
                        selectedDate = date
                    }
                }
            }
        }
        .padding()
        // Gamified: Card background | Minimalist: Clean/Transparent
        .background(isGamified ? Color.themeSurface : Color.clear)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isGamified ? Color.themePrimary.opacity(0.1) : Color.clear, lineWidth: 1)
        )
    }
}

struct WeeklyDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isGamified: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(
                    isSelected ? .white :
                    (isToday ? (isGamified ? .themePrimary : .primary) : .primary)
                )
                .frame(width: 36, height: 36)
                .background(
                    ZStack {
                        if isSelected {
                            if isGamified {
                                Circle().fill(LinearGradient(colors: [.themePrimary, .themeSecondary], startPoint: .top, endPoint: .bottom))
                            } else {
                                Circle().fill(Color.primary) // Minimalist: Black/White
                            }
                        } else if isToday {
                            if isGamified {
                                Circle().stroke(Color.themePrimary, lineWidth: 2)
                            } else {
                                // Minimalist Today: Small dot indicator
                                VStack {
                                    Spacer()
                                    Circle().fill(Color.primary).frame(width: 4, height: 4)
                                }
                            }
                        }
                    }
                )
        }
        .frame(height: 40)
    }
}

struct EventRow: View {
    let event: CalendarEvent
    @Environment(\.colorScheme) var colorScheme
    var isGamified: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            if isGamified {
                // Gamified: Colored Icon with background
                ZStack {
                    Circle()
                        .fill(event.color.opacity(0.15))
                        .frame(width: 42, height: 42)
                    Image(systemName: event.icon)
                        .font(.system(size: 18))
                        .foregroundColor(event.color)
                }
            } else {
                // Minimalist: Clean Vertical Strip
                RoundedRectangle(cornerRadius: 2)
                    .fill(event.color) // Functional color
                    .frame(width: 4, height: 42)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(.themeTextPrimary)
                
                Text(event.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(timeString(event.startTime))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(isGamified ? event.color : .primary)
                
                if isGamified {
                    // XP Badge
                    Text("+XP")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.themeSuccess.opacity(0.1))
                        .foregroundColor(.themeSuccess)
                        .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(Color.themeSurface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(isGamified ? 0 : 0.03), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isGamified ? event.color.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}

struct CalendarEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    @Environment(\.colorScheme) var colorScheme
    var isGamified: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.themeTextPrimary)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.themeTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(isGamified ? Color.themeSurface : Color.clear)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isGamified ? Color.themePrimary.opacity(0.1) : Color.clear, lineWidth: 1)
        )
    }
}

private let monthYearFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM yyyy"
    return formatter
}()
