import SwiftUI
import SwiftData

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
                case .retro:
                    RetroDashboard(subjects: subjects, tasks: tasks)
                case .none:
                    StandardDashboard(subjects: subjects, tasks: tasks)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme((themeManager.selectedGameMode == .arcade || themeManager.selectedGameMode == .retro || themeManager.selectedGameMode == .rainbow) ? .dark : nil)
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
    @State private var showGradeCalcPicker = false
    @State private var showAttendanceSheet = false
    @State private var showLogGradeSheet = false
    @State private var showAddSubject = false
    
    // Computed logic
    private var todaysSchedule: [TodayClassEvent] {
        DashboardLogic.getTodaysSchedule(subjects: subjects, academicWeek: calendarManager.currentTeachingWeek)
    }
    
    private var nextClass: TodayClassEvent? {
        DashboardLogic.getNextClass(from: todaysSchedule)
    }
    
    private var remainingClasses: [TodayClassEvent] {
        DashboardLogic.getRemainingClasses(from: todaysSchedule)
    }
    
    // Logic: "Exam Radar" items (High Priority or Exams)
    private var examItems: [StudyTask] {
        tasks.filter {
            !$0.isCompleted &&
            ($0.priority == .high || $0.title.localizedCaseInsensitiveContains("exam") || $0.title.localizedCaseInsensitiveContains("test") || $0.title.localizedCaseInsensitiveContains("midterm"))
        }
        .sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
    }
    
    // Logic: General "Priority Tasks" (Everything else or just Top 3)
    private var generalTasks: [StudyTask] {
        tasks.filter { !$0.isCompleted }
            .sorted {
                if $0.priority == $1.priority {
                    return ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture)
                }
                return $0.priority == .high // High first
            }
    }
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    
                    // 1. Header & Status
                    VStack(spacing: 24) {
                        CleanHeader()
                        SemesterStatusCard(
                            weekNumber: calendarManager.currentTeachingWeek ?? 1,
                            semesterName: calendarManager.currentSemester.displayName,
                            isEven: (calendarManager.currentTeachingWeek ?? 1) % 2 == 0
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // 2. Quick Buttons
                    SmartActionBelt(
                        onAddTask: { showAddTask = true },
                        onLogGrade: { showLogGradeSheet = true },
                        onFastAttendance: { showAttendanceSheet = true },
                        onGradeCalc: { showGradeCalcPicker = true }
                    )
                    .padding(.horizontal)
                    
                    // 3. Up Next (Hero)
                    if let next = nextClass {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Up Next")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            NextClassHero(event: next)
                                .padding(.horizontal)
                        }
                    } else if !todaysSchedule.isEmpty {
                        AllDoneCard().padding(.horizontal)
                    } else {
                        FreeDayCard().padding(.horizontal)
                    }
                    
                    // 4. Today's Remaining Classes
                    if !remainingClasses.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Later Today")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(remainingClasses) { event in
                                    RemainingClassRow(event: event)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // 5. Exam Radar (Restored)
                    if !examItems.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Exam Radar", systemImage: "exclamationmark.triangle.fill")
                                .font(.headline)
                                .foregroundColor(.themeError)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(examItems) { task in
                                        CleanExamCard(task: task)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // 6. Priority Tasks (General List)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Priority Tasks")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                            NavigationLink("View All") { TasksView() }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        
                        if generalTasks.isEmpty {
                            HomeEmptyStateView(icon: "checkmark.shield", title: "All Caught Up", message: "No pending tasks.")
                                .padding(.horizontal)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(generalTasks.prefix(3)) { task in
                                    CleanTaskRow(task: task)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // 7. Performance (Bottom)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Performance")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        if subjects.isEmpty {
                            Button(action: { showAddSubject = true }) {
                                Text("Add subjects to track performance")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.themeSurface)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(subjects) { subject in
                                        CleanSubjectCard(subject: subject)
                                    }
                                    
                                    Button(action: { showAddSubject = true }) {
                                        VStack {
                                            Image(systemName: "plus")
                                                .font(.title2)
                                                .foregroundColor(.blue)
                                            Text("Add")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.blue)
                                        }
                                        .frame(width: 100, height: 120)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(16)
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
        // Sheets
        .sheet(isPresented: $showAddTask) { NavigationStack { AddTaskView() } }
        .sheet(isPresented: $showLogGradeSheet) { QuickLogGradeSheet(subjects: subjects) }
        .sheet(isPresented: $showGradeCalcPicker) { GradeCalcSubjectPicker(subjects: subjects) }
        .sheet(isPresented: $showAttendanceSheet) { QuickAttendanceSheet(subjects: DashboardLogic.filterTodayClasses(subjects: subjects, academicWeek: calendarManager.currentTeachingWeek)) }
        .sheet(isPresented: $showAddSubject) { NavigationStack { AddSubjectView() } }
    }
}

// MARK: - 🎨 COMPONENTS

struct CleanHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingMessage)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text(Date().formatted(date: .complete, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            HStack(spacing: 12) {
                NavigationLink(destination: SettingsDashboardView()) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                        .padding(10)
                        .background(Color.themeSurface)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                NavigationLink(destination: ProfileView()) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
    }
    
    private var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
}

struct SemesterStatusCard: View {
    let weekNumber: Int
    let semesterName: String
    let isEven: Bool
    private var progress: Double { return Double(weekNumber) / 14.0 }
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle().stroke(Color.gray.opacity(0.2), lineWidth: 5).frame(width: 50, height: 50)
                Circle().trim(from: 0, to: progress)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(weekNumber)").font(.headline).fontWeight(.bold)
                    Text("Wk").font(.system(size: 9)).foregroundColor(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(semesterName).font(.subheadline).fontWeight(.semibold)
                HStack {
                    Text(isEven ? "Even Week" : "Odd Week")
                        .font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.indigo.opacity(0.1)).foregroundColor(.indigo).cornerRadius(6)
                    Text("\(Int(progress * 100))% Complete").font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(16).background(Color.themeSurface).cornerRadius(16).shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

struct SmartActionBelt: View {
    var onAddTask: () -> Void; var onLogGrade: () -> Void; var onFastAttendance: () -> Void; var onGradeCalc: () -> Void
    var body: some View {
        HStack(spacing: 0) {
            BeltButton(icon: "plus", label: "Task", color: .blue, action: onAddTask)
            Spacer()
            BeltButton(icon: "doc.badge.plus", label: "Grade", color: .orange, action: onLogGrade)
            Spacer()
            BeltButton(icon: "hand.raised.fill", label: "Attend", color: .green, action: onFastAttendance)
            Spacer()
            BeltButton(icon: "percent", label: "Calc", color: .purple, action: onGradeCalc)
        }
    }
    struct BeltButton: View {
        let icon: String; let label: String; let color: Color; let action: () -> Void
        var body: some View {
            Button(action: action) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle().fill(color.opacity(0.1)).frame(width: 56, height: 56)
                        Image(systemName: icon).font(.system(size: 22, weight: .semibold)).foregroundColor(color)
                    }
                    Text(label).font(.caption).fontWeight(.medium).foregroundColor(.primary)
                }
            }
        }
    }
}

struct NextClassHero: View {
    let event: TodayClassEvent
    var body: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text(formatTime(event.startTime)).font(.title3).fontWeight(.bold).foregroundColor(.white)
                Text(formatTime(event.endTime)).font(.caption).foregroundColor(.gray)
            }
            Rectangle().fill(Color.white.opacity(0.3)).frame(width: 1, height: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(event.subject.title).font(.headline).foregroundColor(.white).lineLimit(1)
                HStack {
                    Image(systemName: "mappin.and.ellipse").font(.caption)
                    Text(event.room).font(.caption)
                }.foregroundColor(.gray)
            }
            Spacer()
            VStack {
                Image(systemName: event.type.icon).font(.title2).foregroundColor(event.type.color)
                Text(event.timerPhraseShort).font(.system(size: 9, weight: .bold)).foregroundColor(event.type.color).padding(.top, 2)
            }
        }
        .padding(20).background(Color.black.opacity(0.9)).cornerRadius(20).shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short; return f.string(from: date)
    }
}

