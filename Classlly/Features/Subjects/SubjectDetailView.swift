import SwiftUI
import Combine
import SwiftData

// MARK: - MAIN SWITCHER
struct SubjectDetailView: View {
    @EnvironmentObject var themeManager: AppTheme
    @Bindable var subject: Subject
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .arcade:
                ArcadeSubjectDetailView(subject: subject)
            case .retro:
                RetroSubjectDetailView(subject: subject)
            case .rainbow:
                RainbowSubjectDetailView(subject: subject)
            case .none:
                StandardSubjectDetailView(subject: subject)
            }
        }
    }
}

// MARK: - 🌈 RAINBOW DETAIL VIEW
struct RainbowSubjectDetailView: View {
    @Bindable var subject: Subject
    @EnvironmentObject var themeManager: AppTheme
    @Environment(\.modelContext) private var modelContext
    
    @Query private var tasks: [StudyTask]
    private var subjectTasks: [StudyTask] { tasks.filter { $0.subject == subject } }
    
    @State private var showingAddGrade = false
    @State private var showingMarkAttendance = false
    @State private var showingAddTask = false
    @State private var showingEditSubject = false
    
    init(subject: Subject) {
        self.subject = subject
        let subjectID = subject.id
        _tasks = Query(filter: #Predicate { $0.subject?.id == subjectID })
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 50))
                            .foregroundColor(RainbowColors.blue)
                        
