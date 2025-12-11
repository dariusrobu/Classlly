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
                case .rainbow:
                    RainbowDashboard(subjects: subjects, tasks: tasks)
                case .arcade:
                    ArcadeDashboard(subjects: subjects, tasks: tasks)
                case .none:
                    StandardDashboard(subjects: subjects, tasks: tasks)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme((themeManager.selectedGameMode == .arcade || themeManager.selectedGameMode == .rainbow) ? .dark : nil)
    }
    
    private var navigationTitle: String {
        switch themeManager.selectedGameMode {
        case .none: return "Dashboard"
        case .arcade: return "Arcade Hub"
        case .rainbow: return "Dashboard"
        }
    }
}

// MARK: - 🌈 RAINBOW DASHBOARD
struct RainbowDashboard: View {
    let subjects: [Subject]
    let tasks: [StudyTask]
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @EnvironmentObject var themeManager: AppTheme
    
    private let statsColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        // Dynamic Accent Color
        let accentColor = themeManager.selectedTheme.primaryColor
        
        ScrollView {
            VStack(spacing: 24) {
                // 1. Welcome Header
                RainbowContainer {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome back!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Here's your academic overview for today")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        if let currentWeek = calendarManager.currentTeachingWeek {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(accentColor)
                                Text("Academic Week \(currentWeek) • \(calendarManager.currentSemester.displayName)")
                                    .font(.caption)
                                    .foregroundColor(accentColor)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // 2. Quick Stats
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Stats").font(.headline).foregroundColor(.white)
                    
                    LazyVGrid(columns: statsColumns, spacing: 12) {
                        RainbowStatBox(
                            title: "Today's Classes",
                            value: "\(filterTodayClasses(academicWeek: calendarManager.currentTeachingWeek).count)",
                            icon: "calendar",
                            color: accentColor // Dynamic
                        )
                        RainbowStatBox(
                            title: "Pending Tasks",
                            value: "\(tasks.filter { !$0.isCompleted }.count)",
                            icon: "checklist",
                            color: RainbowColors.orange
                        )
                        RainbowStatBox(
                            title: "Subjects",
                            value: "\(subjects.count)",
                            icon: "book",
                            color: RainbowColors.green
                        )
                    }
                }
                
                // 3. Today's Classes
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Today's Classes").font(.headline).foregroundColor(.white)
                        Spacer()
                        // Pass embedInNavigationStack: false
                        NavigationLink(destination: SubjectsView(embedInNavigationStack: false)) {
                            Text("See All").font(.subheadline).foregroundColor(accentColor)
                        }
                    }
                    
                    let todaysClasses = filterTodayClasses(academicWeek: calendarManager.currentTeachingWeek)
                    
                    if todaysClasses.isEmpty {
                        RainbowContainer {
                            VStack(spacing: 16) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("No classes today")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Enjoy your free time or catch up on studies")
                                    .font(.caption).foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        }
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(todaysClasses.prefix(3)) { subject in
                                RainbowContainer {
                                    HStack {
                                        Image(systemName: "book.fill")
                                            .foregroundColor(accentColor)
                                        
                                        VStack(alignment: .leading) {
                                            Text(subject.title).font(.headline).foregroundColor(.white)
                                            Text("\(subject.courseTimeString) • \(subject.courseClassroom)")
                                                .font(.caption).foregroundColor(.gray)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right").foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 4. Upcoming Tasks
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Upcoming Tasks").font(.headline).foregroundColor(.white)
                        Spacer()
                        // Pass embedInNavigationStack: false
                        NavigationLink(destination: TasksView(embedInNavigationStack: false)) {
                            Text("See All").font(.subheadline).foregroundColor(accentColor)
                        }
                    }
                    
                    let upcoming = tasks.filter { !$0.isCompleted }.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
                    
                    if let task = upcoming.first {
                        NavigationLink(destination: EditTaskView(task: task)) {
                            HStack(spacing: 16) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                VStack(alignment: .leading) {
                                    Text(task.title).font(.headline).bold().foregroundColor(.white)
                                    Text(task.dueDate != nil ? "Due \(formatDate(task.dueDate!))" : "No due date")
                                        .font(.caption).foregroundColor(.white.opacity(0.9))
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(.white)
                            }
                            .padding(20)
                            .background(accentColor)
                            .cornerRadius(20)
                            .shadow(color: accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                    } else {
                        Text("No upcoming tasks").font(.caption).foregroundColor(.gray)
                    }
                }
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
    }
    
    private func filterTodayClasses(academicWeek: Int?) -> [Subject] {
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
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        if Calendar.current.isDateInToday(date) { return "today" }
        else if Calendar.current.isDateInTomorrow(date) { return "tomorrow" }
        else { f.dateFormat = "MMM d"; return "on \(f.string(from: date))" }
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
        .background(Color.themeBackground)
    }
    
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
                StatBox(
                    title: "Today's Classes",
                    value: "\(filterTodayClasses(academicWeek: calendarManager.currentTeachingWeek).count)"
                )
                StatBox(
                    title: "Pending Tasks",
                    value: "\(tasks.filter { !$0.isCompleted }.count)"
                )
                StatBox(
                    title: "Subjects",
                    value: "\(subjects.count)"
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
            
            let todaysClasses = filterTodayClasses(academicWeek: calendarManager.currentTeachingWeek)
            
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
                        NavigationLink(destination: EditTaskView(task: task)) {
                            HomeTaskCard(task: task)
                        }
                        .buttonStyle(PlainButtonStyle())
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
    
    private func filterTodayClasses(academicWeek: Int?) -> [Subject] {
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

// MARK: - 🕹️ ARCADE DASHBOARD
struct ArcadeDashboard: View {
    let subjects: [Subject]
    let tasks: [StudyTask]
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    
    // 3 Column Grid for Stats
    private let statsColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 1. Hero Card
                ZStack {
                    LinearGradient(
                        colors: [Color.indigo, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .mask(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 5)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .font(.title2)
                                .foregroundColor(.yellow)
                            Text("LEVEL \(calendarManager.currentTeachingWeek ?? 1)")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.black)
                                .foregroundColor(.white)
                            Spacer()
                            Text("RANK: SCHOLAR")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                        }
                        
                        // XP Bar Placeholder
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("XP PROGRESS").font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text("750 / 1000").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.black.opacity(0.3))
                                    Capsule().fill(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                                        .frame(width: geo.size.width * 0.75)
                                }
                            }.frame(height: 10)
                        }
                    }
                    .padding(20)
                }
                
                // 2. Stats Grid
                LazyVGrid(columns: statsColumns, spacing: 12) {
                    ArcadeStatPill(
                        icon: "shield.fill",
                        value: "\(filterTodayClasses(academicWeek: calendarManager.currentTeachingWeek).count)",
                        label: "Raids",
                        gradient: Gradient(colors: [.cyan, .blue])
                    )
                    ArcadeStatPill(
                        icon: "flame.fill",
                        value: "\(tasks.filter { !$0.isCompleted }.count)",
                        label: "Quests",
                        gradient: Gradient(colors: [.orange, .red])
                    )
                    ArcadeStatPill(
                        icon: "bolt.fill",
                        value: "\(subjects.count)",
                        label: "Skills",
                        gradient: Gradient(colors: [.purple, .pink])
                    )
                }
                
                // 3. Daily Raids (Today's Classes)
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("DAILY RAIDS")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.heavy)
                            .foregroundColor(.cyan)
                        Spacer()
                        NavigationLink("VIEW ALL") { SubjectsView() }
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.cyan)
                            .padding(6)
                            .background(Color.cyan.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    let todaysClasses = filterTodayClasses(academicWeek: calendarManager.currentTeachingWeek)
                    
                    if todaysClasses.isEmpty {
                        Text("No raids scheduled. Base is secure.")
                            .font(.caption).fontWeight(.bold).foregroundColor(.gray)
                            .padding().frame(maxWidth: .infinity).background(Color(white: 0.1)).cornerRadius(16)
                    } else {
                        ForEach(todaysClasses) { subject in
                            HStack {
                                Image(systemName: "shield.fill").foregroundColor(.cyan)
                                VStack(alignment: .leading) {
                                    Text(subject.title).font(.system(.subheadline, design: .rounded)).fontWeight(.bold).foregroundColor(.white)
                                    
                                    HStack(spacing: 12) {
                                        Label(subject.courseTimeString, systemImage: "clock.fill")
                                        Label(subject.courseClassroom, systemImage: "mappin.and.ellipse")
                                        if subject.occursThisWeek(academicWeek: calendarManager.currentTeachingWeek, isCourse: true) {
                                            Text("COURSE").font(.system(size: 8, weight: .black)).padding(4).background(Color.blue.opacity(0.3)).cornerRadius(4).foregroundColor(.blue)
                                        } else {
                                            Text("SEMINAR").font(.system(size: 8, weight: .black)).padding(4).background(Color.orange.opacity(0.3)).cornerRadius(4).foregroundColor(.orange)
                                        }
                                    }.font(.caption2).foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding().background(Color(white: 0.1)).cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cyan.opacity(0.3), lineWidth: 1))
                        }
                    }
                }
                
                // 4. Quest Log (Tasks)
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("QUEST LOG")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.heavy)
                            .foregroundColor(.yellow)
                        Spacer()
                        NavigationLink("VIEW ALL") { TasksView() }
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.yellow)
                            .padding(6)
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    let activeQuests = tasks.filter { !$0.isCompleted }.prefix(3)
                    
