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
        .preferredColorScheme((themeManager.selectedGameMode == .arcade || themeManager.selectedGameMode == .retro || themeManager.selectedGameMode == .rainbow) ? .dark : nil)
    }
    
    private var navigationTitle: String {
        switch themeManager.selectedGameMode {
        case .none: return "Dashboard"
        case .arcade: return "Arcade Hub"
        case .retro: return "Player 1"
        case .rainbow: return "Dashboard"
        }
    }
}

<<<<<<< HEAD
// MARK: - ⚡️ QUICK ATTENDANCE BUTTON
struct QuickAttendanceButton: View {
    @Bindable var subject: Subject
    @Environment(\.modelContext) var modelContext
    var color: Color
    var style: ButtonStyleType = .standard
    
    enum ButtonStyleType {
        case standard, rainbow, arcade
    }
    
    var isAttendedToday: Bool {
        let calendar = Calendar.current
        return subject.attendanceHistory?.contains { calendar.isDate($0.date, inSameDayAs: Date()) } ?? false
    }
    
    var body: some View {
        Button(action: toggleAttendance) {
            Group {
                if isAttendedToday {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(style == .arcade ? .green : (style == .rainbow ? .white : .themeSuccess))
                        .opacity(style == .rainbow ? 0.8 : 1.0)
                } else {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                        .foregroundColor(color)
                        .contentShape(Circle()) // Increases tap area
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func toggleAttendance() {
        let calendar = Calendar.current
        let today = Date()
        
        if isAttendedToday {
            // Remove today's attendance
            if let entryIndex = subject.attendanceHistory?.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
                if let entry = subject.attendanceHistory?[entryIndex] {
                    modelContext.delete(entry)
                }
            }
        } else {
            // Add attendance
            let newEntry = AttendanceEntry(date: today, attended: true, notes: "Quick add from Dashboard")
            newEntry.subject = subject
            modelContext.insert(newEntry)
        }
    }
}

// MARK: - 📊 PROGRESS RING COMPONENT
struct DayProgressRing: View {
    let completed: Int
    let total: Int
    let color: Color
    
    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }
    
    var body: some View {
        ZStack {
            // Background Circle
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 6)
            
            // Progress Circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring, value: progress)
            
            // Text
            VStack(spacing: 0) {
                Text("\(completed)/\(total)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
                Text("Done")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 55, height: 55)
    }
}

// MARK: - 🌈 RAINBOW DASHBOARD
=======
// MARK: - 🌈 RAINBOW DASHBOARD (Refined Fix)
>>>>>>> parent of 347e801 (removed retro)
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
        let accentColor = themeManager.selectedTheme.primaryColor
<<<<<<< HEAD
        let formattedDate = Date().formatted(date: .abbreviated, time: .omitted)
        let progress = DashboardLogic.getDailyProgress(subjects: subjects, academicWeek: calendarManager.currentTeachingWeek)
=======
>>>>>>> parent of 80025b8 (exam added)
        
        ScrollView {
            VStack(spacing: 24) {
                // 1. Welcome Header
                RainbowContainer {
<<<<<<< HEAD
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Welcome back!")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Here's your academic overview")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            if let currentWeek = calendarManager.currentTeachingWeek {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(accentColor)
                                    Text("Week \(currentWeek) • \(formattedDate)")
                                        .font(.caption)
                                        .foregroundColor(accentColor)
                                }
                                .padding(.top, 4)
=======
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
>>>>>>> parent of 80025b8 (exam added)
                            }
                        }
                        Spacer()
                        if progress.total > 0 {
                            DayProgressRing(completed: progress.completed, total: progress.total, color: accentColor)
                                .padding(.leading, 8)
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
                        // FIX: Pass embedInNavigationStack: false
                        NavigationLink(destination: SubjectsView(embedInNavigationStack: false)) {
                            Text("See All").font(.subheadline).foregroundColor(accentColor)
                        }
                    }
                    
                    let todaysClasses = DashboardLogic.filterTodayClasses(subjects: subjects, academicWeek: calendarManager.currentTeachingWeek)
                    
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
                                        
                                        // Quick Attendance Button
                                        QuickAttendanceButton(subject: subject, color: accentColor, style: .rainbow)
                                            .frame(width: 44, height: 44)
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
                        // FIX: Pass embedInNavigationStack: false
                        NavigationLink(destination: TasksView(embedInNavigationStack: false)) {
                            Text("See All").font(.subheadline).foregroundColor(accentColor)
                        }
                    }
                    
                    let upcoming = tasks.filter { !$0.isCompleted }.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
                    
                    if let task = upcoming.first {
                        Button(action: {}) {
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
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        if Calendar.current.isDateInToday(date) { return "today" }
        else if Calendar.current.isDateInTomorrow(date) { return "tomorrow" }
        else { f.dateFormat = "MMM d"; return "on \(f.string(from: date))" }
    }
}

// ... Standard/Arcade/Retro Code is preserved (omitted for brevity)
struct StandardDashboard: View {
    let subjects: [Subject]
    let tasks: [StudyTask]
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
<<<<<<< HEAD
        let formattedDate = Date().formatted(date: .abbreviated, time: .omitted)
        let progress = DashboardLogic.getDailyProgress(subjects: subjects, academicWeek: calendarManager.currentTeachingWeek)
        
        ScrollView {
            VStack(spacing: 20) {
                // Header Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Welcome back!")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.themeTextPrimary)
                            Text("Here's your academic overview")
                                .font(.subheadline)
                                .foregroundColor(.themeTextSecondary)
                            
                            if let currentWeek = calendarManager.currentTeachingWeek {
                                HStack {
                                    Image(systemName: "calendar")
                                    Text("Week \(currentWeek) • \(formattedDate)")
                                }
                                .font(.caption)
                                .foregroundColor(.themePrimary)
                                .padding(.top, 4)
                            }
                        }
                        
                        Spacer()
                        
                        // Progress Ring
                        if progress.total > 0 {
                            DayProgressRing(completed: progress.completed, total: progress.total, color: .themePrimary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.themeSurface)
                .cornerRadius(12)
                
=======
        ScrollView {
            VStack(spacing: 20) {
                welcomeHeader
                quickStatsSection
>>>>>>> parent of 80025b8 (exam added)
                todaysClassesSection
                upcomingTasksSection
                academicPerformanceSection
            }
            .padding()
        }
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
            
            let todaysClasses = DashboardLogic.filterTodayClasses(subjects: subjects, academicWeek: calendarManager.currentTeachingWeek)
            
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
            .padding(.horizontal)
            
            if subjects.isEmpty {
                HomeEmptyStateView(
                    icon: "chart.bar.fill",
                    title: "No Subjects",
                    message: "Add your first subject to track academic performance"
                )
                .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(subjects) { subject in
                            CompactPerformanceCard(subject: subject)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

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
<<<<<<< HEAD
        let formattedDate = Date().formatted(date: .abbreviated, time: .omitted).uppercased()
        let progress = DashboardLogic.getDailyProgress(subjects: subjects, academicWeek: calendarManager.currentTeachingWeek)
        
=======
>>>>>>> parent of 80025b8 (exam added)
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
<<<<<<< HEAD
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text("LEVEL \(calendarManager.currentTeachingWeek ?? 1)")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.black)
                                    .foregroundColor(.white)
                                
                                Text(formattedDate)
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
=======
                            Text("LEVEL \(calendarManager.currentTeachingWeek ?? 1)")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.black)
                                .foregroundColor(.white)
>>>>>>> parent of 80025b8 (exam added)
                            Spacer()
                            
                            if progress.total > 0 {
                                DayProgressRing(completed: progress.completed, total: progress.total, color: .cyan)
                            } else {
                                Text("RANK: SCHOLAR")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(12)
                            }
                        }
                        
                        // XP Bar
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
                    
                    let todaysClasses = DashboardLogic.filterTodayClasses(subjects: subjects, academicWeek: calendarManager.currentTeachingWeek)
                    
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
                                // Arcade Check-In
                                QuickAttendanceButton(subject: subject, color: .cyan, style: .arcade)
                                    .frame(width: 44, height: 44)
                            }
                            .padding().background(Color(white: 0.1)).cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cyan.opacity(0.3), lineWidth: 1))
                        }
                    }
                }
                