                        Text(subject.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text(subject.courseTeacher)
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    // Info Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        RainbowContainer {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Course", systemImage: "clock.fill")
                                    .font(.headline)
                                    .foregroundColor(RainbowColors.blue)
                                Text(subject.courseTimeString).foregroundColor(.white)
                                Text(subject.courseClassroom).foregroundColor(.gray)
                            }
                        }
                        
                        RainbowContainer {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Seminar", systemImage: "person.2.fill")
                                    .font(.headline)
                                    .foregroundColor(RainbowColors.green)
                                if subject.seminarTeacher.isEmpty {
                                    Text("None").foregroundColor(.gray)
                                } else {
                                    Text(subject.seminarTimeString).foregroundColor(.white)
                                    Text(subject.seminarClassroom).foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Stats
                    RainbowContainer {
                        HStack(spacing: 30) {
                            VStack {
                                Text("\(Int(subject.attendanceRate * 100))%")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("Attendance").font(.caption).foregroundColor(.gray)
                            }
                            
                            Divider().background(Color.gray)
                            
                            VStack {
                                Text(String(format: "%.1f", subject.currentGrade ?? 0))
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("Average").font(.caption).foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    
                    // Tasks
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Active Tasks").font(.title3).bold().foregroundColor(.white).padding(.horizontal)
                        
                        if subjectTasks.isEmpty {
                            Text("No tasks for this subject.").foregroundColor(.gray).padding(.horizontal)
                        } else {
                            ForEach(subjectTasks) { task in
                                RainbowContainer {
                                    HStack {
                                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(RainbowColors.orange)
                                        Text(task.title).foregroundColor(.white).strikethrough(task.isCompleted)
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { showingAddGrade = true } label: { Label("Add Grade", systemImage: "graduationcap") }
                    Button { showingMarkAttendance = true } label: { Label("Mark Attendance", systemImage: "checkmark.circle") }
                    Button { showingAddTask = true } label: { Label("Add Task", systemImage: "plus.circle") }
                    Button { showingEditSubject = true } label: { Label("Edit Subject", systemImage: "pencil") }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title3)
                        .foregroundColor(RainbowColors.blue)
                }
            }
        }
        .sheet(isPresented: $showingAddGrade) { AddGradeSheet(isPresented: $showingAddGrade) { d, g, desc in let new = GradeEntry(date: d, grade: g, description: desc); new.subject = subject; modelContext.insert(new) } }
        .sheet(isPresented: $showingMarkAttendance) { MarkAttendanceSheet(isPresented: $showingMarkAttendance) { d, a, n in let new = AttendanceEntry(date: d, attended: a, notes: n); new.subject = subject; modelContext.insert(new) } }
        .sheet(isPresented: $showingAddTask) { AddTaskView(preSelectedSubject: subject) }
        .sheet(isPresented: $showingEditSubject) { EditSubjectView(subject: subject) }
    }
}

// ... (Rest of Standard/Arcade/Retro views unchanged)
// [Omitting for brevity]
struct StandardSubjectDetailView: View {
    @Bindable var subject: Subject
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showingAddGrade = false
    @State private var showingMarkAttendance = false
    @State private var showingAddTask = false
    @State private var showingEditSubject = false
    @State private var showingDeleteAlert = false
    @State private var editingGrade: GradeEntry?
    @State private var editingAttendance: AttendanceEntry?
    @State private var selectedTab = 0
    
    @Query private var tasks: [StudyTask]
    private var subjectTasks: [StudyTask] { tasks.filter { $0.subject == subject } }
    
    private var averageGrade: Double? {
        let grades = subject.gradeHistory ?? []
        guard !grades.isEmpty else { return nil }
        let total = grades.reduce(0.0) { $0 + $1.grade }
        return total / Double(grades.count)
    }
    
    private var formattedAverageGrade: String {
        if let grade = averageGrade {
            return String(format: "%.1f", grade)
        }
        return "N/A"
    }
    
    private var gradeTrend: (icon: String, color: Color, description: String) {
        let grades = subject.gradeHistory ?? []
        guard grades.count >= 2 else { return ("minus.circle", .gray, "No trend data") }
        let sortedGrades = grades.sorted { $0.date > $1.date }
        
        guard sortedGrades.count >= 2,
              let first = sortedGrades.first?.grade,
              let second = sortedGrades.dropFirst().first?.grade else {
             return ("minus.circle", .gray, "No trend data")
        }
        
        let diff = first - second
        if diff > 0.3 { return ("arrow.up.circle.fill", .themeSuccess, "Improving") }
        else if diff < -0.3 { return ("arrow.down.circle.fill", .themeError, "Declining") }
        else { return ("minus.circle", .themeTextSecondary, "Stable") }
    }
    
    init(subject: Subject) {
        self.subject = subject
        let subjectID = subject.id
        _tasks = Query(filter: #Predicate { $0.subject?.id == subjectID })
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                headerView
                courseInfoSection
                if hasSeminar { seminarInfoSection }
                quickActionsSection
                performanceSection
                tabsSection
            }
        }
        .background(Color.themeBackground)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) { showingDeleteAlert = true } label: { Image(systemName: "trash") }
            }
        }
        .sheet(isPresented: $showingAddGrade) { AddGradeSheet(isPresented: $showingAddGrade) { d, g, desc in let new = GradeEntry(date: d, grade: g, description: desc); new.subject = subject; modelContext.insert(new) } }
        .sheet(isPresented: $showingMarkAttendance) { MarkAttendanceSheet(isPresented: $showingMarkAttendance) { d, a, n in let new = AttendanceEntry(date: d, attended: a, notes: n); new.subject = subject; modelContext.insert(new) } }
        .sheet(isPresented: $showingAddTask) { AddTaskView(preSelectedSubject: subject) }
        .sheet(isPresented: $showingEditSubject) { EditSubjectView(subject: subject) }
        .sheet(item: $editingGrade) { grade in EditGradeSheet(gradeEntry: grade) { updated in if let idx = subject.gradeHistory?.firstIndex(where: { $0.id == updated.id }) { subject.gradeHistory?[idx].date = updated.date; subject.gradeHistory?[idx].grade = updated.grade; subject.gradeHistory?[idx].descriptionText = updated.descriptionText } } }
        .sheet(item: $editingAttendance) { attendance in EditAttendanceSheet(attendanceEntry: attendance) { updated in if let idx = subject.attendanceHistory?.firstIndex(where: { $0.id == updated.id }) { subject.attendanceHistory?[idx].date = updated.date; subject.attendanceHistory?[idx].attended = updated.attended; subject.attendanceHistory?[idx].notes = updated.notes } } }
        .alert("Delete", isPresented: $showingDeleteAlert) { Button("Delete", role: .destructive) { modelContext.delete(subject); dismiss() }; Button("Cancel", role: .cancel) { } }
    }
    
    private var hasSeminar: Bool {
        !subject.seminarTeacher.isEmpty || !subject.seminarClassroom.isEmpty
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [.themePrimary, .themeSecondary]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.themePrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                    Image(systemName: "book.fill").font(.system(size: 40, weight: .medium)).foregroundColor(.white)
                }
                VStack(spacing: 8) {
                    Text(subject.title).font(.title2).fontWeight(.bold).foregroundColor(.themeTextPrimary).multilineTextAlignment(.center)
                    Text("Course: \(subject.courseTeacher)").font(.subheadline).foregroundColor(.themeTextSecondary).multilineTextAlignment(.center)
                    
                    if !subject.courseDaysString.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar").font(.caption2).foregroundColor(.themePrimary)
                            Text(subject.courseDaysString).font(.caption).foregroundColor(.themeTextSecondary)
                            Image(systemName: "clock").font(.caption2).foregroundColor(.themePrimary)
                            Text(subject.courseTimeString).font(.caption).foregroundColor(.themeTextSecondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 24).padding(.horizontal, 20).frame(maxWidth: .infinity).background(Color.themeSurface)
        .cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.adaptiveBorder.opacity(0.3), lineWidth: 1)).padding(16)
    }
    
    private var courseInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Course Details", icon: "book.closed.fill").padding(.horizontal)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                DetailInfoCard(icon: "person.fill", title: "Teacher", value: subject.courseTeacher)
                DetailInfoCard(icon: "mappin.circle.fill", title: "Room", value: subject.courseClassroom)
                DetailInfoCard(icon: "clock.fill", title: "Time", value: subject.courseTimeString)
                DetailInfoCard(icon: "calendar", title: "Days", value: subject.courseDaysString)
            }
            .padding(.horizontal)
        }.padding(.vertical)
    }
    
    private var seminarInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Seminar Details", icon: "person.2.fill").padding(.horizontal)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                DetailInfoCard(icon: "person.fill", title: "Teacher", value: subject.seminarTeacher)
                DetailInfoCard(icon: "mappin.circle.fill", title: "Room", value: subject.seminarClassroom)
                DetailInfoCard(icon: "clock.fill", title: "Time", value: subject.seminarTimeString)
                DetailInfoCard(icon: "calendar", title: "Days", value: subject.seminarDaysString)
            }
            .padding(.horizontal)
        }.padding(.vertical)
    }
    
    private var quickActionsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ActionButton(icon: "plus.circle.fill", title: "Grade", subtitle: "Add", color: .themePrimary) { showingAddGrade = true }
                ActionButton(icon: "checkmark.circle.fill", title: "Attend", subtitle: "Mark", color: .themeSuccess) { showingMarkAttendance = true }
                ActionButton(icon: "plus.circle.fill", title: "Task", subtitle: "Add", color: .themeWarning) { showingAddTask = true }
                ActionButton(icon: "pencil", title: "Edit", subtitle: "Details", color: .themeSecondary) { showingEditSubject = true }
            }
            .padding(.horizontal)
        }.padding(.vertical)
    }
    
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Overview").font(.headline).padding(.horizontal)
            HStack(spacing: 12) {
                PerformanceCard(title: "Average Grade", value: formattedAverageGrade, subtitle: averageGrade != nil ? "/10 • \(subject.gradeHistory?.count ?? 0) grades" : "No grades", color: .themePrimary, icon: "star.fill", progress: (averageGrade ?? 0) / 10, trendIcon: gradeTrend.icon, trendColor: gradeTrend.color)
                PerformanceCard(title: "Attendance", value: "\(Int(subject.attendanceRate * 100))%", subtitle: "\(subject.attendedClasses)/\(subject.totalClasses) classes", color: .themeSuccess, icon: "person.2.fill", progress: subject.attendanceRate)
            }
            .padding(.horizontal)
        }.padding(.vertical)
    }
    
    private func standardTabButton(title: String, index: Int) -> some View {
        Button(action: { selectedTab = index }) {
            VStack(spacing: 8) {
                Text(title).font(.subheadline).fontWeight(selectedTab == index ? .semibold : .medium).foregroundColor(selectedTab == index ? .themePrimary : .themeTextSecondary)
                Rectangle().fill(selectedTab == index ? Color.themePrimary : Color.clear).frame(height: 2)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var tabsSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                standardTabButton(title: "Grades", index: 0)
                standardTabButton(title: "Attendance", index: 1)
                standardTabButton(title: "Tasks", index: 2)
            }
            .padding(.horizontal).padding(.top, 24).background(Color.themeSurface)
            
            selectedTabContent
        }
    }
    
    @ViewBuilder
    private var selectedTabContent: some View {
        switch selectedTab {
        case 0: gradeHistoryList
        case 1: attendanceHistoryList
        default: tasksList
        }
    }
    
    private var gradeHistoryList: some View {
        VStack(alignment: .leading, spacing: 16) {
            if (subject.gradeHistory ?? []).isEmpty {
                SubjectEmptyStateView(icon: "chart.line.uptrend.xyaxis", title: "No Grades", message: "Add your first grade.").padding()
            } else {
                LazyVStack(spacing: 1) {
                    ForEach((subject.gradeHistory ?? []).sorted(by: { $0.date > $1.date })) { grade in
                        GradeHistoryRow(grade: grade, averageGrade: averageGrade).padding(.horizontal).padding(.vertical, 12).background(Color.themeSurface).contentShape(Rectangle()).onTapGesture { editingGrade = grade }
                    }
                }
                .background(Color.themeSurface)
            }
        }.padding(.vertical)
    }
    
    private var attendanceHistoryList: some View {
        VStack(alignment: .leading, spacing: 16) {
            if (subject.attendanceHistory ?? []).isEmpty {
                SubjectEmptyStateView(icon: "calendar", title: "No Records", message: "Mark attendance to track it.").padding()
            } else {
                LazyVStack(spacing: 1) {
                    ForEach((subject.attendanceHistory ?? []).sorted(by: { $0.date > $1.date })) { attendance in
                        AttendanceHistoryRow(attendance: attendance).padding(.horizontal).padding(.vertical, 12).background(Color.themeSurface).contentShape(Rectangle()).onTapGesture { editingAttendance = attendance }
                    }
                }
                .background(Color.themeSurface)
            }
        }.padding(.vertical)
    }
    
    private var tasksList: some View {
        VStack(alignment: .leading, spacing: 16) {
            if subjectTasks.isEmpty {
                SubjectEmptyStateView(icon: "checklist", title: "No Tasks", message: "Add tasks for this subject.").padding()
            } else {
                LazyVStack(spacing: 1) {
                    ForEach(subjectTasks) { task in
                        NavigationLink(destination: EditTaskView(task: task)) {
                            TaskRowPreview(title: task.title, subject: task.subject?.title ?? "General", dueDate: task.dueDate != nil ? formatDate(task.dueDate!) : "No date", isCompleted: task.isCompleted).padding(.horizontal).padding(.vertical, 12).background(Color.themeSurface)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .background(Color.themeSurface)
            }
        }.padding(.vertical)
    }
    
    private func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: date) }
}

