import SwiftUI
import SwiftData
import Combine

struct HomeView: View {
    @EnvironmentObject var themeManager: AppTheme
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    
    // Fetch data
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
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme((themeManager.selectedGameMode == .arcade || themeManager.selectedGameMode == .rainbow) ? .dark : nil)
    }
}

// MARK: - 🌈 RAINBOW DASHBOARD
struct RainbowDashboard: View {
    let subjects: [Subject]
    let tasks: [StudyTask]
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @EnvironmentObject var themeManager: AppTheme
    
    // Sheets
    @State private var showAddTask = false
    @State private var showAttendanceSheet = false
    @State private var showLogGradeSheet = false
    @State private var showStudyTimer = false
    @State private var showAddSubject = false
    
    // Logic
    private var todaysSchedule: [TodayClassEvent] { DashboardLogic.getTodaysSchedule(subjects: subjects) }
    private var nextClass: TodayClassEvent? { DashboardLogic.getNextClass(from: todaysSchedule) }
    private var remainingClasses: [TodayClassEvent] { DashboardLogic.getRemainingClasses(from: todaysSchedule) }
    
    private var examItems: [StudyTask] {
        tasks.filter {
            !$0.isCompleted && ($0.priority == .high || $0.title.localizedCaseInsensitiveContains("exam"))
        }.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }
    
    private var generalTasks: [StudyTask] {
        tasks.filter { !$0.isCompleted }
            .sorted {
                if $0.priority == $1.priority {
                    return ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture)
                }
                return $0.priority == .high
            }
    }
    
    var body: some View {
        // Capture Accent Color
        let accent = themeManager.selectedTheme.primaryColor
        
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // 1. Header
                    RainbowHeaderView()
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    // 2. Status & Progress
                    RainbowSemesterStatus(
                        week: calendarManager.currentTeachingWeek ?? 1,
                        semester: calendarManager.currentSemester.displayName,
                        accentColor: accent
                    )
                    .padding(.horizontal)
                    
                    // 3. Quick Actions
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            RainbowActionButton(icon: "plus", label: "Task", color: RainbowColors.blue) { showAddTask = true }
                            RainbowActionButton(icon: "doc.fill", label: "Grade", color: RainbowColors.orange) { showLogGradeSheet = true }
                            RainbowActionButton(icon: "hand.raised.fill", label: "Attend", color: RainbowColors.green) { showAttendanceSheet = true }
                            RainbowActionButton(icon: "hourglass", label: "Focus", color: RainbowColors.purple) { showStudyTimer = true }
                        }
                        .padding(.horizontal)
                    }
                    
                    // 4. Up Next & Remaining Classes
                    VStack(alignment: .leading, spacing: 12) {
                        if let next = nextClass {
                            Text("SCHEDULE")
                                .font(.caption).fontWeight(.black)
                                .foregroundColor(accent)
                                .padding(.horizontal)
                            
                            RainbowNextClassCard(event: next, accentColor: accent)
                                .padding(.horizontal)
                            
                            if !remainingClasses.isEmpty {
                                VStack(spacing: 10) {
                                    ForEach(remainingClasses) { event in
                                        RainbowRemainingRow(event: event)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        } else if !todaysSchedule.isEmpty {
                            RainbowStatusCard(icon: "moon.stars.fill", title: "All Done", subtitle: "No more classes today", color: accent)
                                .padding(.horizontal)
                        } else {
                            RainbowStatusCard(icon: "sun.max.fill", title: "Free Day", subtitle: "Relax and recharge", color: RainbowColors.orange)
                                .padding(.horizontal)
                        }
                    }
                    
                    // 5. Exam Radar
                    if !examItems.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("RADAR")
                                .font(.caption).fontWeight(.black)
                                .foregroundColor(RainbowColors.red)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(examItems) { task in
                                        RainbowExamCard(task: task)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // 6. Priority Tasks
                    if !generalTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("TASKS")
                                    .font(.caption).fontWeight(.black)
                                    .foregroundColor(accent)
                                Spacer()
                                NavigationLink("VIEW ALL") { TasksView() }
                                    .font(.caption).fontWeight(.bold).foregroundColor(.gray)
                            }
                            .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(generalTasks.prefix(3)) { task in
                                    RainbowTaskRow(task: task, accentColor: accent)
                                }
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        RainbowStatusCard(icon: "checkmark.shield.fill", title: "All Caught Up", subtitle: "No pending tasks", color: RainbowColors.green)
                            .padding(.horizontal)
                    }
                    
                    // 7. Performance
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("PERFORMANCE")
                                .font(.caption).fontWeight(.black)
                                .foregroundColor(accent)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        if subjects.isEmpty {
                            Button(action: { showAddSubject = true }) {
                                Text("Add subjects to track stats")
                                    .font(.caption).fontWeight(.bold)
                                    .foregroundColor(.gray)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color(white: 0.1))
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(subjects) { subject in
                                        RainbowSubjectStatsCard(subject: subject)
                                    }
                                    
                                    Button(action: { showAddSubject = true }) {
                                        VStack {
                                            Image(systemName: "plus")
                                                .font(.title2)
                                                .foregroundColor(accent)
                                            Text("Add")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.gray)
                                        }
                                        .frame(width: 100, height: 130)
                                        .background(Color(white: 0.1))
                                        .cornerRadius(20)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
            }
        }
        .sheet(isPresented: $showAddTask) { AddTaskView() }
        .sheet(isPresented: $showLogGradeSheet) { QuickLogGradeSheet(subjects: subjects) }
        .sheet(isPresented: $showAttendanceSheet) { QuickAttendanceSheet(subjects: DashboardLogic.filterTodayClasses(subjects: subjects)) }
        .sheet(isPresented: $showStudyTimer) { StudySessionView() }
        .sheet(isPresented: $showAddSubject) { AddSubjectView() }
    }
}

