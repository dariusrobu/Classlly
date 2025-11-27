import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @EnvironmentObject var themeManager: AppTheme
    @Environment(\.horizontalSizeClass) var sizeClass
    
    @AppStorage("isGamifiedMode") private var isGamifiedMode = false
    
    @Query(sort: \Subject.title) var subjects: [Subject]
    @Query var tasks: [StudyTask]
    
    public init() {}

    var body: some View {
        ScrollView {
            if isGamifiedMode {
                GamifiedDashboardView(
                    calendarManager: calendarManager,
                    subjects: subjects,
                    tasks: tasks,
                    themeColor: themeManager.selectedTheme.accentColor,
                    isiPad: sizeClass == .regular
                )
            } else {
                StandardDashboardView(
                    calendarManager: calendarManager,
                    subjects: subjects,
                    tasks: tasks,
                    isiPad: sizeClass == .regular
                )
            }
        }
        .background(Color.themeBackground)
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if sizeClass == .regular {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsDashboardView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(isGamifiedMode ? themeManager.selectedTheme.accentColor : .primary)
                    }
                }
            }
        }
    }
}

// MARK: - 1. Standard Dashboard Layout
struct StandardDashboardView: View {
    var calendarManager: AcademicCalendarManager
    var subjects: [Subject]
    var tasks: [StudyTask]
    var isiPad: Bool
    
    private var gridColumns: [GridItem] {
        isiPad ? [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)] : [GridItem(.flexible())]
    }
    
    var body: some View {
        VStack(spacing: 20) {
            welcomeHeader
            quickStatsSection
            
            LazyVGrid(columns: gridColumns, spacing: 24) {
                todaysClassesSection
                upcomingTasksSection
                if !isiPad { academicPerformanceSection }
            }
            if isiPad { academicPerformanceSection }
        }
        .padding()
    }
    
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome back!")
                .font(.title2).fontWeight(.semibold).foregroundColor(.themeTextPrimary)
            Text("Here's your academic overview for today")
                .font(.subheadline).foregroundColor(.themeTextSecondary)
            if let currentWeek = calendarManager.currentTeachingWeek {
                HStack {
                    Image(systemName: "calendar")
                    Text("Week \(currentWeek) • \(calendarManager.currentSemester.displayName)")
                }.font(.caption).foregroundColor(.themePrimary).padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding().background(Color.themeSurface).cornerRadius(12)
    }
    
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Stats").font(.headline).fontWeight(.semibold).foregroundColor(.themeTextPrimary)
            HStack(spacing: 12) {
                NavigationLink(destination: CalendarView()) {
                    StatCard(title: "Classes", value: "\(getTodayClasses().count)", icon: "calendar", color: .themePrimary)
                }
                NavigationLink(destination: TasksView()) {
                    StatCard(title: "Tasks", value: "\(tasks.filter { !$0.isCompleted }.count)", icon: "checklist", color: .themeWarning)
                }
                NavigationLink(destination: SubjectsView()) {
                    StatCard(title: "Subjects", value: "\(subjects.count)", icon: "book", color: .themeSuccess)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var todaysClassesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Classes").font(.headline).fontWeight(.semibold).foregroundColor(.themeTextPrimary)
                Spacer()
                NavigationLink("See All") { CalendarView() }.font(.subheadline).foregroundColor(.themePrimary)
            }
            let classes = getTodayClasses()
            if classes.isEmpty {
                HomeEmptyStateView(icon: "calendar.badge.clock", title: "No classes today", message: "Enjoy your free time")
            } else {
                LazyVStack(spacing: 12) { ForEach(classes.prefix(3)) { HomeClassCard(subject: $0, academicWeek: calendarManager.currentTeachingWeek) } }
            }
        }
    }
    
    private var upcomingTasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Upcoming Tasks").font(.headline).fontWeight(.semibold).foregroundColor(.themeTextPrimary)
                Spacer()
                NavigationLink("See All") { TasksView() }.font(.subheadline).foregroundColor(.themePrimary)
            }
            let upcoming = tasks.filter { !$0.isCompleted }.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
            if upcoming.isEmpty {
                HomeEmptyStateView(icon: "checkmark.circle", title: "No pending tasks", message: "All caught up!")
            } else {
                LazyVStack(spacing: 12) { ForEach(upcoming.prefix(3)) { HomeTaskCard(task: $0) } }
            }
        }
    }
    
    private var academicPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Performance").font(.headline).fontWeight(.semibold).foregroundColor(.themeTextPrimary)
                Spacer()
                NavigationLink("See All") { SubjectsView() }.font(.subheadline).foregroundColor(.themePrimary)
            }
            if subjects.isEmpty {
                HomeEmptyStateView(icon: "chart.bar.fill", title: "No Subjects", message: "Add subjects to track stats")
            } else {
                LazyVStack(spacing: 12) { ForEach(subjects.prefix(4)) { SubjectPerformanceCard(subject: $0) } }
            }
        }
    }
    
    func getTodayClasses() -> [Subject] {
        let today = Date()
        let weekday = Calendar.current.component(.weekday, from: today)
        return subjects.filter { subject in
            let hasCourse = subject.courseDays.contains(weekday) && subject.occursThisWeek(academicWeek: calendarManager.currentTeachingWeek, isCourse: true)
            let hasSeminar = subject.seminarDays.contains(weekday) && subject.occursThisWeek(academicWeek: calendarManager.currentTeachingWeek, isCourse: false)
            return hasCourse || hasSeminar
        }
    }
}