struct ArcadeSubjectDetailView: View {
    @Bindable var subject: Subject
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var showingAddGrade = false
    @State private var showingMarkAttendance = false
    @State private var showingAddTask = false
    @State private var showingEditSubject = false
    @State private var selectedTab = 0
    
    @Query private var tasks: [StudyTask]
    private var subjectTasks: [StudyTask] { tasks.filter { $0.subject == subject } }
    
    init(subject: Subject) {
        self.subject = subject
        let subjectID = subject.id
        _tasks = Query(filter: #Predicate { $0.subject?.id == subjectID })
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    arcadeHeader
                    missionIntelSection
                    if hasSeminar { sideQuestIntelSection }
                    statsGrid
                    quickActions
                    tabSwitcher
                    selectedTabContent
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddGrade) { AddGradeSheet(isPresented: $showingAddGrade) { d, g, desc in let new = GradeEntry(date: d, grade: g, description: desc); new.subject = subject; modelContext.insert(new) } }
        .sheet(isPresented: $showingMarkAttendance) { MarkAttendanceSheet(isPresented: $showingMarkAttendance) { d, a, n in let new = AttendanceEntry(date: d, attended: a, notes: n); new.subject = subject; modelContext.insert(new) } }
        .sheet(isPresented: $showingAddTask) { AddTaskView(preSelectedSubject: subject) }
        .sheet(isPresented: $showingEditSubject) { EditSubjectView(subject: subject) }
    }
    
