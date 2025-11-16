import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    
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
            // --- THIS IS THE FIX ---
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // ... (welcomeHeader, quickStatsSection, StatCard, etc.) ...
    
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
                .foregroundColor(.themePrimary)
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
                StatCard(
                    title: "Today's Classes",
                    value: "\(getTodayClasses(academicWeek: calendarManager.currentTeachingWeek).count)",
                    icon: "calendar",
                    color: .themePrimary
                )
                StatCard(
                    title: "Pending Tasks",
                    value: "\(tasks.filter { !$0.isCompleted }.count)",
                    icon: "checklist",
                    color: .themeWarning
                )
                StatCard(
                    title: "Subjects",
                    value: "\(subjects.count)",
                    icon: "book",
                    color: .themeSuccess
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
                    .foregroundColor(.themePrimary)
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
                        HomeClassCard(subject: subject, academicWeek: calendarManager.currentTeachingWeek)
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
                    .foregroundColor(.themePrimary)
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
                        HomeTaskCard(task: task)
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
                    .foregroundColor(.themePrimary)
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
                        SubjectPerformanceCard(subject: subject)
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

// --- All helper structs (StatCard, HomeClassCard, etc.) ---
struct SubjectPerformanceCard: View {
    let subject: Subject
    @Environment(\.colorScheme) var colorScheme
    
    // --- THIS IS THE FIX ---
    private var averageGrade: Double? {
        // 1. Safely unwrap `subject.gradeHistory`
        guard let gradeHistory = subject.gradeHistory, !gradeHistory.isEmpty else { return nil }
        
        // 2. Use the unwrapped `gradeHistory`
        let total = gradeHistory.reduce(0.0) { $0 + $1.grade }
        return total / Double(gradeHistory.count)
    }
    // --- END OF FIX ---
    
    private var gradeColor: Color {
        // (This logic is now safe because `averageGrade` handles the unwrapping)
        guard let grade = averageGrade else { return .gray }
        switch grade {
        case 8.5...10: return .themeSuccess
        case 7...8.4: return .themePrimary
        case 5.5...6.9: return .themeWarning
        default: return .themeError
        }
    }
    
    private var attendanceColor: Color {
        // (This was already safe because `subject.attendanceRate` was fixed in DataModels.swift)
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
                        .fill(Color.themePrimary.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: "book.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.themePrimary)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(subject.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.themeTextPrimary)
                        .lineLimit(1)
                    Text(subject.courseTeacher)
                        .font(.caption)
                        .foregroundColor(.themeTextSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(gradeColor)
                        
                        // (This is now safe)
                        if let grade = averageGrade {
                            Text(String(format: "%.1f", grade))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(gradeColor)
                        } else {
                            Text("N/A")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 12))
                            .foregroundColor(attendanceColor)
                        
                        // (This is now safe)
                        Text("\(Int(subject.attendanceRate * 100))%")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(attendanceColor)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.themeSurface)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// ... (Rest of HomeView.swift and its helper structs are unchanged) ...
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.themeTextPrimary)
            Text(title)
                .font(.caption)
                .foregroundColor(.themeTextSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.themeSurface)
        .cornerRadius(12)
    }
}

struct HomeClassCard: View {
    let subject: Subject
    let academicWeek: Int?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.themePrimary.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "book.fill")
                    .foregroundColor(.themePrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(subject.title)
                    .font(.headline)
                    .foregroundColor(.themeTextPrimary)
                
                HStack {
                    if subject.occursThisWeek(academicWeek: academicWeek, isCourse: true) {
                        Text("Course")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.themePrimary.opacity(0.1))
                            .foregroundColor(.themePrimary)
                            .cornerRadius(4)
                    }
                    
                    if subject.occursThisWeek(academicWeek: academicWeek, isCourse: false) {
                        Text("Seminar")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.themeSuccess.opacity(0.1))
                            .foregroundColor(.themeSuccess)
                            .cornerRadius(4)
                    }
                }
                
                Text("\(subject.courseTimeString) • \(subject.courseClassroom)")
                    .font(.subheadline)
                    .foregroundColor(.themeTextSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.themeSurface)
        .cornerRadius(12)
    }
}

struct HomeTaskCard: View {
    let task: StudyTask
    @Environment(\.colorScheme) var colorScheme
    
    private var dueText: String {
        guard let dueDate = task.dueDate else { return "No due date" }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(dueDate) {
            return "Due today"
        } else if calendar.isDateInTomorrow(dueDate) {
            return "Due tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "Due \(formatter.string(from: dueDate))"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.priority.systemIcon)
                .foregroundColor(task.priority.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(.themeTextPrimary)
                
                if let subjectTitle = task.subject?.title {
                    Text(subjectTitle)
                        .font(.subheadline)
                        .foregroundColor(.themeTextSecondary)
                }
                
                Text(dueText)
                    .font(.caption)
                    .foregroundColor(.themeTextSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.themeSurface)
        .cornerRadius(12)
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