// MARK: - 🏠 STANDARD DASHBOARD
struct StandardDashboard: View {
    let subjects: [Subject]
    let tasks: [StudyTask]
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @EnvironmentObject var themeManager: AppTheme
    
    // Sheets state
    @State private var showAddTask = false
    @State private var showAttendanceSheet = false
    @State private var showLogGradeSheet = false
    @State private var showStudyTimer = false
    @State private var showAddSubject = false
    
    private var todaysSchedule: [TodayClassEvent] { DashboardLogic.getTodaysSchedule(subjects: subjects) }
    private var nextClass: TodayClassEvent? { DashboardLogic.getNextClass(from: todaysSchedule) }
    private var remainingClasses: [TodayClassEvent] { DashboardLogic.getRemainingClasses(from: todaysSchedule) }
    
    private var examItems: [StudyTask] {
        tasks.filter {
            !$0.isCompleted &&
            ($0.priority == .high || $0.title.localizedCaseInsensitiveContains("exam") || $0.title.localizedCaseInsensitiveContains("test"))
        }.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
    }
    
    private var generalTasks: [StudyTask] {
        tasks.filter { !$0.isCompleted }
            .sorted {
                if $0.priority == $1.priority {
                    return ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture)
                }
                return $0.priority == .high
            }
    }
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 24) {
                        CleanHeader()
                        SemesterStatusCard(
                            weekNumber: calendarManager.currentTeachingWeek ?? 1,
                            semesterName: calendarManager.currentSemester.displayName,
                            isEven: (calendarManager.currentTeachingWeek ?? 1) % 2 == 0,
                            accent: themeManager.selectedTheme.primaryColor
                        )
                    }.padding(.horizontal).padding(.top, 10)
                    
                    // Buttons
                    SmartActionBelt(onAddTask: { showAddTask = true }, onLogGrade: { showLogGradeSheet = true }, onFastAttendance: { showAttendanceSheet = true }, onFocus: { showStudyTimer = true }).padding(.horizontal)
                    
                    // Up Next
                    if let next = nextClass {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Up Next").font(.headline).foregroundColor(.secondary).padding(.horizontal)
                            NextClassHero(event: next).padding(.horizontal)
                        }
                    } else if !todaysSchedule.isEmpty { AllDoneCard().padding(.horizontal) } else { FreeDayCard().padding(.horizontal) }
                    
                    // Remaining
                    if !remainingClasses.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Later Today").font(.headline).foregroundColor(.secondary).padding(.horizontal)
                            VStack(spacing: 12) { ForEach(remainingClasses) { event in RemainingClassRow(event: event) } }.padding(.horizontal)
                        }
                    }
                    
                    // Exam Radar
                    if !examItems.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Exam Radar", systemImage: "exclamationmark.triangle.fill").font(.headline).foregroundColor(.themeError).padding(.horizontal)
                            ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 16) { ForEach(examItems) { task in CleanExamCard(task: task) } }.padding(.horizontal) }
                        }
                    }
                    
                    // Tasks
                    VStack(alignment: .leading, spacing: 12) {
                        HStack { Text("Priority Tasks").font(.headline).foregroundColor(.secondary); Spacer(); NavigationLink("View All") { TasksView() }.font(.subheadline).foregroundColor(themeManager.selectedTheme.primaryColor) }.padding(.horizontal)
                        if generalTasks.isEmpty { HomeEmptyStateView(icon: "checkmark.shield", title: "All Caught Up", message: "No pending tasks.").padding(.horizontal) }
                        else { VStack(spacing: 12) { ForEach(generalTasks.prefix(3)) { task in CleanTaskRow(task: task) } }.padding(.horizontal) }
                    }
                    
                    // Performance
                    VStack(alignment: .leading, spacing: 16) {
                        HStack { Text("Performance").font(.headline).foregroundColor(.primary); Spacer() }.padding(.horizontal)
                        if subjects.isEmpty {
                            Button(action: { showAddSubject = true }) { Text("Add subjects to track performance").font(.caption).foregroundColor(.secondary).padding().frame(maxWidth: .infinity).background(Color.themeSurface).cornerRadius(12) }.padding(.horizontal)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(subjects) { subject in CleanSubjectCard(subject: subject) }
                                    Button(action: { showAddSubject = true }) { VStack { Image(systemName: "plus").font(.title2).foregroundColor(themeManager.selectedTheme.primaryColor); Text("Add").font(.caption).fontWeight(.bold).foregroundColor(themeManager.selectedTheme.primaryColor) }.frame(width: 100, height: 120).background(themeManager.selectedTheme.primaryColor.opacity(0.1)).cornerRadius(16) }
                                }.padding(.horizontal)
                            }
                        }
                    }
                    Spacer(minLength: 100)
                }
            }
        }
        .sheet(isPresented: $showAddTask) { NavigationStack { AddTaskView() } }
        .sheet(isPresented: $showLogGradeSheet) { QuickLogGradeSheet(subjects: subjects) }
        .sheet(isPresented: $showAttendanceSheet) { QuickAttendanceSheet(subjects: DashboardLogic.filterTodayClasses(subjects: subjects)) }
        .sheet(isPresented: $showStudyTimer) { StudySessionView() }
        .sheet(isPresented: $showAddSubject) { NavigationStack { AddSubjectView() } }
    }
}