    private var hasSeminar: Bool { !subject.seminarTeacher.isEmpty || !subject.seminarClassroom.isEmpty }
    
    private var arcadeHeader: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing).mask(RoundedRectangle(cornerRadius: 24))
            VStack(spacing: 12) {
                Image(systemName: "bolt.fill").font(.system(size: 40)).foregroundColor(.yellow).shadow(color: .yellow, radius: 10)
                Text(subject.title.uppercased()).font(.system(.title2, design: .rounded)).fontWeight(.black).foregroundColor(.white)
                Text("SKILL LEVEL \(Int(subject.attendanceRate * 10))").font(.caption).fontWeight(.bold).padding(6).background(Color.black.opacity(0.3)).cornerRadius(8).foregroundColor(.white)
            }
            .padding(30)
        }
        .shadow(color: .purple.opacity(0.5), radius: 10).padding()
    }
    
    private var missionIntelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MISSION INTEL").font(.system(.caption, design: .rounded)).fontWeight(.black).foregroundColor(.cyan).padding(.horizontal)
            HStack(spacing: 12) {
                ArcadeInfoCell(label: "MENTOR", value: subject.courseTeacher, icon: "person.fill")
                ArcadeInfoCell(label: "SECTOR", value: subject.courseClassroom, icon: "mappin.and.ellipse")
            }.padding(.horizontal)
            HStack(spacing: 12) {
                ArcadeInfoCell(label: "TIME WINDOW", value: subject.courseTimeString, icon: "clock.fill")
                ArcadeInfoCell(label: "CYCLE", value: subject.courseDaysString, icon: "calendar")
            }.padding(.horizontal)
        }
    }
    
    private var sideQuestIntelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SIDE QUEST INTEL").font(.system(.caption, design: .rounded)).fontWeight(.black).foregroundColor(.orange).padding(.horizontal)
            HStack(spacing: 12) {
                ArcadeInfoCell(label: "MENTOR", value: subject.seminarTeacher, icon: "person.fill")
                ArcadeInfoCell(label: "SECTOR", value: subject.seminarClassroom, icon: "mappin.and.ellipse")
            }.padding(.horizontal)
            HStack(spacing: 12) {
                ArcadeInfoCell(label: "TIME WINDOW", value: subject.seminarTimeString, icon: "clock.fill")
                ArcadeInfoCell(label: "CYCLE", value: subject.seminarDaysString, icon: "calendar")
            }.padding(.horizontal)
        }
    }
    
    private var statsGrid: some View {
        HStack(spacing: 16) {
            ArcadeStatPill(icon: "star.fill", value: String(format: "%.1f", subject.currentGrade ?? 0), label: "Mastery", gradient: Gradient(colors: [.orange, .red]))
            ArcadeStatPill(icon: "person.fill", value: "\(Int(subject.attendanceRate * 100))%", label: "Sync Rate", gradient: Gradient(colors: [.blue, .cyan]))
        }.padding(.horizontal)
    }
    
    private var quickActions: some View {
        HStack(spacing: 12) {
            ArcadeActionButton(icon: "plus", label: "XP", color: .green) { showingAddGrade = true }
            ArcadeActionButton(icon: "checkmark", label: "SYNC", color: .cyan) { showingMarkAttendance = true }
            ArcadeActionButton(icon: "exclamationmark", label: "QUEST", color: .yellow) { showingAddTask = true }
            ArcadeActionButton(icon: "gear", label: "CONFIG", color: .gray) { showingEditSubject = true }
        }.padding(.horizontal)
    }
    
    private var tabSwitcher: some View {
        HStack {
            ForEach(["XP LOG", "SYNC LOG", "QUESTS"], id: \.self) { tab in
                let index = ["XP LOG", "SYNC LOG", "QUESTS"].firstIndex(of: tab) ?? 0
                Button(action: { selectedTab = index }) {
                    Text(tab).font(.system(.caption, design: .rounded)).fontWeight(.bold)
                        .padding(.vertical, 8).padding(.horizontal, 16)
                        .background(selectedTab == index ? Color.purple : Color(white: 0.1))
                        .foregroundColor(.white).cornerRadius(20)
                }
            }
        }.padding(.top)
    }
    
    @ViewBuilder
    private var selectedTabContent: some View {
        Group {
            if selectedTab == 0 {
                VStack(spacing: 12) {
                    if (subject.gradeHistory ?? []).isEmpty { Text("NO XP RECORDED").font(.caption).foregroundColor(.gray).padding() }
                    ForEach((subject.gradeHistory ?? []).sorted(by: { $0.date > $1.date })) { grade in
                        HStack {
                            Text(String(format: "%.1f", grade.grade)).font(.title3).fontWeight(.black).foregroundColor(.yellow)
                            VStack(alignment: .leading) {
                                Text(grade.descriptionText.isEmpty ? "XP GAIN" : grade.descriptionText).font(.caption).fontWeight(.bold).foregroundColor(.white)
                                Text(formatDate(grade.date)).font(.caption2).foregroundColor(.gray)
                            }
                            Spacer()
                        }.padding().background(Color(white: 0.1)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.yellow.opacity(0.3), lineWidth: 1))
                    }
                }.padding(.horizontal)
            } else if selectedTab == 1 {
                VStack(spacing: 12) {
                    if (subject.attendanceHistory ?? []).isEmpty { Text("NO SYNC DATA").font(.caption).foregroundColor(.gray).padding() }
                    ForEach((subject.attendanceHistory ?? []).sorted(by: { $0.date > $1.date })) { att in
                        HStack {
                            Image(systemName: att.attended ? "checkmark.circle.fill" : "xmark.circle.fill").foregroundColor(att.attended ? .green : .red)
                            Text(att.attended ? "SYNC COMPLETE" : "SYNC FAILED").font(.caption).fontWeight(.bold).foregroundColor(.white)
                            Spacer()
                            Text(formatDate(att.date)).font(.caption2).foregroundColor(.gray)
                        }.padding().background(Color(white: 0.1)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(att.attended ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1))
                    }
                }.padding(.horizontal)
            } else {
                VStack(spacing: 12) {
                    if subjectTasks.isEmpty { Text("NO ACTIVE QUESTS").font(.caption).foregroundColor(.gray).padding() }
                    ForEach(subjectTasks) { task in
                        HStack {
                            Image(systemName: task.isCompleted ? "checkmark.circle" : "circle").foregroundColor(.cyan)
                            Text(task.title).font(.caption).fontWeight(.bold).foregroundColor(.white).strikethrough(task.isCompleted)
                            Spacer()
                            if let d = task.dueDate { Text(formatDate(d)).font(.caption2).foregroundColor(.gray) }
                        }.padding().background(Color(white: 0.1)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cyan.opacity(0.3), lineWidth: 1))
                    }
                }.padding(.horizontal)
            }
        }.padding(.bottom, 40)
    }
    
    private func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.dateFormat = "MMM d"; return f.string(from: date) }
}