// MARK: - 2. Gamified Dashboard Layout
struct GamifiedDashboardView: View {
    var calendarManager: AcademicCalendarManager
    var subjects: [Subject]
    var tasks: [StudyTask]
    var themeColor: Color
    var isiPad: Bool
    
    private var gridColumns: [GridItem] {
        isiPad ? [GridItem(.flexible(), spacing: 24), GridItem(.flexible(), spacing: 24)] : [GridItem(.flexible())]
    }
    
    var body: some View {
        VStack(spacing: 24) {
            gamifiedHeader
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Quick Stats").font(.headline).foregroundColor(.primary)
                HStack(spacing: 15) {
                    NavigationLink(destination: CalendarView()) {
                        GamifiedStatCard(title: "Today's Classes", value: "\(getTodayClasses().count)", icon: "calendar", gradient: Gradient(colors: [themeColor, themeColor.opacity(0.6)]))
                    }
                    NavigationLink(destination: TasksView()) {
                        GamifiedStatCard(title: "Pending Tasks", value: "\(tasks.filter { !$0.isCompleted }.count)", icon: "checklist", gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.7)]))
                    }
                    NavigationLink(destination: SubjectsView()) {
                        GamifiedStatCard(title: "Subjects", value: "\(subjects.count)", icon: "book.closed", gradient: Gradient(colors: [Color.green, Color.green.opacity(0.7)]))
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            LazyVGrid(columns: gridColumns, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack { Text("Today's Classes").font(.headline).foregroundColor(.primary); Spacer(); NavigationLink("See All") { CalendarView() }.font(.caption).foregroundColor(themeColor) }
                    let classes = getTodayClasses()
                    if classes.isEmpty {
                        VStack(spacing: 15) {
                            Image(systemName: "calendar.badge.clock").font(.system(size: 45)).foregroundColor(.secondary)
                            Text("No classes").font(.headline).foregroundColor(.primary)
                        }.frame(maxWidth: .infinity).frame(height: 150).background(Color.themeSurface).cornerRadius(20)
                    } else {
                        ForEach(classes.prefix(3)) { s in GamifiedClassCard(subject: s, themeColor: themeColor, academicWeek: calendarManager.currentTeachingWeek) }
                    }
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack { Text("Upcoming Tasks").font(.headline).foregroundColor(.primary); Spacer(); NavigationLink("See All") { TasksView() }.font(.caption).foregroundColor(themeColor) }
                    let upcoming = tasks.filter { !$0.isCompleted }.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
                    if upcoming.isEmpty {
                        VStack { Text("All caught up!").foregroundColor(.secondary) }.frame(maxWidth: .infinity).frame(height: 100).background(Color.themeSurface).cornerRadius(20)
                    } else {
                        ForEach(upcoming.prefix(3)) { t in GamifiedTaskCard(task: t, color: themeColor) }
                    }
                }
                
                if isiPad {
                     VStack(alignment: .leading, spacing: 10) {
                        HStack { Text("Performance").font(.headline).foregroundColor(.primary); Spacer(); NavigationLink("See All") { SubjectsView() }.font(.caption).foregroundColor(themeColor) }
                         ForEach(subjects.prefix(3)) { s in GamifiedPerformanceRow(subject: s, color: themeColor) }
                    }
                }
            }
            if !isiPad {
                VStack(alignment: .leading, spacing: 10) {
                    HStack { Text("Performance").font(.headline).foregroundColor(.primary); Spacer(); NavigationLink("See All") { SubjectsView() }.font(.caption).foregroundColor(themeColor) }
                     ForEach(subjects.prefix(3)) { s in GamifiedPerformanceRow(subject: s, color: themeColor) }
                }
            }
        }
        .padding()
    }
    
    private var gamifiedHeader: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Welcome back!").font(.largeTitle).fontWeight(.bold).foregroundColor(.primary)
            Text("Here's your academic overview").font(.subheadline).foregroundColor(.secondary)
            HStack {
                if let currentWeek = calendarManager.currentTeachingWeek {
                    Image(systemName: "calendar").foregroundColor(themeColor)
                    Text("Week \(currentWeek) • \(calendarManager.currentSemester.displayName)").foregroundColor(themeColor)
                }
            }.font(.caption).padding(.top, 5)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding().background(Color.themeSurface.opacity(0.5)).cornerRadius(20)
    }
    
    func getTodayClasses() -> [Subject] {
        let today = Date()
        let weekday = Calendar.current.component(.weekday, from: today)
        return subjects.filter { subject in
            let hasCourse = subject.courseDays.contains(weekday) && subject.occursThisWeek(academicWeek: calendarManager.currentTeachingWeek, isCourse: true)
            let hasSeminar = subject.seminarDays.contains(weekday) && subject.occursThisWeek(academicWeek: calendarManager.currentTeachingWeek, isCourse: false)
            return hasCourse || hasSeminar
        }
    }
}

