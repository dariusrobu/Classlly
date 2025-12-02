import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject var themeManager: AppTheme
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    
    @Query(sort: \Subject.title) var subjects: [Subject]
    @Query var tasks: [StudyTask]
    
    public init() {}

    var body: some View {
        NavigationView {
            Group {
                switch themeManager.selectedGameMode {
                case .arcade:
                    ArcadeDashboard(subjects: subjects, tasks: tasks)
                case .retro:
                    RetroDashboard(subjects: subjects, tasks: tasks)
                case .none:
                    StandardDashboard(subjects: subjects, tasks: tasks)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(themeManager.selectedGameMode != .none ? .dark : nil)
    }
    
    private var navigationTitle: String {
        switch themeManager.selectedGameMode {
        case .none: return "Dashboard"
        case .arcade: return "Arcade Hub"
        case .retro: return "Player 1"
        }
    }
}

// MARK: - 👾 RETRO DASHBOARD
struct RetroDashboard: View {
    let subjects: [Subject]
    let tasks: [StudyTask]
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    
    private var retroFont: Font.Design { .monospaced }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header... (Kept brief for clarity, assume standard header)
                // ...
                
                // Quests (Tasks)
                VStack(alignment: .leading, spacing: 12) {
                    Text("> ACTIVE QUESTS")
                        .font(.system(.headline, design: retroFont))
                        .foregroundColor(.yellow)
                    
                    let activeQuests = tasks.filter { !$0.isCompleted }.prefix(3)
                    
                    if activeQuests.isEmpty {
                        Text("No active quests. Map clear.")
                            .font(.system(.caption, design: retroFont))
                            .foregroundColor(.gray)
                    } else {
                        ForEach(activeQuests) { task in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.yellow)
                                VStack(alignment: .leading) {
                                    Text(task.title)
                                        .font(.system(.subheadline, design: retroFont))
                                        .lineLimit(1)
                                    // NOTES
                                    if !task.notes.isEmpty {
                                        Text(task.notes)
                                            .font(.system(size: 8, design: retroFont))
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                                Text("EXP+")
                                    .font(.system(size: 10, design: retroFont))
                                    .foregroundColor(.green)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.15))
                            .border(Color.gray.opacity(0.5), width: 1)
                        }
                    }
                }
                
                // ... (Skill Trees section)
            }
            .padding()
        }
        .background(Color(red: 0.05, green: 0.05, blue: 0.1).ignoresSafeArea())
    }
}

// MARK: - 🕹️ ARCADE DASHBOARD
struct ArcadeDashboard: View {
    let subjects: [Subject]
    let tasks: [StudyTask]
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // ... (Header and Stats)
                
                // Quest Log (Tasks)
                VStack(alignment: .leading, spacing: 16) {
                    Text("QUEST LOG")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                    
                    let activeQuests = tasks.filter { !$0.isCompleted }.prefix(3)
                    
                    if activeQuests.isEmpty {
                        // Empty state...
                    } else {
                        ForEach(activeQuests) { task in
                            HStack {
                                Circle()
                                    .strokeBorder(task.priority.color, lineWidth: 2)
                                    .background(Circle().fill(task.priority.color.opacity(0.2)))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: task.priority.iconName)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(task.priority.color)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(task.title)
                                        .font(.system(.body, design: .rounded))
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                    // NOTES
                                    if !task.notes.isEmpty {
                                        Text(task.notes)
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                    
                                    Text(task.subject?.title ?? "Side Quest")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                // XP Badge...
                            }
                            .padding()
                            .background(Color(white: 0.1))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                            )
                        }
                    }
                }
                
                // ... (Skill Mastery section)
            }
            .padding(20)
        }
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - 👔 STANDARD DASHBOARD
struct StandardDashboard: View {
    let subjects: [Subject]
    let tasks: [StudyTask]
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
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
    }
    
    // ... (Sections code omitted for brevity, uses HomeTaskCard below)
    
    private var welcomeHeader: some View {
        // ... (Header code)
        EmptyView() // Placeholder for actual header code
    }
    
    private var quickStatsSection: some View { EmptyView() }
    private var todaysClassesSection: some View { EmptyView() }
    
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
    
    private var academicPerformanceSection: some View { EmptyView() }
}

// MARK: - SHARED COMPONENTS

struct HomeTaskCard: View {
    let task: StudyTask
    @Environment(\.colorScheme) var colorScheme
    
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
                .foregroundColor(task.priority.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(.themeTextPrimary)
                
                // NOTES DISPLAY
                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.caption)
                        .foregroundColor(.themeTextSecondary)
                        .lineLimit(1)
                }
                
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

// ... (Other helpers: StatCard, HomeClassCard, HomeEmptyStateView, SubjectPerformanceCard remain unchanged)
struct StatCard: View { var body: some View { EmptyView() } } // Placeholder
struct HomeClassCard: View { var body: some View { EmptyView() } } // Placeholder
struct HomeEmptyStateView: View {
    let icon: String; let title: String; let message: String
    var body: some View { EmptyView() }
} // Placeholder
struct SubjectPerformanceCard: View { var body: some View { EmptyView() } } // Placeholder