struct RetroSubjectDetailView: View {
    @Bindable var subject: Subject
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var showingAddGrade = false
    @State private var showingMarkAttendance = false
    @State private var showingAddTask = false
    @State private var showingEditSubject = false
    @State private var selectedTab = 0
    
    @Query private var tasks: [StudyTask]
    private var subjectTasks: [StudyTask] { tasks.filter { $0.subject == subject } }
    
    init(subject: Subject) {
        self.subject = subject
        let subjectID = subject.id
        _tasks = Query(filter: #Predicate { $0.subject?.id == subjectID })
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.05).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    retroHeader
                    courseMetadata
                    if hasSeminar { seminarMetadata }
                    statsMatrix
                    actionMatrix
                    databaseTabs
                    databaseLists
                }.padding()
            }
        }
        .sheet(isPresented: $showingAddGrade) { AddGradeSheet(isPresented: $showingAddGrade) { d, g, desc in let new = GradeEntry(date: d, grade: g, description: desc); new.subject = subject; modelContext.insert(new) } }
        .sheet(isPresented: $showingMarkAttendance) { MarkAttendanceSheet(isPresented: $showingMarkAttendance) { d, a, n in let new = AttendanceEntry(date: d, attended: a, notes: n); new.subject = subject; modelContext.insert(new) } }
        .sheet(isPresented: $showingAddTask) { AddTaskView(preSelectedSubject: subject) }
        .sheet(isPresented: $showingEditSubject) { EditSubjectView(subject: subject) }
    }
    
    private var hasSeminar: Bool { !subject.seminarTeacher.isEmpty || !subject.seminarClassroom.isEmpty }
    
    private var retroHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("> LOADING_FILE: \(subject.title.uppercased())").font(.system(.headline, design: .monospaced)).foregroundColor(.green)
            Rectangle().frame(height: 1).foregroundColor(.green)
        }
    }
    
    private var courseMetadata: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("COURSE_METADATA:").font(.system(.caption, design: .monospaced)).foregroundColor(.gray)
            RetroInfoRow(label: "INSTRUCTOR", value: subject.courseTeacher)
            RetroInfoRow(label: "COORDS", value: subject.courseClassroom)
            RetroInfoRow(label: "CYCLE", value: subject.courseDaysString)
            RetroInfoRow(label: "TIME_SLOT", value: subject.courseTimeString)
        }.padding().border(Color.green.opacity(0.5), width: 1)
    }
    
    private var seminarMetadata: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SEMINAR_METADATA:").font(.system(.caption, design: .monospaced)).foregroundColor(.gray)
            RetroInfoRow(label: "INSTRUCTOR", value: subject.seminarTeacher)
            RetroInfoRow(label: "COORDS", value: subject.seminarClassroom)
            RetroInfoRow(label: "CYCLE", value: subject.seminarDaysString)
            RetroInfoRow(label: "TIME_SLOT", value: subject.seminarTimeString)
        }.padding().border(Color.green.opacity(0.5), width: 1)
    }
    
    private var statsMatrix: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("STATS_MATRIX:").font(.system(.caption, design: .monospaced)).foregroundColor(.gray)
            HStack { Text("GRADE_VAL:"); Spacer(); Text(String(format: "%.1f / 10.0", subject.currentGrade ?? 0)) }.font(.system(.body, design: .monospaced)).foregroundColor(.green)
            HStack { Text("ATTENDANCE:"); Spacer(); Text("\(Int(subject.attendanceRate * 100))%") }.font(.system(.body, design: .monospaced)).foregroundColor(.green)
        }.padding().border(Color.green.opacity(0.5), width: 1)
    }
    
    private var actionMatrix: some View {
        VStack(spacing: 8) {
            HStack {
                RetroButton(label: "[ INPUT_GRADE ]") { showingAddGrade = true }
                RetroButton(label: "[ MARK_ATTEND ]") { showingMarkAttendance = true }
            }
            HStack {
                RetroButton(label: "[ NEW_TASK ]") { showingAddTask = true }
                RetroButton(label: "[ MODIFY_FILE ]", color: .yellow) { showingEditSubject = true }
            }
        }
    }
    
    private var databaseTabs: some View {
        HStack(spacing: 0) {
            ForEach(["FILE_A:GRD", "FILE_B:ATT", "FILE_C:TSK"], id: \.self) { tab in
                let index = ["FILE_A:GRD", "FILE_B:ATT", "FILE_C:TSK"].firstIndex(of: tab) ?? 0
                Button(action: { selectedTab = index }) {
                    Text(tab).font(.system(.caption, design: .monospaced)).padding(8)
                        .background(selectedTab == index ? Color.green : Color.clear)
                        .foregroundColor(selectedTab == index ? .black : .green).border(Color.green, width: 1)
                }
            }
        }.padding(.top)
    }
    
    private var databaseLists: some View {
        VStack(alignment: .leading, spacing: 8) {
            if selectedTab == 0 {
                Text("> READING_GRADE_DATA...").font(.caption).fontDesign(.monospaced).foregroundColor(.gray)
                if (subject.gradeHistory ?? []).isEmpty { Text("NULL_DATA").fontDesign(.monospaced).foregroundColor(.gray) }
                ForEach((subject.gradeHistory ?? []).sorted(by: { $0.date > $1.date })) { grade in
                    Text("[ \(formatDate(grade.date)) ] VAL: \(String(format: "%.1f", grade.grade)) - \(grade.descriptionText)")
                        .font(.system(.caption, design: .monospaced)).foregroundColor(.green)
                }
            } else if selectedTab == 1 {
                Text("> READING_ATTENDANCE_LOG...").font(.caption).fontDesign(.monospaced).foregroundColor(.gray)
                if (subject.attendanceHistory ?? []).isEmpty { Text("NULL_DATA").fontDesign(.monospaced).foregroundColor(.gray) }
                ForEach((subject.attendanceHistory ?? []).sorted(by: { $0.date > $1.date })) { att in
                    Text("[ \(formatDate(att.date)) ] STATUS: \(att.attended ? "PRESENT" : "ABSENT")")
                        .font(.system(.caption, design: .monospaced)).foregroundColor(att.attended ? .green : .red)
                }
            } else {
                Text("> READING_TASK_QUEUE...").font(.caption).fontDesign(.monospaced).foregroundColor(.gray)
                if subjectTasks.isEmpty { Text("NULL_DATA").fontDesign(.monospaced).foregroundColor(.gray) }
                ForEach(subjectTasks) { task in
                    Text("[ \(task.isCompleted ? "X" : " ") ] \(task.title.uppercased())")
                        .font(.system(.caption, design: .monospaced)).foregroundColor(.green)
                }
            }
        }
        .padding().border(Color.green.opacity(0.3), width: 1)
    }
    
    private func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.dateFormat = "MM-dd"; return f.string(from: date) }
}