                    if activeQuests.isEmpty {
                        Text("Map Clear. No active quests.").font(.caption).fontWeight(.bold).foregroundColor(.gray).padding().frame(maxWidth: .infinity).background(Color(white: 0.1)).cornerRadius(16)
                    } else {
                        ForEach(activeQuests) { task in
                            NavigationLink(destination: EditTaskView(task: task)) {
                                HStack {
                                    Image(systemName: task.priority.iconName).foregroundColor(task.priority.color)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(task.title).font(.system(.body, design: .rounded)).fontWeight(.bold).foregroundColor(.white)
                                        if !task.notes.isEmpty { Text(task.notes).font(.caption2).foregroundColor(.gray).lineLimit(1) }
                                        
                                        HStack {
                                            if let sub = task.subject { Text(sub.title).foregroundColor(.cyan) }
                                            if let d = task.dueDate { Text("• \(formatDate(d))").foregroundColor(.gray) }
                                        }.font(.caption2)
                                    }
                                    Spacer()
                                    Text("+100 XP").font(.system(size: 10, weight: .black)).foregroundColor(.green).padding(4).background(Color.green.opacity(0.2)).cornerRadius(4)
                                }
                                .padding().background(Color(white: 0.1)).cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // 5. Skill Mastery (Academic Performance)
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("SKILL MASTERY")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.heavy)
                            .foregroundColor(.purple)
                        Spacer()
                        NavigationLink("VIEW ALL") { SubjectsView() }
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.purple)
                            .padding(6)
                            .background(Color.purple.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    ForEach(subjects.prefix(3)) { subject in
                        HStack {
                            Image(systemName: "bolt.fill").foregroundColor(.purple)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(subject.title).font(.system(.subheadline, design: .rounded)).fontWeight(.bold).foregroundColor(.white)
                                Text(subject.courseTeacher).font(.caption2).foregroundColor(.gray)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("LVL \(Int(subject.attendanceRate * 10))").font(.caption).fontWeight(.black).foregroundColor(.purple)
                                if let g = subject.currentGrade {
                                    Text("XP: \(String(format: "%.1f", g))").font(.caption2).fontWeight(.bold).foregroundColor(.yellow)
                                }
                            }
                        }
                        .padding()
                        .background(Color(white: 0.1))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.purple.opacity(0.3), lineWidth: 1))
                    }
                }
            }
            .padding(20)
        }
        .background(Color.black.ignoresSafeArea())
    }
    
    private func filterTodayClasses(academicWeek: Int?) -> [Subject] {
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
    
    private func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.dateFormat = "MMM d"; return f.string(from: date) }
}