<<<<<<< HEAD
                // 3. Quest Log
=======
                // 4. Quest Log (Tasks)
>>>>>>> parent of 80025b8 (exam added)
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
                    }
                }
                
<<<<<<< HEAD
                // 4. Skill Mastery
=======
                // 5. Skill Mastery (Academic Performance)
>>>>>>> parent of 80025b8 (exam added)
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
    
    private func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.dateFormat = "MMM d"; return f.string(from: date) }
}

// MARK: - DASHBOARD LOGIC HELPER
struct DashboardLogic {
    static func getDailyProgress(subjects: [Subject], academicWeek: Int?) -> (completed: Int, total: Int) {
        let today = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: today)
        
        var total = 0
        var completed = 0
        
        for subject in subjects {
            let isCourseToday = subject.courseDays.contains(weekday) && subject.occursThisWeek(academicWeek: academicWeek, isCourse: true)
            let isSeminarToday = subject.seminarDays.contains(weekday) && subject.occursThisWeek(academicWeek: academicWeek, isCourse: false)
            
            if isCourseToday {
                total += 1
                if isTimePassed(subject.courseEndTime) { completed += 1 }
            }
            
            if isSeminarToday {
                total += 1
                if isTimePassed(subject.seminarEndTime) { completed += 1 }
            }
        }
        
