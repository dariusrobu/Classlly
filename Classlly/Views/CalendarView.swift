import SwiftUI
import Combine
import SwiftData

enum CalendarEvent: Identifiable {
    case task(StudyTask)
    case `class`(subject: Subject, isCourse: Bool, date: Date)
    var id: String {
        switch self {
        case .task(let task): return "task-\(task.id.uuidString)"
        case .class(let subject, let isCourse, let date): let type = isCourse ? "course" : "seminar"; return "class-\(subject.id.uuidString)-\(type)-\(date.timeIntervalSince1970)"
        }
    }
    var icon: String { switch self { case .task: return "checkmark.circle"; case .class(_, let isCourse, _): return isCourse ? "book.fill" : "person.2.fill" } }
    var startTime: Date { switch self { case .task(let task): return task.dueDate ?? Date(); case .class(let subject, let isCourse, _): return isCourse ? subject.courseStartTime : subject.seminarStartTime } }
    var endTime: Date { switch self { case .task: return startTime; case .class(let subject, let isCourse, _): return isCourse ? subject.courseEndTime : subject.seminarEndTime } }
    var title: String { switch self { case .task(let task): return task.title; case .class(let subject, let isCourse, _): let type = isCourse ? "Course" : "Seminar"; return "\(subject.title) (\(type))" } }
    var subtitle: String { switch self { case .task(let task): return task.subject?.title ?? "No Subject"; case .class(let subject, let isCourse, _): let teacher = isCourse ? subject.courseTeacher : subject.seminarTeacher; let room = isCourse ? subject.courseClassroom : subject.seminarClassroom; return "\(teacher) • \(room)" } }
    var color: Color { switch self { case .task: return .themeWarning; case .class(_, let isCourse, _): return isCourse ? .themePrimary : .themeSuccess } }
    var frequencyInfo: String? { switch self { case .task: return nil; case .class(let subject, let isCourse, _): return isCourse ? subject.courseFrequencyString : subject.seminarFrequencyString } }
}

struct CalendarView: View {
    @State private var currentDate = Date()
    @State private var selectedDate = Date()
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @EnvironmentObject var themeManager: AppTheme
    @Query var subjects: [Subject]; @Query var tasks: [StudyTask]
    @State private var selectedTask: StudyTask?; @State private var selectedSubject: Subject?; @State private var showingTaskDetail = false; @State private var showingSubjectDetail = false; @State private var showingAddTask = false
    
    public init() {}
    
    private var eventsForSelectedDate: [CalendarEvent] {
        let tasksOnDate = tasks.filter { task in guard let dueDate = task.dueDate else { return false }; return Calendar.current.isDate(dueDate, inSameDayAs: selectedDate) }
        var classEvents: [CalendarEvent] = []
        let weekday = Calendar.current.component(.weekday, from: selectedDate)
        let academicWeek = getAcademicWeek(for: selectedDate)
        for subject in subjects {
            let cDays = subject.courseDays ?? []; let sDays = subject.seminarDays ?? []
            if cDays.contains(weekday) && subject.occursThisWeek(academicWeek: academicWeek, isCourse: true) { classEvents.append(.class(subject: subject, isCourse: true, date: selectedDate)) }
            if sDays.contains(weekday) && subject.occursThisWeek(academicWeek: academicWeek, isCourse: false) { classEvents.append(.class(subject: subject, isCourse: false, date: selectedDate)) }
        }
        let taskEvents = tasksOnDate.map { CalendarEvent.task($0) }
        return (taskEvents + classEvents).sorted { $0.startTime < $1.startTime }
    }
    