struct GradeHistoryRow: View {
    let grade: GradeEntry; let averageGrade: Double?
    var body: some View { HStack(spacing: 16) { ZStack { Circle().fill(gradeColor).frame(width: 44, height: 44); Text(String(format: "%.1f", grade.grade)).font(.system(size: 14, weight: .bold)).foregroundColor(.white) }; VStack(alignment: .leading, spacing: 4) { Text(grade.descriptionText.isEmpty ? "Grade" : grade.descriptionText).font(.body).foregroundColor(.themeTextPrimary); Text(formatDate(grade.date)).font(.caption).foregroundColor(.themeTextSecondary); if let avg = averageGrade { let diff = grade.grade - avg; Text(String(format: "%+.1f", diff)).font(.caption).foregroundColor(diff >= 0 ? .themeSuccess : .themeError) } } } }
    private var gradeColor: Color { switch grade.grade { case 8.5...10: return .themeSuccess; case 7...8.4: return .themePrimary; case 5.5...6.9: return .themeWarning; default: return .themeError } }
    private func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: date) }
}

struct AttendanceHistoryRow: View {
    let attendance: AttendanceEntry
    var body: some View { HStack(spacing: 16) { ZStack { Circle().fill(attendance.attended ? Color.themeSuccess : Color.themeError).frame(width: 44, height: 44); Image(systemName: attendance.attended ? "checkmark" : "xmark").font(.system(size: 16, weight: .bold)).foregroundColor(.white) }; VStack(alignment: .leading, spacing: 4) { Text(attendance.attended ? "Present" : "Absent").font(.body).foregroundColor(.themeTextPrimary); Text(formatDate(attendance.date)).font(.caption).foregroundColor(.themeTextSecondary); if !attendance.notes.isEmpty { Text(attendance.notes).font(.caption2).foregroundColor(.themeTextSecondary).lineLimit(1) } }; Spacer(); Image(systemName: "chevron.right").font(.system(size: 14, weight: .medium)).foregroundColor(.themeTextSecondary) } }
    private func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: date) }
}