struct RemainingClassRow: View {
    let event: TodayClassEvent
    var body: some View {
        HStack(spacing: 16) {
            Text(formatTime(event.startTime))
                .font(.subheadline).fontWeight(.medium).foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.subject.title).font(.body).fontWeight(.semibold).foregroundColor(.primary)
                Text(event.room).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: event.type.icon).foregroundColor(event.type.color)
        }
        .padding()
        .background(Color.themeSurface)
        .cornerRadius(12)
    }
    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short; return f.string(from: date)
    }
}

struct CleanExamCard: View {
    let task: StudyTask
    var daysLeft: Int {
        guard let due = task.dueDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: due).day ?? 0
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(daysLeft <= 1 ? "URGENT" : "\(daysLeft) DAYS")
                    .font(.system(size: 10, weight: .black)).foregroundColor(.white)
                    .padding(.horizontal, 8).padding(.vertical, 4).background(Color.red).cornerRadius(8)
                Spacer()
            }
            Text(task.title).font(.headline).foregroundColor(.primary).lineLimit(2)
            if let subject = task.subject { Text(subject.title).font(.caption).foregroundColor(.secondary) }
        }
        .padding(16).frame(width: 160, height: 120).background(Color.themeSurface).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.red.opacity(0.1), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct CleanTaskRow: View {
    @Bindable var task: StudyTask
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { withAnimation { task.isCompleted.toggle() } }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2).foregroundColor(task.isCompleted ? .green : .secondary)
            }.buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title).font(.subheadline).fontWeight(.medium).strikethrough(task.isCompleted).foregroundColor(task.isCompleted ? .secondary : .primary)
                HStack {
                    if let subject = task.subject {
                        Text(subject.title).font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1)).foregroundColor(.blue).cornerRadius(4)
                    }
                    if task.priority == .high {
                        Text("High Priority").font(.caption2).foregroundColor(.red)
                    }
                }
            }
            Spacer()
        }
        .padding().background(Color.themeSurface).cornerRadius(12)
        .opacity(task.isCompleted ? 0.6 : 1.0)
    }
}