// MARK: - 🌈 RAINBOW COMPONENTS

struct RainbowHeaderView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("HELLO STUDENT").font(.system(size: 10, weight: .black)).foregroundColor(.gray)
                Text(Date().formatted(date: .complete, time: .omitted).uppercased()).font(.title3).fontWeight(.black).foregroundColor(.white)
            }
            Spacer()
            NavigationLink(destination: SettingsDashboardView()) { Image(systemName: "gearshape.fill").font(.title2).foregroundColor(.white).padding(10).background(Color(white: 0.15)).clipShape(Circle()) }
        }
    }
}

struct RainbowSemesterStatus: View {
    let week: Int
    let semester: String
    let accentColor: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(semester.uppercased()).font(.caption).fontWeight(.bold).foregroundColor(.gray)
                Text("WEEK \(week)")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundStyle(LinearGradient(colors: [accentColor, accentColor.opacity(0.6)], startPoint: .leading, endPoint: .trailing))
            }
            Spacer()
            ZStack {
                Circle().stroke(Color(white: 0.1), lineWidth: 8).frame(width: 60, height: 60)
                Circle().trim(from: 0, to: Double(week)/14.0)
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                Text("\(Int((Double(week)/14.0)*100))%")
                    .font(.caption2).fontWeight(.bold).foregroundColor(.white)
            }
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(20)
    }
}

struct RainbowNextClassCard: View {
    let event: TodayClassEvent
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .center, spacing: 4) {
                if event.startTime > Date() {
                    Text(event.startTime, style: .timer).font(.title3).fontWeight(.black).foregroundColor(.white).monospacedDigit()
                    Text("STARTS IN").font(.system(size: 8, weight: .bold)).foregroundColor(accentColor)
                } else {
                    Text("NOW").font(.title3).fontWeight(.black).foregroundColor(.white)
                    Text("HAPPENING").font(.system(size: 8, weight: .bold)).foregroundColor(RainbowColors.orange)
                }
            }.frame(minWidth: 80)
            Rectangle().fill(Color(white: 0.2)).frame(width: 1, height: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(event.subject.title).font(.headline).fontWeight(.bold).foregroundColor(.white)
                HStack { Image(systemName: "mappin.circle.fill").foregroundColor(.gray); Text(event.room).font(.subheadline).foregroundColor(.gray) }
            }
            Spacer()
            Image(systemName: event.type == .course ? "book.fill" : "person.2.fill")
                .font(.title).foregroundColor(event.subject.color).opacity(0.8)
        }
        .padding(24)
        .background(Color(white: 0.1))
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(LinearGradient(colors: [accentColor.opacity(0.6), accentColor.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2))
    }
}

