import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    
    @AppStorage("isGamified") private var isGamified = false
    
    @Query(sort: \Subject.title) var subjects: [Subject]
    @Query var tasks: [StudyTask]
    
    public init() {}

    var body: some View {
        NavigationStack {
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
            .navigationDestination(for: Subject.self) { subject in
                SubjectDetailView(subject: subject)
            }
        }
    }
    
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isGamified ? "Player Ready!" : "Welcome back")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.themeTextPrimary)
                    Text(isGamified ? "Current Session Stats" : "Academic Overview")
                        .font(.subheadline)
                        .foregroundColor(.themeTextSecondary)
                }
                Spacer()
                if isGamified {
                    // Total Level Badge for Header
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.themePrimary, .themeSecondary], startPoint: .top, endPoint: .bottom))
                            .frame(width: 50, height: 50)
                            .shadow(color: .themePrimary.opacity(0.5), radius: 5)
                        VStack(spacing: 0) {
                            Text("LVL")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white.opacity(0.9))
                            Text("\(calculateTotalLevel())")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            
            if let currentWeek = calendarManager.currentTeachingWeek {
                HStack {
                    Image(systemName: isGamified ? "flag.checkered.2.crossed" : "calendar")
                    Text("Week \(currentWeek)")
                    if isGamified {
                        Text("•")
                        Text("Season \(calendarManager.currentSemester == .semester1 ? "1" : "2")")
                    } else {
                        Text("•")
                        Text(calendarManager.currentSemester.displayName)
                    }
                }
                .font(.caption)
                .foregroundColor(!isGamified ? .secondary : .themeAccent)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(isGamified ? Color.themeSurface : Color.clear)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isGamified ? Color.themePrimary.opacity(0.3) : Color.adaptiveBorder, lineWidth: 1)
        )
    }
    
    private func calculateTotalLevel() -> Int {
        let totalXP = subjects.reduce(0) { $0 + ($1.attendedClasses * 50) + Int(($1.currentGrade ?? 0) * 100) }
        return (totalXP / 1000) + 1
    }
    
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Stats")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.themeTextPrimary)
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Classes",
                    value: "\(getTodayClasses(academicWeek: calendarManager.currentTeachingWeek).count)",
                    icon: "calendar",
                    color: .themePrimary,
                    isGamified: isGamified,
                    xpValue: "+50 XP"
                )
                StatCard(
                    title: "Tasks",
                    value: "\(tasks.filter { !$0.isCompleted }.count)",
                    icon: "checklist",
                    color: .themeWarning,
                    isGamified: isGamified,
                    xpValue: "Reward"
                )
                StatCard(
                    title: "Subjects",
                    value: "\(subjects.count)",
                    icon: "book",
                    color: .themeSuccess,
                    isGamified: isGamified,
                    xpValue: "Active"
                )
            }
        }
    }
    
    private var todaysClassesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(isGamified ? "Daily Quests" : "Today's Classes")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.themeTextPrimary)
                Spacer()
                NavigationLink("See All") { SubjectsView() }
                    .font(.subheadline)
                    .foregroundColor(!isGamified ? .primary : .themePrimary)
            }
            
            let todaysClasses = getTodayClasses(academicWeek: calendarManager.currentTeachingWeek)
            
            if todaysClasses.isEmpty {
                // FIXED: Explicit argument labels matching the struct definition
                HomeEmptyStateView(
                    icon: "calendar.badge.clock",
                    title: "No quests active",
                    message: "Enjoy your downtime",
                    isGamified: isGamified
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(todaysClasses.prefix(3)) { subject in
                        HomeClassCard(
                            subject: subject,
                            academicWeek: calendarManager.currentTeachingWeek,
                            isGamified: isGamified
                        )
                    }
                }
            }
        }
    }
    
    private var upcomingTasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(isGamified ? "Side Missions" : "Upcoming Tasks")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.themeTextPrimary)
                Spacer()
                NavigationLink("See All") { TasksView() }
                    .font(.subheadline)
                    .foregroundColor(!isGamified ? .primary : .themePrimary)
            }
            
            let upcomingTasks = tasks
                .filter { !$0.isCompleted }
                .sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
            
            if upcomingTasks.isEmpty {
                HomeEmptyStateView(
                    icon: "checkmark.circle",
                    title: "Mission Complete",
                    message: "All tasks finished!",
                    isGamified: isGamified
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(upcomingTasks.prefix(3)) { task in
                        HomeTaskCard(task: task, isGamified: isGamified)
                    }
                }
            }
        }
    }
    
    private var academicPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(isGamified ? "Player Stats" : "Academic Performance")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.themeTextPrimary)
                Spacer()
                NavigationLink("See All") { SubjectsView() }
                    .font(.subheadline)
                    .foregroundColor(!isGamified ? .primary : .themePrimary)
            }
            
            if subjects.isEmpty {
                HomeEmptyStateView(
                    icon: "chart.bar.fill",
                    title: "No Stats",
                    message: "Start classes to gain XP",
                    isGamified: isGamified
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(subjects.prefix(4)) { subject in
                        if isGamified {
                            GamifiedHomeSubjectCard(subject: subject)
                        } else {
                            SubjectPerformanceCard(subject: subject, isMinimalist: true)
                        }
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

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let isGamified: Bool
    let xpValue: String
    
    var body: some View {
        VStack(spacing: 8) {
            if isGamified {
                // Gamified HUD Style
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Spacer()
                    Text(xpValue)
                        .font(.system(size: 8, weight: .bold))
                        .padding(4)
                        .background(color.opacity(0.2))
                        .foregroundColor(color)
                        .cornerRadius(4)
                }
                
                Text(value)
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.themeTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.themeTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
            } else {
                // Minimalist Style
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
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(isGamified ? Color.themeSurface : Color.clear)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isGamified ? color.opacity(0.3) : Color.adaptiveBorder, lineWidth: 1)
        )
        .shadow(color: isGamified ? color.opacity(0.1) : .clear, radius: 4, x: 0, y: 2)
    }
}

struct HomeClassCard: View {
    let subject: Subject
    let academicWeek: Int?
    let isGamified: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            if isGamified {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: [.themePrimary, .themeSecondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)
                    Image(systemName: "book.fill")
                        .foregroundColor(.white)
                }
            } else {
                Image(systemName: "book.fill")
                    .foregroundColor(.themePrimary)
                    .font(.title3)
                    .frame(width: 24)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(subject.title)
                    .font(.headline)
                    .foregroundColor(.themeTextPrimary)
                
                Text("\(subject.courseTimeString) • \(subject.courseClassroom)")
                    .font(.subheadline)
                    .foregroundColor(.themeTextSecondary)
            }
            
            Spacer()
            
            if isGamified {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.caption2)
                    Text("+50 XP")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.themeWarning.opacity(0.2))
                .foregroundColor(.themeWarning)
                .clipShape(Capsule())
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(isGamified ? Color.themeSurface : Color.clear)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isGamified ? Color.themePrimary.opacity(0.2) : Color.adaptiveBorder, lineWidth: 1)
        )
    }
}