struct CleanSubjectCard: View {
    let subject: Subject
    var body: some View {
        NavigationLink(destination: SubjectDetailView(subject: subject)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle().fill(Color.blue.opacity(0.1)).frame(width: 36, height: 36)
                        Image(systemName: "book.fill").font(.caption).foregroundColor(.blue)
                    }
                    Spacer()
                    if let grade = subject.currentGrade {
                        Text(String(format: "%.1f", grade)).font(.subheadline).fontWeight(.bold).foregroundColor(grade >= 5 ? .green : .red)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(subject.title).font(.headline).foregroundColor(.primary).lineLimit(1)
                    Text(subject.courseTeacher).font(.caption).foregroundColor(.secondary).lineLimit(1)
                }
            }
            .padding(16).frame(width: 150, height: 120).background(Color.themeSurface).cornerRadius(16).shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        }.buttonStyle(PlainButtonStyle())
    }
}

struct FreeDayCard: View {
    var body: some View {
        HStack {
            Image(systemName: "sun.max.fill").font(.title).foregroundColor(.orange)
            VStack(alignment: .leading) {
                Text("Free Day").font(.headline).foregroundColor(.primary)
                Text("No classes today.").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }.padding().background(Color.themeSurface).cornerRadius(16)
    }
}

struct HomeEmptyStateView: View {
    let icon: String; let title: String; let message: String
    var body: some View {
        HStack {
            Image(systemName: icon).font(.title2).foregroundColor(.secondary)
            VStack(alignment: .leading) {
                Text(title).font(.headline).foregroundColor(.primary)
                Text(message).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }.padding().background(Color.themeSurface).cornerRadius(12)
    }
}

struct AllDoneCard: View {
    var body: some View {
        HStack {
            Image(systemName: "moon.stars.fill").font(.title).foregroundColor(.indigo)
            VStack(alignment: .leading) {
                Text("All Clear").font(.headline).foregroundColor(.primary)
                Text("No more classes today.").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }.padding().background(Color.themeSurface).cornerRadius(16)
    }
}

// MARK: - 📱 SHEETS
struct QuickLogGradeSheet: View {
    let subjects: [Subject]; @Environment(\.dismiss) var dismiss; @Environment(\.modelContext) var modelContext
    @State private var selectedSubject: Subject?; @State private var gradeValue = ""; @State private var weightValue = "100"
    var body: some View {
        NavigationStack {
            Form {
                Section("Subject") { Picker("Select", selection: $selectedSubject) { Text("None").tag(nil as Subject?); ForEach(subjects) { Text($0.title).tag($0 as Subject?) } } }
                if selectedSubject != nil {
                    Section("Grade") { TextField("Value (1-10)", text: $gradeValue).keyboardType(.decimalPad); TextField("Weight %", text: $weightValue).keyboardType(.numberPad) }
                    Button("Save") {
                        let g = Double(gradeValue.replacingOccurrences(of: ",", with: ".")) ?? 0
                        let w = Double(weightValue) ?? 100
                        let entry = GradeEntry(date: Date(), grade: g, weight: w, description: "Quick Log")
                        entry.subject = selectedSubject
                        modelContext.insert(entry)
                        dismiss()
                    }.disabled(gradeValue.isEmpty)
                }
            }.navigationTitle("Log Grade").toolbar { Button("Cancel") { dismiss() } }
        }
    }
}

struct GradeCalcSubjectPicker: View {
    let subjects: [Subject]; @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            List(subjects) { sub in NavigationLink(destination: WhatIfGradeView(subject: sub)) { Text(sub.title) } }
            .navigationTitle("Calculator").toolbar { Button("Close") { dismiss() } }
        }
    }
}

struct QuickAttendanceSheet: View {
    let subjects: [Subject]; @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            List(subjects) { sub in
                HStack { Text(sub.title); Spacer(); QuickAttendanceButton(subject: sub) }
            }.navigationTitle("Attendance").toolbar { Button("Done") { dismiss() } }
        }.presentationDetents([.medium])
    }
}