struct RainbowTaskRow: View {
    @Bindable var task: StudyTask
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { withAnimation { task.isCompleted.toggle() } }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(task.isCompleted ? accentColor : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title).font(.body).fontWeight(.medium).strikethrough(task.isCompleted).foregroundColor(task.isCompleted ? .gray : .white)
                HStack {
                    if let subject = task.subject { Text(subject.title).font(.caption2).fontWeight(.bold).foregroundColor(subject.color) }
                    if task.priority == .high { Text("HIGH").font(.caption2).fontWeight(.black).foregroundColor(RainbowColors.red) }
                }
            }
            Spacer()
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(16)
        .opacity(task.isCompleted ? 0.6 : 1.0)
    }
}

// ... Rest of Rainbow Components ...

struct RainbowActionButton: View {
    let icon: String; let label: String; let color: Color; let action: () -> Void
    var body: some View { Button(action: action) { HStack { Image(systemName: icon); Text(label) }.font(.system(size: 14, weight: .bold)).foregroundColor(.black).padding(.vertical, 12).padding(.horizontal, 20).background(color).cornerRadius(30) } }
}

struct RainbowRemainingRow: View {
    let event: TodayClassEvent
    var body: some View { HStack(spacing: 16) { Text(formatTime(event.startTime)).font(.subheadline).fontWeight(.bold).foregroundColor(.gray).frame(width: 60, alignment: .leading); VStack(alignment: .leading, spacing: 2) { Text(event.subject.title).font(.body).fontWeight(.bold).foregroundColor(.white); Text(event.room).font(.caption).foregroundColor(.gray) }; Spacer(); Image(systemName: event.type == .course ? "book.fill" : "person.2.fill").foregroundColor(event.subject.color) }.padding().background(Color(white: 0.1)).cornerRadius(16) }
    private func formatTime(_ date: Date) -> String { let f = DateFormatter(); f.timeStyle = .short; return f.string(from: date) }
}

struct RainbowSubjectStatsCard: View {
    let subject: Subject
    var body: some View {
        NavigationLink(destination: SubjectDetailView(subject: subject)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack { ZStack { Circle().fill(subject.color.opacity(0.2)).frame(width: 40, height: 40); Image(systemName: "book.fill").font(.caption).foregroundColor(subject.color) }; Spacer(); if let grade = subject.currentGrade { Text(String(format: "%.1f", grade)).font(.title3).fontWeight(.black).foregroundColor(grade >= 5 ? RainbowColors.green : RainbowColors.red) } }
                VStack(alignment: .leading, spacing: 4) { Text(subject.title).font(.headline).fontWeight(.bold).foregroundColor(.white).lineLimit(1); Text("Attd: \(Int(subject.attendanceRate * 100))%").font(.caption).fontWeight(.bold).foregroundColor(.gray) }
            }.padding(16).frame(width: 150, height: 130).background(Color(white: 0.1)).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(subject.color.opacity(0.3), lineWidth: 1))
        }
    }
}

struct RainbowStatusCard: View { let icon: String; let title: String; let subtitle: String; let color: Color; var body: some View { HStack(spacing: 16) { Image(systemName: icon).font(.largeTitle).foregroundColor(color); VStack(alignment: .leading) { Text(title).font(.headline).fontWeight(.bold).foregroundColor(.white); Text(subtitle).font(.caption).foregroundColor(.gray) }; Spacer() }.padding(20).background(Color(white: 0.1)).cornerRadius(20) } }
struct RainbowExamCard: View { let task: StudyTask; var body: some View { VStack(alignment: .leading, spacing: 12) { HStack { Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.black); Spacer(); if let due = task.dueDate { Text(due.formatted(.dateTime.day().month())).font(.caption).fontWeight(.bold).foregroundColor(.black) } }; Text(task.title).font(.headline).fontWeight(.black).foregroundColor(.black).lineLimit(2); Text(task.subject?.title ?? "General").font(.caption).fontWeight(.bold).foregroundColor(.black.opacity(0.7)) }.padding(16).frame(width: 160, height: 120).background(LinearGradient(colors: [RainbowColors.orange, RainbowColors.red], startPoint: .topLeading, endPoint: .bottomTrailing)).cornerRadius(20) } }