struct HomeTaskCard: View {
    let task: StudyTask
    let isGamified: Bool
    
    private var xpReward: Int {
        switch task.priority {
        case .high: return 50
        case .medium: return 30
        case .low: return 10
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if isGamified {
                Circle()
                    .stroke(task.priority.color, lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle().fill(task.priority.color.opacity(0.2))
                    )
            } else {
                Image(systemName: "circle")
                    .font(.title3)
                    .foregroundColor(task.priority.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(.themeTextPrimary)
                if isGamified {
                    Text(task.priority.rawValue)
                        .font(.caption2)
                        .foregroundColor(task.priority.color)
                } else {
                    if let date = task.dueDate {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if isGamified {
                Text("+\(xpReward) XP")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.themeSuccess)
            }
        }
        .padding()
        .background(isGamified ? Color.themeSurface : Color.clear)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isGamified ? task.priority.color.opacity(0.3) : Color.adaptiveBorder, lineWidth: 1)
        )
    }
}

struct GamifiedHomeSubjectCard: View {
    let subject: Subject
    
    var level: Int {
        let xp = (subject.attendedClasses * 50) + Int((subject.currentGrade ?? 0) * 100)
        return (xp / 500) + 1
    }
    
    var body: some View {
        NavigationLink(value: subject) {
            HStack(spacing: 12) {
                ZStack {
                    Image(systemName: "hexagon.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.themeSecondary)
                        .shadow(color: .themeSecondary.opacity(0.5), radius: 4)
                    
                    VStack(spacing: 0) {
                        Text("LVL")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                        Text("\(level)")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(subject.title)
                        .font(.headline)
                        .bold()
                        .foregroundColor(.themeTextPrimary)
                    
                    // Progress Bar
                    HStack(spacing: 4) {
                        Capsule()
                            .fill(Color.themeSurface)
                            .frame(height: 6)
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(LinearGradient(colors: [.themeSuccess, .themeAccent], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: 100 * subject.attendanceRate)
                            }
                        Text("\(Int(subject.attendanceRate * 100))%")
                            .font(.caption2)
                            .foregroundColor(.themeTextSecondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.themeBackground.opacity(0.5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(LinearGradient(colors: [.themePrimary.opacity(0.5), .clear], startPoint: .leading, endPoint: .trailing), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SubjectPerformanceCard: View {
    let subject: Subject
    var isMinimalist: Bool = true
    
    var body: some View {
        NavigationLink(value: subject) {
            HStack(spacing: 16) {
                Image(systemName: "book.closed.fill")
                    .foregroundColor(.themeSecondary)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(subject.title)
                        .font(.headline)
                        .foregroundColor(.themeTextPrimary)
                    Text(subject.courseTeacher)
                        .font(.caption)
                        .foregroundColor(.themeTextSecondary)
                }
                
                Spacer()
                
                Text("\(Int(subject.attendanceRate * 100))%")
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundColor(.themeTextPrimary)
            }
            .padding()
            .background(Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.adaptiveBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HomeEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var isGamified: Bool
    
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
        .background(isGamified ? Color.themeSurface : Color.clear)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isGamified ? Color.themePrimary.opacity(0.1) : Color.adaptiveBorder, lineWidth: 1)
        )
    }
}
