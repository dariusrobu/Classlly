import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @EnvironmentObject var themeManager: AppTheme
    
    @Query(sort: \Subject.title) var subjects: [Subject]
    @Query var tasks: [StudyTask]
    
    public init() {}

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    welcomeHeader
                    quickStatsSection
                    todaysClassesSection
                    upcomingTasksSection
                    academicPerformanceSection
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Sections
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome back!")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.themeTextPrimary)
            Text("Here's your academic overview for today")
                .font(.subheadline)
                .foregroundColor(.themeTextSecondary)
            
            if let currentWeek = calendarManager.currentTeachingWeek {
                HStack {
                    Image(systemName: "calendar")
                    Text("Academic Week \(currentWeek)")
                    Text("•")
                    Text(calendarManager.currentSemester.displayName)
                }
                .font(.caption)
                .foregroundColor(themeManager.selectedTheme.accentColor)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.themeSurface)
        .cornerRadius(12)
    }
    
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Stats")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.themeTextPrimary)
            
            HStack(spacing: 12) {
                DashboardCard(
                    title: "Today's Classes",
                    icon: "calendar",
                    count: getTodayClasses(academicWeek: calendarManager.currentTeachingWeek).count,
                    gradientColors: themeManager.selectedTheme.gamifiedGradient,
                    isGamifiedMode: themeManager.isGamifiedMode
                )
                
                DashboardCard(
                    title: "Pending Tasks",
                    icon: "checklist",
                    count: tasks.filter { !$0.isCompleted }.count,
                    gradientColors: [.orange, .red.opacity(0.8)],
                    isGamifiedMode: themeManager.isGamifiedMode
                )
                
                DashboardCard(
                    title: "Subjects",
                    icon: "book",
                    count: subjects.count,
                    gradientColors: [.green, .teal],
                    isGamifiedMode: themeManager.isGamifiedMode
                )
            }
        }
    }
    
    private var todaysClassesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Classes")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.themeTextPrimary)
                Spacer()
                NavigationLink("See All") { SubjectsView() }
                    .font(.subheadline)
                    .foregroundColor(themeManager.selectedTheme.accentColor)
            }
            
            let todaysClasses = getTodayClasses(academicWeek: calendarManager.currentTeachingWeek)
            
            if todaysClasses.isEmpty {
                HomeEmptyStateView(
                    icon: "calendar.badge.clock",
                    title: "No classes today",
                    message: "Enjoy your free time or catch up on studies"
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(todaysClasses.prefix(3)) { subject in
                        HomeClassCard(
                            subject: subject,
                            academicWeek: calendarManager.currentTeachingWeek,
                            isGamified: themeManager.isGamifiedMode,
                            gradientColors: themeManager.selectedTheme.gamifiedGradient
                        )
                    }
                }
            }
        }
    }
    
    private var upcomingTasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Upcoming Tasks")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.themeTextPrimary)
                Spacer()
                NavigationLink("See All") { TasksView() }
                    .font(.subheadline)
                    .foregroundColor(themeManager.selectedTheme.accentColor)
            }
            
            let upcomingTasks = tasks
                .filter { !$0.isCompleted }
                .sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
            
            if upcomingTasks.isEmpty {
                HomeEmptyStateView(
                    icon: "checkmark.circle",
                    title: "No pending tasks",
                    message: "You're all caught up!"
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(upcomingTasks.prefix(3)) { task in
                        HomeTaskCard(
                            task: task,
                            isGamified: themeManager.isGamifiedMode,
                            gradientColors: themeManager.selectedTheme.gamifiedGradient
                        )
                    }
                }
            }
        }
    }
    
    private var academicPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Academic Performance")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.themeTextPrimary)
                Spacer()
                NavigationLink("See All") { SubjectsView() }
                    .font(.subheadline)
                    .foregroundColor(themeManager.selectedTheme.accentColor)
            }
            
            if subjects.isEmpty {
                HomeEmptyStateView(
                    icon: "chart.bar.fill",
                    title: "No Subjects",
                    message: "Add your first subject to track academic performance"
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(subjects.prefix(4)) { subject in
                        SubjectPerformanceCard(
                            subject: subject,
                            isGamified: themeManager.isGamifiedMode,
                            gradientColors: themeManager.selectedTheme.gamifiedGradient
                        )
                    }
                }
            }
        }
    }
    
    func getTodayClasses(academicWeek: Int?) -> [Subject] {
        let today = Date()
        let weekday = Calendar.current.component(.weekday, from: today)
        return subjects.filter { subject in
            let hasCourseToday = subject.courseDays.contains(weekday) &&
                               subject.occursThisWeek(academicWeek: academicWeek, isCourse: true)
            let hasSeminarToday = subject.seminarDays.contains(weekday) &&
                                subject.occursThisWeek(academicWeek: academicWeek, isCourse: false)
            return hasCourseToday || hasSeminarToday
        }
    }
}

// MARK: - Helper Views

struct SubjectPerformanceCard: View {
    let subject: Subject
    let isGamified: Bool
    let gradientColors: [Color]
    @Environment(\.colorScheme) var colorScheme
    
    // FIX: Use optional coalescing for gradeHistory
    private var averageGrade: Double? {
        guard let history = subject.gradeHistory, !history.isEmpty else { return nil }
        let total = history.reduce(0.0) { $0 + $1.grade }
        return total / Double(history.count)
    }
    
    private var primaryColor: Color { gradientColors.first ?? .blue }
    