// MARK: - STANDARD COMPONENTS (Restored)

struct CleanHeader: View {
    @EnvironmentObject var themeManager: AppTheme
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingMessage).font(.largeTitle).fontWeight(.bold).foregroundColor(.primary)
                Text(Date().formatted(date: .complete, time: .omitted)).font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
            HStack(spacing: 12) {
                NavigationLink(destination: SettingsDashboardView()) { Image(systemName: "gearshape").font(.system(size: 20)).foregroundColor(.primary).padding(10).background(Color.themeSurface).clipShape(Circle()).shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2) }
                NavigationLink(destination: ProfileView()) { Image(systemName: "person.crop.circle").font(.system(size: 24)).foregroundColor(themeManager.selectedTheme.primaryColor).padding(8).background(themeManager.selectedTheme.primaryColor.opacity(0.1)).clipShape(Circle()) }
            }
        }
    }
    private var greetingMessage: String { let h = Calendar.current.component(.hour, from: Date()); return h < 12 ? "Good Morning" : h < 17 ? "Good Afternoon" : "Good Evening" }
}

struct SemesterStatusCard: View {
    let weekNumber: Int; let semesterName: String; let isEven: Bool; let accent: Color
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle().stroke(Color.gray.opacity(0.2), lineWidth: 5).frame(width: 50, height: 50)
                Circle().trim(from: 0, to: Double(weekNumber)/14.0).stroke(accent, style: StrokeStyle(lineWidth: 5, lineCap: .round)).frame(width: 50, height: 50).rotationEffect(.degrees(-90))
                VStack(spacing: 0) { Text("\(weekNumber)").font(.headline).fontWeight(.bold); Text("Wk").font(.system(size: 9)).foregroundColor(.secondary) }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(semesterName).font(.subheadline).fontWeight(.semibold)
                HStack {
                    Text(isEven ? "Even Week" : "Odd Week").font(.caption).padding(.horizontal, 8).padding(.vertical, 4).background(accent.opacity(0.1)).foregroundColor(accent).cornerRadius(6)
                    Text("\(Int((Double(weekNumber)/14.0)*100))% Complete").font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
        }.padding(16).background(Color.themeSurface).cornerRadius(16).shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

struct SmartActionBelt: View {
    var onAddTask: () -> Void; var onLogGrade: () -> Void; var onFastAttendance: () -> Void; var onFocus: () -> Void
    var body: some View { HStack(spacing: 0) { BeltButton(icon: "plus", label: "Task", color: .blue, action: onAddTask); Spacer(); BeltButton(icon: "doc.badge.plus", label: "Grade", color: .orange, action: onLogGrade); Spacer(); BeltButton(icon: "hand.raised.fill", label: "Attend", color: .green, action: onFastAttendance); Spacer(); BeltButton(icon: "hourglass", label: "Focus", color: .indigo, action: onFocus) } }
    struct BeltButton: View { let icon: String; let label: String; let color: Color; let action: () -> Void; var body: some View { Button(action: action) { VStack(spacing: 8) { ZStack { Circle().fill(color.opacity(0.1)).frame(width: 56, height: 56); Image(systemName: icon).font(.system(size: 22, weight: .semibold)).foregroundColor(color) }; Text(label).font(.caption).fontWeight(.medium).foregroundColor(.primary) } } } }
}

struct NextClassHero: View {
    let event: TodayClassEvent
    var body: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                if event.startTime > Date() { Text(event.startTime, style: .timer).font(.title3).fontWeight(.bold).foregroundColor(.white).monospacedDigit(); Text("until start").font(.caption2).foregroundColor(.gray) }
                else { Text("Now").font(.title3).fontWeight(.bold).foregroundColor(.white); Text("ends \(formatTime(event.endTime))").font(.caption).foregroundColor(.gray) }
            }.frame(minWidth: 80)
            Rectangle().fill(Color.white.opacity(0.3)).frame(width: 1, height: 40)
            VStack(alignment: .leading, spacing: 4) { Text(event.subject.title).font(.headline).foregroundColor(.white).lineLimit(1); HStack { Image(systemName: "mappin.and.ellipse").font(.caption); Text(event.room).font(.caption) }.foregroundColor(.gray) }; Spacer()
            VStack { Image(systemName: event.type.icon).font(.title2).foregroundColor(event.type.color); Text(event.timerPhraseShort).font(.system(size: 9, weight: .bold)).foregroundColor(event.type.color).padding(.top, 2) }
        }.padding(20).background(Color.black.opacity(0.9)).cornerRadius(20).shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    private func formatTime(_ date: Date) -> String { let f = DateFormatter(); f.timeStyle = .short; return f.string(from: date) }
}