// --- HELPERS ---

struct GamifiedStatCard: View { let title: String; let value: String; let icon: String; let gradient: Gradient; var body: some View { VStack { ZStack { Circle().fill(.white.opacity(0.2)).frame(width: 40, height: 40); Image(systemName: icon).font(.title3).foregroundColor(.white) }; Text(value).font(.system(size: 36, weight: .bold)).foregroundColor(.white); Text(title).font(.caption).fontWeight(.medium).foregroundColor(.white.opacity(0.9)) }.frame(maxWidth: .infinity).frame(height: 140).background(LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)).cornerRadius(20) } }
struct GamifiedClassCard: View { let subject: Subject; let themeColor: Color; let academicWeek: Int?; var body: some View { HStack(spacing: 15) { ZStack { Circle().fill(.white.opacity(0.2)).frame(width: 40, height: 40); Image(systemName: "book.fill").font(.system(size: 18, weight: .bold)).foregroundColor(.white) }; VStack(alignment: .leading, spacing: 2) { Text(subject.title).font(.headline).fontWeight(.bold).foregroundColor(.white); HStack(spacing: 4) { Image(systemName: "clock"); Text(subject.courseTimeString); Text("•"); Text(subject.courseClassroom) }.font(.caption).foregroundColor(.white.opacity(0.8)) }; Spacer() }.padding().background(LinearGradient(gradient: Gradient(colors: [themeColor, themeColor.opacity(0.7)]), startPoint: .leading, endPoint: .trailing)).cornerRadius(24) } }
struct GamifiedTaskCard: View { let task: StudyTask; let color: Color; var body: some View { HStack(spacing: 15) { ZStack { Circle().fill(.white).frame(width: 24, height: 24); Image(systemName: "exclamationmark").font(.caption.bold()).foregroundColor(color) }.padding(.leading, 8); VStack(alignment: .leading) { Text(task.title).font(.headline).bold().foregroundColor(.white); if let d = task.dueDate { Text(formatDate(d)).font(.caption).foregroundColor(.white.opacity(0.8)) } }; Spacer(); Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.7)) }.padding().background(LinearGradient(gradient: Gradient(colors: [color, color.opacity(0.7)]), startPoint: .leading, endPoint: .trailing)).cornerRadius(30) }
    // ✅ FIXED: Removed unused 'd' variable in closure by not capturing it, simply using formatDate(d) directly.
    private func formatDate(_ d: Date) -> String { let f = DateFormatter(); f.dateFormat = "MMM d"; return "Due \(f.string(from: d))" }
}
struct GamifiedPerformanceRow: View { let subject: Subject; let color: Color; var body: some View { HStack(spacing: 15) { ZStack { Circle().fill(.white.opacity(0.2)).frame(width: 40, height: 40); Image(systemName: "book.fill").foregroundColor(.white) }; VStack(alignment: .leading) { Text(subject.title).font(.headline).bold().foregroundColor(.white); Text(subject.courseTeacher).font(.caption).foregroundColor(.white.opacity(0.7)) }; Spacer(); VStack(alignment: .trailing) { HStack(spacing: 4) { Image(systemName: "person.fill"); Text("\(Int(subject.attendanceRate * 100))%") }.font(.caption).foregroundColor(.white.opacity(0.8)) } }.padding().background(LinearGradient(gradient: Gradient(colors: [color.opacity(0.8), color.opacity(0.5)]), startPoint: .leading, endPoint: .trailing)).cornerRadius(20) } }
struct SubjectPerformanceCard: View { let subject: Subject; var body: some View { NavigationLink(destination: SubjectDetailView(subject: subject)) { HStack { VStack(alignment: .leading) { Text(subject.title).font(.headline); Text(subject.courseTeacher).font(.caption).foregroundColor(.secondary) }; Spacer(); Text("\(Int(subject.attendanceRate * 100))%").font(.subheadline).bold() }.padding().background(Color.themeSurface).cornerRadius(12) }.buttonStyle(.plain) } }
struct StatCard: View { let title: String; let value: String; let icon: String; let color: Color; var body: some View { VStack { Image(systemName: icon).foregroundColor(color); Text(value).font(.title2).bold(); Text(title).font(.caption).foregroundColor(.secondary) }.frame(maxWidth: .infinity).padding().background(Color.themeSurface).cornerRadius(12) } }
struct HomeClassCard: View { let subject: Subject; let academicWeek: Int?; var body: some View { HStack { Text(subject.title).font(.headline); Spacer(); Text(subject.courseTimeString).font(.subheadline) }.padding().background(Color.themeSurface).cornerRadius(12) } }
struct HomeTaskCard: View { let task: StudyTask; var body: some View { HStack { Image(systemName: task.priority.systemIcon).foregroundColor(task.priority.color); Text(task.title).font(.headline); Spacer() }.padding().background(Color.themeSurface).cornerRadius(12) } }
struct HomeEmptyStateView: View { let icon: String; let title: String; let message: String; var body: some View { VStack { Image(systemName: icon).font(.largeTitle); Text(title).font(.headline); Text(message).font(.caption) }.frame(maxWidth: .infinity).padding().background(Color.themeSurface).cornerRadius(12) } }