    private var gradeColor: Color {
        if isGamified { return .white }
        guard let grade = averageGrade else { return .gray }
        switch grade {
        case 8.5...10: return .themeSuccess
        case 7...8.4: return .themePrimary
        case 5.5...6.9: return .themeWarning
        default: return .themeError
        }
    }
    
    private var attendanceColor: Color {
        if isGamified { return .white }
        let rate = subject.attendanceRate
        switch rate {
        case 0.9...1.0: return .themeSuccess
        case 0.7..<0.9: return .themePrimary
        case 0.5..<0.7: return .themeWarning
        default: return .themeError
        }
    }
    
    var body: some View {
        NavigationLink(destination: SubjectDetailView(subject: subject)) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isGamified ? .white.opacity(0.2) : primaryColor.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: "book.fill")
                        .font(.system(size: 18))
                        .foregroundColor(isGamified ? .white : primaryColor)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(subject.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isGamified ? .white : .themeTextPrimary)
                        .lineLimit(1)
                    Text(subject.courseTeacher)
                        .font(.caption)
                        .foregroundColor(isGamified ? .white.opacity(0.8) : .themeTextSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(gradeColor)
                        
                        if let grade = averageGrade {
                            Text(String(format: "%.1f", grade))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(gradeColor)
                        } else {
                            Text("N/A")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(isGamified ? .white.opacity(0.7) : .gray)
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 12))
                            .foregroundColor(attendanceColor)
                        
                        Text("\(Int(subject.attendanceRate * 100))%")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(attendanceColor)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isGamified ? .white.opacity(0.5) : .secondary)
            }
            .padding()
            .background(backgroundView)
            .cornerRadius(isGamified ? 20 : 12)
            .shadow(
                color: isGamified ? primaryColor.opacity(0.3) : Color.black.opacity(0.05),
                radius: isGamified ? 8 : 2,
                x: 0,
                y: isGamified ? 4 : 1
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if isGamified {
            LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            Color.themeSurface
        }
    }
}

// Helper structs remain the same as before (HomeClassCard, HomeTaskCard, HomeEmptyStateView)
// I'm including them below to ensure the file is complete.

struct HomeClassCard: View {
    let subject: Subject
    let academicWeek: Int?
    let isGamified: Bool
    let gradientColors: [Color]
    @Environment(\.colorScheme) var colorScheme
    
    private var primaryColor: Color { gradientColors.first ?? .blue }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isGamified ? .white.opacity(0.2) : primaryColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "book.fill")
                    .foregroundColor(isGamified ? .white : primaryColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(subject.title)
                    .font(.headline)
                    .foregroundColor(isGamified ? .white : .themeTextPrimary)
                
                HStack {
                    if subject.occursThisWeek(academicWeek: academicWeek, isCourse: true) {
                        Text("Course")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(isGamified ? .white.opacity(0.2) : primaryColor.opacity(0.1))
                            .foregroundColor(isGamified ? .white : primaryColor)
                            .cornerRadius(4)
                    }
                    
                    if subject.occursThisWeek(academicWeek: academicWeek, isCourse: false) {
                        Text("Seminar")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(isGamified ? .white.opacity(0.2) : Color.themeSuccess.opacity(0.1))
                            .foregroundColor(isGamified ? .white : .themeSuccess)
                            .cornerRadius(4)
                    }
                }
                
                Text("\(subject.courseTimeString) • \(subject.courseClassroom)")
                    .font(.subheadline)
                    .foregroundColor(isGamified ? .white.opacity(0.8) : .themeTextSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isGamified ? .white.opacity(0.5) : .secondary)
        }
        .padding()
        .background(backgroundView)
        .cornerRadius(isGamified ? 20 : 12)
        .shadow(color: isGamified ? primaryColor.opacity(0.3) : Color.black.opacity(0.05), radius: isGamified ? 8 : 2, x: 0, y: isGamified ? 4 : 1)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if isGamified {
            LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            Color.themeSurface
        }
    }
}

struct HomeTaskCard: View {
    let task: StudyTask
    let isGamified: Bool
    let gradientColors: [Color]
    @Environment(\.colorScheme) var colorScheme
    
    private var primaryColor: Color { gradientColors.first ?? .blue }
    
    private var dueText: String {
        guard let dueDate = task.dueDate else { return "No due date" }
        let calendar = Calendar.current
        if calendar.isDateInToday(dueDate) { return "Due today" }
        else if calendar.isDateInTomorrow(dueDate) { return "Due tomorrow" }
        else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "Due \(formatter.string(from: dueDate))"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.priority.systemIcon)
                .foregroundColor(isGamified ? .white : task.priority.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(isGamified ? .white : .themeTextPrimary)
                
                if let subjectTitle = task.subject?.title {
                    Text(subjectTitle)
                        .font(.subheadline)
                        .foregroundColor(isGamified ? .white.opacity(0.8) : .themeTextSecondary)
                }
                
                Text(dueText)
                    .font(.caption)
                    .foregroundColor(isGamified ? .white.opacity(0.7) : .themeTextSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isGamified ? .white.opacity(0.5) : .secondary)
        }
        .padding()
        .background(backgroundView)
        .cornerRadius(isGamified ? 20 : 12)
        .shadow(color: isGamified ? primaryColor.opacity(0.3) : Color.black.opacity(0.05), radius: isGamified ? 8 : 2, x: 0, y: isGamified ? 4 : 1)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if isGamified {
            LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            Color.themeSurface
        }
    }
}

struct HomeEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text(title)
                .font(.headline)
                .foregroundColor(.themeTextPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.themeTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.themeSurface)
        .cornerRadius(12)
    }
}