struct RemainingClassRow: View {
    let event: TodayClassEvent
    var body: some View { HStack(spacing: 16) { Text(formatTime(event.startTime)).font(.subheadline).fontWeight(.medium).foregroundColor(.secondary).frame(width: 60, alignment: .leading); VStack(alignment: .leading, spacing: 2) { Text(event.subject.title).font(.body).fontWeight(.semibold).foregroundColor(.primary); Text(event.room).font(.caption).foregroundColor(.secondary) }; Spacer(); Image(systemName: event.type.icon).foregroundColor(event.type.color) }.padding().background(Color.themeSurface).cornerRadius(12) }
    private func formatTime(_ date: Date) -> String { let f = DateFormatter(); f.timeStyle = .short; return f.string(from: date) }
}

struct CleanExamCard: View {
    let task: StudyTask
    var daysLeft: Int { guard let due = task.dueDate else { return 0 }; return Calendar.current.dateComponents([.day], from: Date(), to: due).day ?? 0 }
    var body: some View { VStack(alignment: .leading, spacing: 10) { HStack { Text(daysLeft <= 1 ? "URGENT" : "\(daysLeft) DAYS").font(.system(size: 10, weight: .black)).foregroundColor(.white).padding(.horizontal, 8).padding(.vertical, 4).background(Color.red).cornerRadius(8); Spacer() }; Text(task.title).font(.headline).foregroundColor(.primary).lineLimit(2); if let subject = task.subject { Text(subject.title).font(.caption).foregroundColor(.secondary) } }.padding(16).frame(width: 160, height: 120).background(Color.themeSurface).cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.red.opacity(0.1), lineWidth: 1)).shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2) }
}