    private func getAcademicWeek(for date: Date) -> Int? {
        let calendar = Calendar.current
        let today = Date()
        let daysDifference = calendar.dateComponents([.day], from: date, to: today).day ?? 0
        if let currentWeek = calendarManager.currentTeachingWeek {
            let weekDifference = daysDifference / 7; let estimatedWeek = currentWeek - weekDifference; return max(1, estimatedWeek)
        }
        return nil
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    if let currentWeek = calendarManager.currentTeachingWeek {
                        HStack {
                            Image(systemName: "clock.badge.checkmark").foregroundColor(currentWeek % 2 == 1 ? .themeWarning : .themePrimary)
                            Text("Week \(currentWeek) • \(currentWeek % 2 == 1 ? "ODD WEEK" : "EVEN WEEK")").font(.subheadline).fontWeight(.semibold).foregroundColor(currentWeek % 2 == 1 ? .themeWarning : .themePrimary)
                            Text("•").foregroundColor(.secondary)
                            Text(calendarManager.currentSemester.displayName).font(.subheadline).foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }.padding(.horizontal).padding(.top, 8)
                
                VStack(spacing: 12) {
                    HStack {
                        Button(action: previousWeek) { Image(systemName: "chevron.left").font(.system(size: 16, weight: .medium)).foregroundColor(.themePrimary).frame(width: 30, height: 30).background(Color.themePrimary.opacity(0.1)).clipShape(Circle()) }
                        Spacer()
                        VStack(spacing: 2) {
                            Text(weekRangeString).font(.title2).fontWeight(.semibold).foregroundColor(.themeTextPrimary).multilineTextAlignment(.center)
                            Text(currentDate, formatter: monthYearFormatter).font(.subheadline).foregroundColor(.themeTextSecondary)
                        }
                        Spacer()
                        Button(action: nextWeek) { Image(systemName: "chevron.right").font(.system(size: 16, weight: .medium)).foregroundColor(.themePrimary).frame(width: 30, height: 30).background(Color.themePrimary.opacity(0.1)).clipShape(Circle()) }
                    }.padding(.horizontal, 8)
                }.padding(.vertical, 16).padding(.horizontal)
                
                WeeklyCalendarGrid(currentDate: $currentDate, selectedDate: $selectedDate).padding(.horizontal).adaptiveCard()
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Events for \(formattedSelectedDate)").font(.headline).fontWeight(.semibold).foregroundColor(.themeTextPrimary)
                        Spacer()
                        Text("\(eventsForSelectedDate.count) events").font(.caption).foregroundColor(.themeTextSecondary)
                        Button(action: { showingAddTask = true }) { Image(systemName: "plus.circle.fill").font(.system(size: 20, weight: .medium)).foregroundColor(.themePrimary) }
                    }.padding(.horizontal)
                    if eventsForSelectedDate.isEmpty {
                        CalendarEmptyStateView(icon: "calendar", title: "No Events", message: "No classes or tasks scheduled.").padding(.horizontal)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(eventsForSelectedDate) { event in EventRow(event: event).onTapGesture { handleEventTap(event) }.adaptiveCard() }
                            }.padding(.horizontal)
                        }
                    }
                }.padding(.vertical)
                Spacer()
            }
            .navigationTitle("Calendar").navigationBarTitleDisplayMode(.inline).background(Color.clear)
            .sheet(isPresented: $showingTaskDetail) { if let task = selectedTask { EditTaskView(task: task) } }
            .sheet(isPresented: $showingSubjectDetail) { if let subject = selectedSubject { SubjectDetailView(subject: subject) } }
            .sheet(isPresented: $showingAddTask) { AddTaskView() }
        }
    }
    // ... (Private helpers handleEventTap, weekRangeString, formattedSelectedDate, previousWeek, nextWeek - same as previous)
    private func handleEventTap(_ event: CalendarEvent) { switch event { case .task(let task): selectedTask = task; showingTaskDetail = true; case .class(let subject, _, _): selectedSubject = subject; showingSubjectDetail = true } }
    private var weekRangeString: String { let calendar = Calendar.current; guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentDate) else { return "This Week" }; let startDate = weekInterval.start; let endDate = calendar.date(byAdding: .day, value: 6, to: startDate) ?? startDate; let f = DateFormatter(); f.dateFormat = "MMM d"; return "\(f.string(from: startDate)) - \(f.string(from: endDate))" }
    private var formattedSelectedDate: String { let f = DateFormatter(); f.dateStyle = .long; f.timeStyle = .none; return f.string(from: selectedDate) }
    private func previousWeek() { if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentDate) { currentDate = newDate } }
    private func nextWeek() { if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDate) { currentDate = newDate } }
}