struct SubjectEmptyStateView: View {
    let icon: String; let title: String; let message: String
    var body: some View { VStack(spacing: 12) { Image(systemName: icon).font(.system(size: 48)).foregroundColor(.themeTextSecondary); Text(title).font(.headline).foregroundColor(.themeTextPrimary); Text(message).font(.subheadline).foregroundColor(.themeTextSecondary).multilineTextAlignment(.center) }.padding().frame(maxWidth: .infinity).background(Color.themeSurface).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.adaptiveTertiaryBackground, lineWidth: 1)) }
}

struct TaskRowPreview: View {
    let title: String; let subject: String; let dueDate: String; let isCompleted: Bool
    var body: some View { HStack(spacing: 12) { Circle().fill(isCompleted ? Color.themeSuccess : Color.adaptiveTertiary).frame(width: 12, height: 12); VStack(alignment: .leading, spacing: 4) { Text(title).font(.body).foregroundColor(isCompleted ? .themeTextSecondary : .themeTextPrimary).strikethrough(isCompleted); HStack(spacing: 8) { Text(subject).font(.caption).foregroundColor(.themeTextSecondary); Text("•").font(.caption).foregroundColor(.themeTextSecondary); Text(dueDate).font(.caption).foregroundColor(.themeTextSecondary) } }; Spacer(); Image(systemName: "chevron.right").font(.system(size: 14, weight: .medium)).foregroundColor(.themeTextSecondary) } }
}

