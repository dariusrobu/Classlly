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
                VStack(spacing: 24) {
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
            .background(Color.clear)
        }
    }
    
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome back!").font(.title2).fontWeight(.semibold)
            Text("Here's your academic overview for today").font(.subheadline).opacity(0.8)
            if let currentWeek = calendarManager.currentTeachingWeek {
                HStack {
                    Image(systemName: "calendar")
                    Text("Academic Week \(currentWeek) • \(calendarManager.currentSemester.displayName)")
                }
                .font(.caption).fontWeight(.semibold).padding(.top, 4)
                .foregroundColor(themeManager.isGamified ? GameColor.electricBlue : .themePrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(20).adaptiveCard()
    }
    
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Stats").font(.headline).fontWeight(.bold)
            HStack(spacing: 12) {
                StatCard(title: "Today's Classes", value: "\(getTodayClasses(academicWeek: calendarManager.currentTeachingWeek).count)", icon: "calendar").adaptiveCard(color: GameColor.electricBlue)
                StatCard(title: "Pending Tasks", value: "\(tasks.filter { !$0.isCompleted }.count)", icon: "checklist").adaptiveCard(color: GameColor.neonOrange)
                StatCard(title: "Subjects", value: "\(subjects.count)", icon: "book").adaptiveCard(color: GameColor.emeraldGreen)
            }
        }
    }
    
    private var todaysClassesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Classes").font(.headline).fontWeight(.bold)
                Spacer()
                NavigationLink("See All") { SubjectsView() }.font(.subheadline).foregroundColor(themeManager.isGamified ? GameColor.electricBlue : .themePrimary)
            }
            let todaysClasses = getTodayClasses(academicWeek: calendarManager.currentTeachingWeek)
            if todaysClasses.isEmpty {
                HomeEmptyStateView(icon: "calendar.badge.clock", title: "No classes today", message: "Enjoy your free time").adaptiveCard()
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
                Text("Upcoming Tasks").font(.headline).fontWeight(.bold)
                Spacer()
                NavigationLink("See All") { TasksView() }.font(.subheadline).foregroundColor(themeManager.isGamified ? GameColor.electricBlue : .themePrimary)
            }
            let upcomingTasks = tasks.filter { !$0.isCompleted }.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
            if upcomingTasks.isEmpty {
                HomeEmptyStateView(icon: "checkmark.circle", title: "No pending tasks", message: "You're all caught up!").adaptiveCard()
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
                Text("Academic Performance").font(.headline).fontWeight(.bold)
                Spacer()
                NavigationLink("See All") { SubjectsView() }.font(.subheadline).foregroundColor(themeManager.isGamified ? GameColor.electricBlue : .themePrimary)
            }
            if subjects.isEmpty {
                HomeEmptyStateView(icon: "chart.bar.fill", title: "No Subjects", message: "Add your first subject").adaptiveCard()
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
            let cDays = subject.courseDays ?? []
            let sDays = subject.seminarDays ?? []
            return (cDays.contains(weekday) && subject.occursThisWeek(academicWeek: academicWeek, isCourse: true)) ||
                   (sDays.contains(weekday) && subject.occursThisWeek(academicWeek: academicWeek, isCourse: false))
        }
    }
}

struct SubjectPerformanceCard: View {
    let subject: Subject
    private var averageGrade: Double? {
        let history = subject.gradeHistory ?? []
        guard !history.isEmpty else { return nil }
        return history.reduce(0.0) { $0 + $1.grade } / Double(history.count)
    }
    var body: some View {
        NavigationLink(destination: SubjectDetailView(subject: subject)) {
            HStack(spacing: 16) {
                ZStack { Circle().fill(Color.white.opacity(0.2)).frame(width: 44, height: 44); Image(systemName: "book.fill").font(.system(size: 18)) }
                VStack(alignment: .leading, spacing: 6) { Text(subject.title).font(.headline).fontWeight(.semibold).lineLimit(1); Text(subject.courseTeacher).font(.caption).opacity(0.8).lineLimit(1) }
                Spacer()
                if let grade = averageGrade { Text(String(format: "%.1f", grade)).font(.title3).fontWeight(.bold) } else { Text("N/A").font(.subheadline).opacity(0.6) }
            }
            .padding().adaptiveCard(color: GameColor.electricBlue)
        }.buttonStyle(PlainButtonStyle())
    }
}

struct StatCard: View {
    let title: String; let value: String; let icon: String
    var body: some View {
        VStack(spacing: 12) {
            ZStack { Circle().fill(Color.white.opacity(0.2)).frame(width: 40, height: 40); Image(systemName: icon).font(.title3).foregroundColor(.white) }
            Text(value).font(.system(size: 32, weight: .bold, design: .rounded))
            Text(title).font(.caption).fontWeight(.medium).multilineTextAlignment(.center).opacity(0.9).lineLimit(1).minimumScaleFactor(0.8)
        }.frame(maxWidth: .infinity).padding(.vertical, 20).padding(.horizontal, 8)
    }
}

struct HomeClassCard: View {
    let subject: Subject; let academicWeek: Int?
    var body: some View {
        HStack(spacing: 12) {
            ZStack { Circle().fill(Color.white.opacity(0.1)).frame(width: 40, height: 40); Image(systemName: "book.fill") }
            VStack(alignment: .leading, spacing: 4) {
                Text(subject.title).font(.headline)
                HStack { if subject.occursThisWeek(academicWeek: academicWeek, isCourse: true) { Text("Course").font(.caption).padding(.horizontal, 8).padding(.vertical, 2).background(Color.white.opacity(0.1)).cornerRadius(4) } }
                Text("\(subject.courseTimeString) • \(subject.courseClassroom)").font(.subheadline).opacity(0.7)
            }
            Spacer()
        }.padding().adaptiveCard()
    }
}

struct HomeTaskCard: View {
    let task: StudyTask
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.priority.systemIcon).font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title).font(.headline)
                if let subject = task.subject { Text(subject.title).font(.caption).opacity(0.8) }
                if let date = task.dueDate { Text(date.formatted(date: .abbreviated, time: .omitted)).font(.caption).opacity(0.7) }
            }
            Spacer()
        }.padding().adaptiveCard(color: GameColor.electricBlue)
    }
}

struct HomeEmptyStateView: View {
    let icon: String; let title: String; let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 40)).opacity(0.5)
            Text(title).font(.headline)
            Text(message).font(.subheadline).opacity(0.7).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity).padding(40)
    }
}