struct QuickAttendanceButton: View {
    @Bindable var subject: Subject; @Environment(\.modelContext) var modelContext
    var isAttended: Bool { let cal = Calendar.current; return subject.attendanceHistory?.contains { cal.isDate($0.date, inSameDayAs: Date()) } ?? false }
    var body: some View {
        Button(action: toggle) { Image(systemName: isAttended ? "checkmark.circle.fill" : "plus.circle").font(.title2).foregroundColor(isAttended ? .green : .blue) }
    }
    func toggle() {
        let cal = Calendar.current; let today = Date()
        if isAttended, let idx = subject.attendanceHistory?.firstIndex(where: { cal.isDate($0.date, inSameDayAs: today) }), let entry = subject.attendanceHistory?[idx] { modelContext.delete(entry) }
        else { let e = AttendanceEntry(date: today, attended: true, notes: "Quick"); e.subject = subject; modelContext.insert(e) }
    }
}

// MARK: - LOGIC & GAME MODES
struct TodayClassEvent: Identifiable {
    let id = UUID(); let subject: Subject; let type: ClassType; let startTime: Date; let endTime: Date; let room: String
    var timerPhraseShort: String {
        let diff = startTime.timeIntervalSinceNow
        if diff <= 0 { return Date() < endTime ? "NOW" : "DONE" }
        return "IN \(Int(diff / 60)) MIN"
    }
}
struct DashboardLogic {
    static func getTodaysSchedule(subjects: [Subject], academicWeek: Int?) -> [TodayClassEvent] {
        let cal = Calendar.current; let today = Date(); let weekday = cal.component(.weekday, from: today); var events: [TodayClassEvent] = []
        for s in subjects {
            if s.courseDays.contains(weekday), s.occursThisWeek(academicWeek: academicWeek, isCourse: true), let start = combine(today, s.courseStartTime), let end = combine(today, s.courseEndTime) { events.append(TodayClassEvent(subject: s, type: .course, startTime: start, endTime: end, room: s.courseClassroom)) }
            if s.seminarDays.contains(weekday), s.occursThisWeek(academicWeek: academicWeek, isCourse: false), let start = combine(today, s.seminarStartTime), let end = combine(today, s.seminarEndTime) { events.append(TodayClassEvent(subject: s, type: .seminar, startTime: start, endTime: end, room: s.seminarClassroom)) }
        }
        return events.sorted { $0.startTime < $1.startTime }
    }
    static func getNextClass(from schedule: [TodayClassEvent]) -> TodayClassEvent? { return schedule.first { $0.endTime > Date() } }
    static func getRemainingClasses(from schedule: [TodayClassEvent]) -> [TodayClassEvent] {
        guard let next = getNextClass(from: schedule) else { return [] }
        return schedule.filter { $0.startTime > next.startTime }
    }
    static func filterTodayClasses(subjects: [Subject], academicWeek: Int?) -> [Subject] {
        let ids = Set(getTodaysSchedule(subjects: subjects, academicWeek: academicWeek).map { $0.subject.id }); return subjects.filter { ids.contains($0.id) }
    }
    static func combine(_ d: Date, _ t: Date) -> Date? { let c = Calendar.current; let tc = c.dateComponents([.hour, .minute], from: t); return c.date(bySettingHour: tc.hour ?? 0, minute: tc.minute ?? 0, second: 0, of: d) }
}
struct RainbowDashboard: View { let subjects: [Subject]; let tasks: [StudyTask]; var body: some View { Text("Rainbow") } }
struct ArcadeDashboard: View { let subjects: [Subject]; let tasks: [StudyTask]; var body: some View { Text("Arcade") } }
struct RetroDashboard: View { let subjects: [Subject]; let tasks: [StudyTask]; var body: some View { Text("Retro") } }