struct AddGradeSheet: View {
    @Binding var isPresented: Bool; let onSave: (Date, Double, String) -> Void; @State private var grade = ""; @State private var description = ""; @State private var date = Date(); @Environment(\.colorScheme) private var colorScheme; var body: some View { NavigationView { Form { Section(header: Text("Grade Details")) { DatePicker("Date", selection: $date, displayedComponents: .date); HStack { Text("Grade"); TextField("1-10", text: $grade).keyboardType(.decimalPad); Text("/10") }; TextField("Description", text: $description) } }.navigationTitle("Add Grade").toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { isPresented = false } }; ToolbarItem(placement: .navigationBarTrailing) { Button("Save") { if let g = Double(grade), g >= 1 && g <= 10 { onSave(date, g, description); isPresented = false } }.disabled(grade.isEmpty) } } }.preferredColorScheme(colorScheme) }
}

struct MarkAttendanceSheet: View {
    @Binding var isPresented: Bool; let onSave: (Date, Bool, String) -> Void; @State private var status = true; @State private var notes = ""; @State private var date = Date(); @Environment(\.colorScheme) private var colorScheme; var body: some View { NavigationView { Form { Section(header: Text("Attendance")) { DatePicker("Date", selection: $date, displayedComponents: .date); Toggle("Attended Class", isOn: $status); TextField("Notes", text: $notes) } }.navigationTitle("Mark Attendance").toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { isPresented = false } }; ToolbarItem(placement: .navigationBarTrailing) { Button("Save") { onSave(date, status, notes); isPresented = false } } } }.preferredColorScheme(colorScheme) }
}

struct EditGradeSheet: View {
    let gradeEntry: GradeEntry; let onSave: (GradeEntry) -> Void; @Environment(\.dismiss) var dismiss; @State private var grade: String; @State private var description: String; @State private var date: Date; @Environment(\.colorScheme) private var colorScheme; init(gradeEntry: GradeEntry, onSave: @escaping (GradeEntry) -> Void) { self.gradeEntry = gradeEntry; self.onSave = onSave; _grade = State(initialValue: String(format: "%.1f", gradeEntry.grade)); _description = State(initialValue: gradeEntry.descriptionText); _date = State(initialValue: gradeEntry.date) }; var body: some View { NavigationView { Form { Section(header: Text("Grade Details")) { DatePicker("Date", selection: $date, displayedComponents: .date); HStack { Text("Grade"); TextField("1-10", text: $grade).keyboardType(.decimalPad); Text("/10") }; TextField("Description", text: $description) } }.navigationTitle("Edit Grade").toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }; ToolbarItem(placement: .navigationBarTrailing) { Button("Save") { if let g = Double(grade), g >= 1 && g <= 10 { let updated = GradeEntry(id: gradeEntry.id, date: date, grade: g, description: description); onSave(updated); dismiss() } } } } }.preferredColorScheme(colorScheme) }
}

struct EditAttendanceSheet: View {
    let attendanceEntry: AttendanceEntry; let onSave: (AttendanceEntry) -> Void; @Environment(\.dismiss) var dismiss; @State private var status: Bool; @State private var notes: String; @State private var date: Date; @Environment(\.colorScheme) private var colorScheme; init(attendanceEntry: AttendanceEntry, onSave: @escaping (AttendanceEntry) -> Void) { self.attendanceEntry = attendanceEntry; self.onSave = onSave; _status = State(initialValue: attendanceEntry.attended); _notes = State(initialValue: attendanceEntry.notes); _date = State(initialValue: attendanceEntry.date) }; var body: some View { NavigationView { Form { Section(header: Text("Attendance")) { DatePicker("Date", selection: $date, displayedComponents: .date); Toggle("Attended Class", isOn: $status); TextField("Notes", text: $notes) } }.navigationTitle("Edit Attendance").toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }; ToolbarItem(placement: .navigationBarTrailing) { Button("Save") { let updated = AttendanceEntry(id: attendanceEntry.id, date: date, attended: status, notes: notes); onSave(updated); dismiss() } } } }.preferredColorScheme(colorScheme) }
}