// MARK: - LOCAL COMPONENTS (For Standard Dashboard)

struct HomeClassCard: View {
    let subject: Subject
    let academicWeek: Int?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.themePrimary.opacity(0.1)).frame(width: 40, height: 40)
                Image(systemName: "book.fill").foregroundColor(.themePrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(subject.title).font(.headline).foregroundColor(.themeTextPrimary)
                HStack {
                    if subject.occursThisWeek(academicWeek: academicWeek, isCourse: true) {
                        Text("Course").font(.caption).padding(.horizontal, 8).padding(.vertical, 2).background(Color.themePrimary.opacity(0.1)).foregroundColor(.themePrimary).cornerRadius(4)
                    }
                    if subject.occursThisWeek(academicWeek: academicWeek, isCourse: false) {
                        Text("Seminar").font(.caption).padding(.horizontal, 8).padding(.vertical, 2).background(Color.themeSuccess.opacity(0.1)).foregroundColor(.themeSuccess).cornerRadius(4)
                    }
                }
                Text("\(subject.courseTimeString) • \(subject.courseClassroom)").font(.subheadline).foregroundColor(.themeTextSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right").font(.system(size: 14, weight: .medium)).foregroundColor(.secondary)
        }
        .padding()
        .background(Color.themeSurface)
        .cornerRadius(12)
    }
}