struct CleanTaskRow: View {
    @Bindable var task: StudyTask
    @EnvironmentObject var themeManager: AppTheme
    var body: some View { HStack(spacing: 12) { Button(action: { withAnimation { task.isCompleted.toggle() } }) { Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle").font(.title2).foregroundColor(task.isCompleted ? .green : .secondary) }.buttonStyle(PlainButtonStyle()); VStack(alignment: .leading, spacing: 4) { Text(task.title).font(.subheadline).fontWeight(.medium).strikethrough(task.isCompleted).foregroundColor(task.isCompleted ? .secondary : .primary); HStack { if let subject = task.subject { Text(subject.title).font(.caption2).padding(.horizontal, 6).padding(.vertical, 2).background(themeManager.selectedTheme.primaryColor.opacity(0.1)).foregroundColor(themeManager.selectedTheme.primaryColor).cornerRadius(4) }; if task.priority == .high { Text("High Priority").font(.caption2).foregroundColor(.red) } } }; Spacer() }.padding().background(Color.themeSurface).cornerRadius(12).opacity(task.isCompleted ? 0.6 : 1.0) }
}

struct CleanSubjectCard: View {
    let subject: Subject; @EnvironmentObject var themeManager: AppTheme
    var body: some View { NavigationLink(destination: SubjectDetailView(subject: subject)) { VStack(alignment: .leading, spacing: 12) { HStack { ZStack { Circle().fill(themeManager.selectedTheme.primaryColor.opacity(0.1)).frame(width: 36, height: 36); Image(systemName: "book.fill").font(.caption).foregroundColor(themeManager.selectedTheme.primaryColor) }; Spacer(); if let grade = subject.currentGrade { Text(String(format: "%.1f", grade)).font(.subheadline).fontWeight(.bold).foregroundColor(grade >= 5 ? .green : .red) } }; VStack(alignment: .leading, spacing: 4) { Text(subject.title).font(.headline).foregroundColor(.primary).lineLimit(1); Text(subject.courseTeacher).font(.caption).foregroundColor(.secondary).lineLimit(1) } }.padding(16).frame(width: 150, height: 120).background(Color.themeSurface).cornerRadius(16).shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2) }.buttonStyle(PlainButtonStyle()) }
}

struct FreeDayCard: View { var body: some View { HStack { Image(systemName: "sun.max.fill").font(.title).foregroundColor(.orange); VStack(alignment: .leading) { Text("Free Day").font(.headline).foregroundColor(.primary); Text("No classes today.").font(.caption).foregroundColor(.secondary) }; Spacer() }.padding().background(Color.themeSurface).cornerRadius(16) } }
struct HomeEmptyStateView: View { let icon: String; let title: String; let message: String; var body: some View { HStack { Image(systemName: icon).font(.title2).foregroundColor(.secondary); VStack(alignment: .leading) { Text(title).font(.headline).foregroundColor(.primary); Text(message).font(.caption).foregroundColor(.secondary) }; Spacer() }.padding().background(Color.themeSurface).cornerRadius(12) } }
struct AllDoneCard: View { var body: some View { HStack { Image(systemName: "moon.stars.fill").font(.title).foregroundColor(.indigo); VStack(alignment: .leading) { Text("All Clear").font(.headline).foregroundColor(.primary); Text("No more classes today.").font(.caption).foregroundColor(.secondary) }; Spacer() }.padding().background(Color.themeSurface).cornerRadius(16) } }

// MARK: - ⏱️ STUDY TIMER SHEET
struct StudySessionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var timerManager: StudyTimerManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Picker("Mode", selection: Binding(get: { timerManager.selectedMode }, set: { timerManager.setMode($0) })) { Text("Focus").tag(0); Text("Short Break").tag(1); Text("Long Break").tag(2) }.pickerStyle(.segmented).padding(.horizontal).disabled(timerManager.isRunning)
                ZStack { Circle().stroke(Color.gray.opacity(0.2), lineWidth: 20); Circle().trim(from: 0, to: timerManager.progress).stroke(Color.indigo, style: StrokeStyle(lineWidth: 20, lineCap: .round)).rotationEffect(.degrees(-90)).animation(.linear(duration: 1), value: timerManager.timeRemaining); VStack { Text(timeString(time: timerManager.timeRemaining)).font(.system(size: 60, weight: .bold, design: .monospaced)); Text(timerManager.isRunning ? "STAY FOCUSED" : "PAUSED").font(.caption).fontWeight(.bold).foregroundColor(.secondary) } }.padding(40)
                HStack(spacing: 30) {
                    Button(action: { if timerManager.isRunning { timerManager.pause() } else { timerManager.start() } }) { Image(systemName: timerManager.isRunning ? "pause.fill" : "play.fill").font(.title).foregroundColor(.white).frame(width: 70, height: 70).background(Color.indigo).clipShape(Circle()).shadow(radius: 5) }
                    Button(action: { timerManager.reset() }) { Image(systemName: "arrow.counterclockwise").font(.title).foregroundColor(.indigo).frame(width: 70, height: 70).background(Color.indigo.opacity(0.1)).clipShape(Circle()) }
                }
                Spacer()
                if timerManager.isRunning { Button("Continue in Background") { dismiss() }.font(.subheadline).foregroundColor(.secondary).padding(.bottom) }
            }.navigationTitle("Study Timer").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } } }
        }
    }
    private func timeString(time: TimeInterval) -> String { let minutes = Int(time) / 60; let seconds = Int(time) % 60; return String(format: "%02d:%02d", minutes, seconds) }
}

// MARK: - 📱 HELPER SHEETS
struct QuickLogGradeSheet: View {
    let subjects: [Subject]; @Environment(\.dismiss) var dismiss; @Environment(\.modelContext) var modelContext
    @State private var selectedSubject: Subject?; @State private var gradeValue = ""; @State private var weightValue = "100"
    var body: some View { NavigationStack { Form { Section("Subject") { Picker("Select", selection: $selectedSubject) { Text("None").tag(nil as Subject?); ForEach(subjects) { Text($0.title).tag($0 as Subject?) } } }; if selectedSubject != nil { Section("Grade") { TextField("Value", text: $gradeValue).keyboardType(.decimalPad); TextField("Weight %", text: $weightValue).keyboardType(.numberPad) }; Button("Save") { save() }.disabled(gradeValue.isEmpty) } }.navigationTitle("Log Grade").toolbar { Button("Cancel") { dismiss() } } } }
    func save() { let g = Double(gradeValue.replacingOccurrences(of: ",", with: ".")) ?? 0; let w = Double(weightValue) ?? 100; let e = GradeEntry(date: Date(), grade: g, weight: w, description: "Quick Log"); e.subject = selectedSubject; modelContext.insert(e); dismiss() }
}