        return (completed, total)
    }
    
    static func filterTodayClasses(subjects: [Subject], academicWeek: Int?) -> [Subject] {
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
    
    private static func isTimePassed(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        // Extract hour/minute from subject date (assuming it has correct components)
        // and compare with current hour/minute
        let eventComponents = calendar.dateComponents([.hour, .minute], from: date)
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        
        guard let eh = eventComponents.hour, let em = eventComponents.minute,
              let nh = nowComponents.hour, let nm = nowComponents.minute else { return false }
        
        if nh > eh { return true }
        if nh == eh && nm >= em { return true }
        return false
    }
}

// MARK: - 👾 RETRO DASHBOARD
struct RetroDashboard: View {
    let subjects: [Subject]
    let tasks: [StudyTask]
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    private var retroFont: Font.Design { .monospaced }
    
    private let statsColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 1. Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "person.crop.square.fill").font(.system(size: 40)).foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("PLAYER 1").font(.system(.title3, design: retroFont)).fontWeight(.black).foregroundColor(.green)
                            Text("Level \(calendarManager.currentTeachingWeek ?? 1)").font(.system(.caption, design: retroFont)).foregroundColor(.white)
                        }
                        Spacer()
                        Text("HP 100/100").font(.system(.caption, design: retroFont)).foregroundColor(.red).padding(6).overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.red, lineWidth: 1))
                    }
                }
                .padding().background(Color.black).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green, lineWidth: 2))
                
                // 2. Inventory (Stats)
                LazyVGrid(columns: statsColumns, spacing: 12) {
                    RetroStatCard(
                        label: "RAIDS",
                        value: "\(filterTodayClasses(academicWeek: calendarManager.currentTeachingWeek).count)",
                        color: .cyan
                    )
                    RetroStatCard(
                        label: "MANA",
                        value: "\(tasks.filter { !$0.isCompleted }.count)",
                        color: .blue
                    )
                    RetroStatCard(
                        label: "SKILLS",
                        value: "\(subjects.count)",
                        color: .purple
                    )
                }
                
                // 3. Active Cycle (Classes)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("> ACTIVE_CYCLE").font(.system(.headline, design: retroFont)).foregroundColor(.cyan)
                        Spacer()
                        NavigationLink(" [ LIST ] ") { SubjectsView() }
                            .font(.system(.caption, design: retroFont))
                            .foregroundColor(.cyan)
                            .border(Color.cyan, width: 1)
                    }
                    
                    let todaysClasses = filterTodayClasses(academicWeek: calendarManager.currentTeachingWeek)
                    
                    if todaysClasses.isEmpty {
                        Text("CYCLE_EMPTY. REST_MODE_ENGAGED.").font(.system(.caption, design: retroFont)).foregroundColor(.gray)
                    } else {
                        ForEach(todaysClasses) { subject in
                            HStack {
                                Text("[ ]").foregroundColor(.cyan)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(subject.title.uppercased()).font(.system(.subheadline, design: retroFont)).foregroundColor(.white)
                                    HStack {
                                        Text("ROOM: \(subject.courseClassroom)")
                                        Text("|")
                                        Text(subject.courseTimeString)
                                    }.font(.system(.caption2, design: retroFont)).foregroundColor(.gray)
                                }
                                Spacer()
                                if subject.occursThisWeek(academicWeek: calendarManager.currentTeachingWeek, isCourse: true) {
                                    Text("<CRS>").font(.system(.caption2, design: retroFont)).foregroundColor(.cyan)
                                } else {
                                    Text("<SEM>").font(.system(.caption2, design: retroFont)).foregroundColor(.orange)
                                }
                            }.padding(8).border(Color.cyan.opacity(0.5), width: 1)
                        }
                    }
                }
                
                // 4. Active Quests
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("> ACTIVE_QUESTS").font(.system(.headline, design: retroFont)).foregroundColor(.yellow)
                        Spacer()
                        NavigationLink(" [ LIST ] ") { TasksView() }
                            .font(.system(.caption, design: retroFont))
                            .foregroundColor(.yellow)
                            .border(Color.yellow, width: 1)
                    }
                    
                    let activeQuests = tasks.filter { !$0.isCompleted }.prefix(3)
                    if activeQuests.isEmpty {
                        Text("NO_DATA").font(.system(.caption, design: retroFont)).foregroundColor(.gray)
                    } else {
                        ForEach(activeQuests) { task in
                            HStack {
                                Text(task.isCompleted ? "[X]" : "[ ]").foregroundColor(.yellow)
                                VStack(alignment: .leading) {
                                    Text(task.title.uppercased()).font(.system(.subheadline, design: retroFont)).foregroundColor(.white)
                                    if !task.notes.isEmpty { Text(task.notes).font(.system(size: 8, design: retroFont)).foregroundColor(.gray) }
                                    HStack {
                                        if let s = task.subject { Text("SUB: \(s.title)") }
                                        if let d = task.dueDate { Text("DUE: \(formatDate(d))") }
                                    }.font(.system(size: 8, design: retroFont)).foregroundColor(.gray)
                                }
                                Spacer()
                                Text("EXP+").font(.system(size: 10, design: retroFont)).foregroundColor(.green)
                            }.padding(8).border(Color.yellow.opacity(0.5), width: 1)
                        }
                    }
                }
                
                // 5. Skill Trees (Performance)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("> SKILL_TREES").font(.system(.headline, design: retroFont)).foregroundColor(.purple)
                        Spacer()
                        NavigationLink(" [ LIST ] ") { SubjectsView() }
                            .font(.system(.caption, design: retroFont))
                            .foregroundColor(.purple)
                            .border(Color.purple, width: 1)
                    }
                    
                    ForEach(subjects.prefix(3)) { subject in
                        HStack {
                            Text("::").foregroundColor(.purple)
                            VStack(alignment: .leading) {
                                Text(subject.title.uppercased()).font(.system(.subheadline, design: retroFont)).foregroundColor(.white)
                                Text("INSTR: \(subject.courseTeacher.uppercased())").font(.system(.caption2, design: retroFont)).foregroundColor(.gray)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("LVL \(Int(subject.attendanceRate * 10))").font(.system(.caption, design: retroFont)).foregroundColor(.purple)
                                if let g = subject.currentGrade {
                                    Text("VAL: \(String(format: "%.1f", g))").font(.system(.caption2, design: retroFont)).foregroundColor(.green)
                                }
                            }
                        }
                        .padding(8)
                        .border(Color.purple.opacity(0.5), width: 1)
                    }
                }
            }
            .padding()
        }
        .background(Color(red: 0.05, green: 0.05, blue: 0.1).ignoresSafeArea())
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
    
    private func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.dateFormat = "MM-dd"; return f.string(from: date) }
}