struct HomeTaskCard: View {
    let task: StudyTask
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.priority.systemIcon).foregroundColor(task.priority.color).frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title).font(.headline).foregroundColor(.themeTextPrimary)
                if !task.notes.isEmpty { Text(task.notes).font(.caption).foregroundColor(.themeTextSecondary).lineLimit(1) }
                if let subjectTitle = task.subject?.title { Text(subjectTitle).font(.subheadline).foregroundColor(.themeTextSecondary) }
                Text(dueText).font(.caption).foregroundColor(.themeTextSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right").font(.system(size: 14, weight: .medium)).foregroundColor(.secondary)
        }
        .padding()
        .background(Color.themeSurface)
        .cornerRadius(12)
    }
    
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
}

struct HomeEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 40)).foregroundColor(.secondary)
            Text(title).font(.headline).foregroundColor(.themeTextPrimary)
            Text(message).font(.subheadline).foregroundColor(.themeTextSecondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.themeSurface)
        .cornerRadius(12)
    }
}

struct SubjectPerformanceCard: View {
    let subject: Subject
    var body: some View {
        NavigationLink(destination: SubjectDetailView(subject: subject)) {
            HStack {
                ZStack { Circle().fill(Color.themePrimary.opacity(0.1)).frame(width: 44, height: 44); Image(systemName: "book.fill").foregroundColor(.themePrimary) }
                VStack(alignment: .leading) { Text(subject.title).font(.headline); Text(subject.courseTeacher).font(.caption).foregroundColor(.secondary) }
                Spacer()
                VStack(alignment: .trailing) { Text("Avg: \(String(format: "%.1f", subject.currentGrade ?? 0))").font(.caption).bold(); Text("Att: \(Int(subject.attendanceRate*100))%").font(.caption).foregroundColor(.secondary) }
            }.padding().background(Color.themeSurface).cornerRadius(12)
        }.buttonStyle(PlainButtonStyle())
    }
}