struct GradeCalcSubjectPicker: View {
    let subjects: [Subject]; @Environment(\.dismiss) var dismiss
    var body: some View { NavigationStack { List(subjects) { sub in NavigationLink(destination: WhatIfGradeView(subject: sub)) { Text(sub.title) } }.navigationTitle("Calculator").toolbar { Button("Close") { dismiss() } } } }
}

struct QuickAttendanceSheet: View {
    let subjects: [Subject]; @Environment(\.dismiss) var dismiss
    var body: some View { NavigationStack { List(subjects) { sub in HStack { Text(sub.title); Spacer(); QuickAttendanceButton(subject: sub) } }.navigationTitle("Attendance").toolbar { Button("Done") { dismiss() } } }.presentationDetents([.medium]) }
}

struct QuickAttendanceButton: View {
    @Bindable var subject: Subject; @Environment(\.modelContext) var modelContext
    var isAttended: Bool { let cal = Calendar.current; let att = subject.attendance ?? []; return att.contains { cal.isDate($0.date, inSameDayAs: Date()) } }
    var body: some View { Button(action: toggle) { Image(systemName: isAttended ? "checkmark.circle.fill" : "plus.circle").font(.title2).foregroundColor(isAttended ? .green : .blue) } }
    func toggle() { let cal = Calendar.current; let today = Date(); if isAttended, let att = subject.attendance, let idx = att.firstIndex(where: { cal.isDate($0.date, inSameDayAs: today) }) { modelContext.delete(att[idx]) } else { let e = AttendanceEntry(date: today, status: .present, note: "Quick"); e.subject = subject; modelContext.insert(e) } }
}

// MARK: - LOGIC
struct TodayClassEvent: Identifiable {
    let id = UUID(); let subject: Subject; let type: ClassType; let startTime: Date; let endTime: Date; let room: String
    var timerPhraseShort: String { let diff = startTime.timeIntervalSinceNow; if diff <= 0 { return Date() < endTime ? "NOW" : "DONE" }; let minutes = Int(diff / 60); return "IN \(minutes) MIN" }
}

struct DashboardLogic {
    static func getTodaysSchedule(subjects: [Subject]) -> [TodayClassEvent] {
        let cal = Calendar.current; let today = Date(); let weekday = cal.component(.weekday, from: today); var events: [TodayClassEvent] = []
        for s in subjects {
            if s.courseDays.contains(weekday), s.occursThisWeek(date: today, isSeminar: false), let start = combine(today, s.courseStartTime), let end = combine(today, s.courseEndTime) { events.append(TodayClassEvent(subject: s, type: .course, startTime: start, endTime: end, room: s.courseClassroom)) }
            if s.seminarDays.contains(weekday), s.occursThisWeek(date: today, isSeminar: true), let start = combine(today, s.seminarStartTime), let end = combine(today, s.seminarEndTime) { events.append(TodayClassEvent(subject: s, type: .seminar, startTime: start, endTime: end, room: s.seminarClassroom)) }
        }
        return events.sorted { $0.startTime < $1.startTime }
    }
    static func getNextClass(from schedule: [TodayClassEvent]) -> TodayClassEvent? { return schedule.first { $0.endTime > Date() } }
    static func getRemainingClasses(from schedule: [TodayClassEvent]) -> [TodayClassEvent] { guard let next = getNextClass(from: schedule) else { return [] }; return schedule.filter { $0.startTime > next.startTime } }
    static func filterTodayClasses(subjects: [Subject]) -> [Subject] { let events = getTodaysSchedule(subjects: subjects); let ids = Set(events.map { $0.subject.id }); return subjects.filter { ids.contains($0.id) } }
    static func combine(_ d: Date, _ t: Date) -> Date? { let c = Calendar.current; let tc = c.dateComponents([.hour, .minute], from: t); return c.date(bySettingHour: tc.hour ?? 0, minute: tc.minute ?? 0, second: 0, of: d) }
}

struct ArcadeDashboard: View { let subjects: [Subject]; let tasks: [StudyTask]; var body: some View { Text("Arcade Mode Active").foregroundColor(.cyan).padding().background(Color.black) } }