// ... (WeeklyCalendarGrid, WeeklyDayCell, EventRow, CalendarEmptyStateView - same as previous)
struct WeeklyCalendarGrid: View {
    @Binding var currentDate: Date; @Binding var selectedDate: Date; @Environment(\.colorScheme) var colorScheme
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]; private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private var daysInWeek: [Date] { getDaysInWeek() }
    var body: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: columns, spacing: 10) { ForEach(daysOfWeek, id: \.self) { day in Text(day).font(.caption).fontWeight(.medium).foregroundColor(.secondary).frame(height: 30) } }
            LazyVGrid(columns: columns, spacing: 8) { ForEach(daysInWeek, id: \.self) { date in WeeklyDayCell(date: date, isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate), isToday: Calendar.current.isDateInToday(date)).onTapGesture { selectedDate = date } } }
        }.padding()
    }
    private func getDaysInWeek() -> [Date] { let calendar = Calendar.current; guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentDate) else { return [] }; var days: [Date] = []; for dayOffset in 0..<7 { if let date = calendar.date(byAdding: .day, value: dayOffset, to: weekInterval.start) { days.append(date) } }; return days }
}

struct WeeklyDayCell: View {
    let date: Date; let isSelected: Bool; let isToday: Bool; @EnvironmentObject var themeManager: AppTheme
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))").font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? .white : (isToday ? (themeManager.isGamified ? GameColor.accent : .themePrimary) : .themeTextPrimary))
                .frame(height: 40).frame(maxWidth: .infinity)
                .background(ZStack { if isSelected { Circle().fill(themeManager.isGamified ? GameColor.accent : Color.themePrimary) } else if isToday { Circle().stroke(themeManager.isGamified ? GameColor.accent : Color.themePrimary, lineWidth: 2) } })
            Text(getAbbr(date)).font(.system(size: 12, weight: .medium)).foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
        }.frame(height: 60)
    }
    func getAbbr(_ date: Date) -> String { let f = DateFormatter(); f.dateFormat = "E"; return f.string(from: date) }
}

struct EventRow: View {
    let event: CalendarEvent; @Environment(\.colorScheme) var colorScheme
    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) { Circle().fill(event.color).frame(width: 12, height: 12); Rectangle().fill(event.color).frame(width: 2).frame(maxHeight: .infinity) }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(getTime(event.startTime)).font(.subheadline).fontWeight(.medium).foregroundColor(event.color)
                    Spacer()
                    Text(getType(event)).font(.caption2).fontWeight(.medium).padding(.horizontal, 6).padding(.vertical, 2).background(event.color.opacity(0.2)).foregroundColor(event.color).cornerRadius(4)
                }
                Text(event.title).font(.headline).foregroundColor(.themeTextPrimary)
                HStack { Image(systemName: event.icon).font(.caption).foregroundColor(.themeTextSecondary); Text(event.subtitle).font(.subheadline).foregroundColor(.themeTextSecondary); Spacer() }
            }
            Spacer(); Image(systemName: "chevron.right").font(.system(size: 14, weight: .medium)).foregroundColor(.secondary)
        }.padding()
    }
    func getTime(_ date: Date) -> String { let f = DateFormatter(); f.dateFormat = "h:mm a"; return f.string(from: date) }
    func getType(_ event: CalendarEvent) -> String { switch event { case .task: return "Task"; case .class(_, let isCourse, _): return isCourse ? "Course" : "Seminar" } }
}

struct CalendarEmptyStateView: View {
    let icon: String; let title: String; let message: String
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon).font(.system(size: 48)).foregroundColor(.secondary)
            VStack(spacing: 8) { Text(title).font(.headline).foregroundColor(.themeTextPrimary); Text(message).font(.subheadline).foregroundColor(.themeTextSecondary).multilineTextAlignment(.center) }
        }.frame(maxWidth: .infinity).padding(.vertical, 40).adaptiveCard()
    }
}
private let monthYearFormatter: DateFormatter = { let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f }()