// MARK: - LOCAL COMPONENTS

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
            
            // Standard Quick Attendance Button
            QuickAttendanceButton(subject: subject, color: .themePrimary, style: .standard)
                .frame(width: 44, height: 44)
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

// Compact Card for Horizontal Scroll
struct CompactPerformanceCard: View {
    let subject: Subject
    
    var body: some View {
        NavigationLink(destination: SubjectDetailView(subject: subject)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.themePrimary.opacity(0.1))
                            .frame(width: 32, height: 32)
                        Image(systemName: "book.fill")
                            .font(.caption)
                            .foregroundColor(.themePrimary)
                    }
                    Spacer()
                    if let grade = subject.currentGrade {
                        Text(String(format: "%.1f", grade))
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(gradeColor(grade).opacity(0.1))
                            .foregroundColor(gradeColor(grade))
                            .cornerRadius(4)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(subject.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.themeTextPrimary)
                        .lineLimit(1)
                    
                    Text(subject.courseTeacher)
                        .font(.caption)
                        .foregroundColor(.themeTextSecondary)
                        .lineLimit(1)
                }
                
                HStack {
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                    Text("\(Int(subject.attendanceRate * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.themeTextSecondary)
            }
            .padding(12)
            .frame(width: 150)
            .background(Color.themeSurface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.adaptiveBorder.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func gradeColor(_ grade: Double) -> Color {
        switch grade {
        case 9...10: return .themeSuccess
        case 7..<9: return .themePrimary
        case 5..<7: return .themeWarning
        default: return .themeError
        }
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
