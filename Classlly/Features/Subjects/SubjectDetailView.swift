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
            case .rainbow:
                RainbowSubjectDetailView(subject: subject)
            case .arcade:
                ArcadeSubjectDetailView(subject: subject)
            case .retro:
                RetroSubjectDetailView(subject: subject)
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
    @Environment(\.dismiss) var dismiss
    
    // State for sheets
    @State private var showingAddGrade = false
    @State private var showingMarkAttendance = false
    @State private var showingAddTask = false
    @State private var showingEditSubject = false
    @State private var showingDeleteAlert = false
    @State private var showingWhatIf = false
    
    @State private var editingGrade: GradeEntry?
    @State private var editingAttendance: AttendanceEntry?
    
    @Query private var tasks: [StudyTask]
    private var subjectTasks: [StudyTask] { tasks.filter { $0.subject == subject } }
    
    // Filtered Grades
    private var exams: [GradeEntry] {
        (subject.gradeHistory ?? []).filter { $0.isExam }.sorted(by: { $0.date > $1.date })
    }
    
    private var regularGrades: [GradeEntry] {
        (subject.gradeHistory ?? []).filter { !$0.isExam }.sorted(by: { $0.date > $1.date })
    }
    
    init(subject: Subject) {
        self.subject = subject
        let subjectID = subject.id
        _tasks = Query(filter: #Predicate { $0.subject?.id == subjectID })
    }
    
    // Computed Helpers
    private var formattedAverageGrade: String {
        if let grade = subject.weightedAverage {
            return String(format: "%.1f", grade)
        }
        return "N/A"
    }
    
    var body: some View {
        let accentColor = themeManager.selectedTheme.primaryColor
        
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // 1. HEADER
                    RainbowContainer {
                        HStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(accentColor.opacity(0.15))
                                    .frame(width: 64, height: 64)
                                Image(systemName: "book.fill")
                                    .font(.title)
                                    .foregroundColor(accentColor)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(subject.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text(subject.courseTeacher)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    // 2. STATS
                    HStack(spacing: 12) {
                        RainbowStatBox(
                            title: "Average",
                            value: formattedAverageGrade,
                            icon: "star.fill",
                            color: RainbowColors.orange
                        )
                        
                        RainbowStatBox(
                            title: "Attendance",
                            value: "\(Int(subject.attendanceRate * 100))%",
                            icon: "person.3.fill",
                            color: RainbowColors.green
                        )
                    }
                    
                    // 3. ACTIONS
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            RainbowActionButton(icon: "plus", label: "Grade", color: accentColor) { showingAddGrade = true }
                            RainbowActionButton(icon: "checkmark", label: "Attend", color: RainbowColors.green) { showingMarkAttendance = true }
                            RainbowActionButton(icon: "list.bullet", label: "Task", color: RainbowColors.blue) { showingAddTask = true }
                            RainbowActionButton(icon: "function", label: "What If", color: RainbowColors.orange) { showingWhatIf = true }
                            RainbowActionButton(icon: "pencil", label: "Edit", color: .gray) { showingEditSubject = true }
                        }
                    }
                    
                    // 4. INFO CARDS
                    VStack(spacing: 12) {
                        RainbowInfoCard(
                            title: "Course Details",
                            icon: "clock.fill",
                            lines: [
                                (subject.courseDaysString, subject.courseTimeString),
                                (subject.courseClassroom, subject.courseFrequency.rawValue)
                            ],
                            color: accentColor
                        )
                        
                        if !subject.seminarTeacher.isEmpty || !subject.seminarClassroom.isEmpty {
                            RainbowInfoCard(
                                title: "Seminar Details",
                                icon: "person.2.fill",
                                lines: [
                                    (subject.seminarDaysString, subject.seminarTimeString),
                                    (subject.seminarClassroom, subject.seminarFrequency.rawValue)
                                ],
                                color: RainbowColors.purple
                            )
                        }
                    }
                    
                    // 5. SECTIONS (Scrollable)
                    VStack(spacing: 32) {
                        
                        // EXAMS SECTION
                        VStack(alignment: .leading, spacing: 16) {
                            RainbowSectionHeader(title: "Exams", icon: "star.fill", color: RainbowColors.yellow)
                            
                            if exams.isEmpty {
                                EmptyRainbowState(icon: "star.slash", text: "No exams recorded")
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(exams) { grade in
                                        RainbowGradeRow(grade: grade)
                                            .onTapGesture { editingGrade = grade }
                                    }
                                }
                            }
                        }
                        
                        // GRADES SECTION
                        VStack(alignment: .leading, spacing: 16) {
                            RainbowSectionHeader(title: "Grades", icon: "chart.bar.fill", color: RainbowColors.orange)
                            
                            if regularGrades.isEmpty {
                                EmptyRainbowState(icon: "chart.bar", text: "No regular grades")
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(regularGrades) { grade in
                                        RainbowGradeRow(grade: grade)
                                            .onTapGesture { editingGrade = grade }
                                    }
                                }
                            }
                        }
                        
                        // ATTENDANCE SECTION
                        VStack(alignment: .leading, spacing: 16) {
                            RainbowSectionHeader(title: "Attendance", icon: "calendar", color: RainbowColors.green)
                            
                            if (subject.attendanceHistory ?? []).isEmpty {
                                EmptyRainbowState(icon: "calendar", text: "No attendance records")
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach((subject.attendanceHistory ?? []).sorted(by: { $0.date > $1.date })) { att in
                                        RainbowAttendanceRow(attendance: att)
                                            .onTapGesture { editingAttendance = att }
                                    }
                                }
                            }
                        }
                        
                        // TASKS SECTION
                        VStack(alignment: .leading, spacing: 16) {
                            RainbowSectionHeader(title: "Tasks", icon: "checklist", color: RainbowColors.blue)
                            
                            if subjectTasks.isEmpty {
                                EmptyRainbowState(icon: "checklist", text: "No tasks for this subject")
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(subjectTasks) { task in
                                        RainbowTaskRowPreview(task: task, color: accentColor)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button(role: .destructive) { showingDeleteAlert = true } label: { Image(systemName: "trash").foregroundColor(.red) } } }
        .sheet(isPresented: $showingAddGrade) {
            AddGradeSheet(isPresented: $showingAddGrade, accentColor: accentColor) { d, g, w, desc, isExam in
                let new = GradeEntry(date: d, grade: g, weight: w, description: desc, isExam: isExam)
                new.subject = subject
                modelContext.insert(new)
            }
        }
        .sheet(isPresented: $showingMarkAttendance) { MarkAttendanceSheet(isPresented: $showingMarkAttendance) { d, a, n in let new = AttendanceEntry(date: d, attended: a, notes: n); new.subject = subject; modelContext.insert(new) } }
        .sheet(isPresented: $showingAddTask) { AddTaskView(preSelectedSubject: subject) }
        .sheet(isPresented: $showingEditSubject) { EditSubjectView(subject: subject) }
        .sheet(isPresented: $showingWhatIf) { WhatIfGradeView(subject: subject) }
        .sheet(item: $editingGrade) { grade in
            EditGradeSheet(gradeEntry: grade, accentColor: accentColor) { updated in
                if let idx = subject.gradeHistory?.firstIndex(where: { $0.id == updated.id }) {
                    subject.gradeHistory?[idx].date = updated.date
                    subject.gradeHistory?[idx].grade = updated.grade
                    subject.gradeHistory?[idx].weight = updated.weight
                    subject.gradeHistory?[idx].descriptionText = updated.descriptionText
                    subject.gradeHistory?[idx].isExam = updated.isExam
                }
            }
        }
        .sheet(item: $editingAttendance) { attendance in EditAttendanceSheet(attendanceEntry: attendance) { updated in if let idx = subject.attendanceHistory?.firstIndex(where: { $0.id == updated.id }) { subject.attendanceHistory?[idx].date = updated.date; subject.attendanceHistory?[idx].attended = updated.attended; subject.attendanceHistory?[idx].notes = updated.notes } } }
        .alert("Delete", isPresented: $showingDeleteAlert) { Button("Delete", role: .destructive) { modelContext.delete(subject); dismiss() }; Button("Cancel", role: .cancel) { } }
    }
}

// MARK: - 👔 STANDARD DETAIL VIEW
struct StandardSubjectDetailView: View {
    @Bindable var subject: Subject
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var themeManager: AppTheme
    
    @State private var showingAddGrade = false
    @State private var showingMarkAttendance = false
    @State private var showingAddTask = false
    @State private var showingEditSubject = false
    @State private var showingDeleteAlert = false
    @State private var showingWhatIf = false
    
    @State private var editingGrade: GradeEntry?
    @State private var editingAttendance: AttendanceEntry?
    
    @Query private var tasks: [StudyTask]
    private var subjectTasks: [StudyTask] { tasks.filter { $0.subject == subject } }
    
    // Filtered Grades
    private var exams: [GradeEntry] {
        (subject.gradeHistory ?? []).filter { $0.isExam }.sorted(by: { $0.date > $1.date })
    }
    
    private var regularGrades: [GradeEntry] {
        (subject.gradeHistory ?? []).filter { !$0.isExam }.sorted(by: { $0.date > $1.date })
    }
    
    private var averageGrade: Double? {
        return subject.weightedAverage
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
        let accentColor = themeManager.selectedGameMode == .rainbow ? themeManager.selectedTheme.primaryColor : Color.themePrimary
        
        ScrollView {
            LazyVStack(spacing: 0) {
                headerView(accentColor: accentColor)
                courseInfoSection
                if hasSeminar { seminarInfoSection }
                quickActionsSection(accentColor: accentColor)
                performanceSection
                
                // Stacked Sections
                examHistorySection
                gradeHistorySection
                attendanceHistorySection
                tasksSection
            }
            .padding(.bottom, 40)
        }
        .background(Color.themeBackground)
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button(role: .destructive) { showingDeleteAlert = true } label: { Image(systemName: "trash") } } }
        .sheet(isPresented: $showingAddGrade) {
            AddGradeSheet(isPresented: $showingAddGrade, accentColor: accentColor) { d, g, w, desc, isExam in
                let new = GradeEntry(date: d, grade: g, weight: w, description: desc, isExam: isExam)
                new.subject = subject
                modelContext.insert(new)
            }
        }
        .sheet(isPresented: $showingMarkAttendance) { MarkAttendanceSheet(isPresented: $showingMarkAttendance) { d, a, n in let new = AttendanceEntry(date: d, attended: a, notes: n); new.subject = subject; modelContext.insert(new) } }
        .sheet(isPresented: $showingAddTask) { AddTaskView(preSelectedSubject: subject) }
        .sheet(isPresented: $showingEditSubject) { EditSubjectView(subject: subject) }
        .sheet(isPresented: $showingWhatIf) { WhatIfGradeView(subject: subject) }
        .sheet(item: $editingGrade) { grade in
            EditGradeSheet(gradeEntry: grade, accentColor: accentColor) { updated in
                if let idx = subject.gradeHistory?.firstIndex(where: { $0.id == updated.id }) {
                    subject.gradeHistory?[idx].date = updated.date
                    subject.gradeHistory?[idx].grade = updated.grade
                    subject.gradeHistory?[idx].weight = updated.weight
                    subject.gradeHistory?[idx].descriptionText = updated.descriptionText
                    subject.gradeHistory?[idx].isExam = updated.isExam
                }
            }
        }
        .sheet(item: $editingAttendance) { attendance in EditAttendanceSheet(attendanceEntry: attendance) { updated in if let idx = subject.attendanceHistory?.firstIndex(where: { $0.id == updated.id }) { subject.attendanceHistory?[idx].date = updated.date; subject.attendanceHistory?[idx].attended = updated.attended; subject.attendanceHistory?[idx].notes = updated.notes } } }
        .alert("Delete", isPresented: $showingDeleteAlert) { Button("Delete", role: .destructive) { modelContext.delete(subject); dismiss() }; Button("Cancel", role: .cancel) { } }
    }
    
    private var hasSeminar: Bool {
        !subject.seminarTeacher.isEmpty || !subject.seminarClassroom.isEmpty
    }
    
    private func headerView(accentColor: Color) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [accentColor, accentColor.opacity(0.6)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 100, height: 100)
                        .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    Image(systemName: "book.fill").font(.system(size: 40, weight: .medium)).foregroundColor(.white)
                }
                VStack(spacing: 8) {
                    Text(subject.title).font(.title2).fontWeight(.bold).foregroundColor(.themeTextPrimary).multilineTextAlignment(.center)
                    Text("Course: \(subject.courseTeacher)").font(.subheadline).foregroundColor(.themeTextSecondary).multilineTextAlignment(.center)
                    
                    if !subject.courseDaysString.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar").font(.caption2).foregroundColor(accentColor)
                            Text(subject.courseDaysString).font(.caption).foregroundColor(.themeTextSecondary)
                            Image(systemName: "clock").font(.caption2).foregroundColor(accentColor)
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
    
    private func quickActionsSection(accentColor: Color) -> some View { ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 12) { ActionButton(icon: "plus.circle.fill", title: "Grade", subtitle: "Add", color: accentColor) { showingAddGrade = true }; ActionButton(icon: "checkmark.circle.fill", title: "Attend", subtitle: "Mark", color: .themeSuccess) { showingMarkAttendance = true }; ActionButton(icon: "plus.circle.fill", title: "Task", subtitle: "Add", color: .themeWarning) { showingAddTask = true }; ActionButton(icon: "function", title: "What If", subtitle: "Calc", color: .themeSecondary) { showingWhatIf = true }; ActionButton(icon: "pencil", title: "Edit", subtitle: "Details", color: .themeSecondary) { showingEditSubject = true } }.padding(.horizontal) }.padding(.vertical) }
    
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
    
    private var examHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Exams").font(.headline).padding(.horizontal).padding(.top, 16)
            
            if exams.isEmpty {
                SubjectEmptyStateView(icon: "star.slash", title: "No Exams", message: "Add an exam grade.").padding(.horizontal)
            } else {
                LazyVStack(spacing: 1) {
                    ForEach(exams) { grade in
                        GradeHistoryRow(grade: grade, averageGrade: averageGrade).padding(.horizontal).padding(.vertical, 12).background(Color.themeSurface).contentShape(Rectangle()).onTapGesture { editingGrade = grade }
                    }
                }
                .background(Color.themeSurface)
            }
        }
    }
    
    private var gradeHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Grades").font(.headline).padding(.horizontal).padding(.top, 16)
            
            if regularGrades.isEmpty {
                SubjectEmptyStateView(icon: "chart.line.uptrend.xyaxis", title: "No Grades", message: "Add your first grade.").padding(.horizontal)
            } else {
                LazyVStack(spacing: 1) {
                    ForEach(regularGrades) { grade in
                        GradeHistoryRow(grade: grade, averageGrade: averageGrade).padding(.horizontal).padding(.vertical, 12).background(Color.themeSurface).contentShape(Rectangle()).onTapGesture { editingGrade = grade }
                    }
                }
                .background(Color.themeSurface)
            }
        }
    }
    
    private var attendanceHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Attendance").font(.headline).padding(.horizontal).padding(.top, 16)
            
            if (subject.attendanceHistory ?? []).isEmpty {
                SubjectEmptyStateView(icon: "calendar", title: "No Records", message: "Mark attendance to track it.").padding(.horizontal)
            } else {
                LazyVStack(spacing: 1) {
                    ForEach((subject.attendanceHistory ?? []).sorted(by: { $0.date > $1.date })) { attendance in
                        AttendanceHistoryRow(attendance: attendance).padding(.horizontal).padding(.vertical, 12).background(Color.themeSurface).contentShape(Rectangle()).onTapGesture { editingAttendance = attendance }
                    }
                }
                .background(Color.themeSurface)
            }
        }
    }
    
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tasks").font(.headline).padding(.horizontal).padding(.top, 16)
            
            if subjectTasks.isEmpty {
                SubjectEmptyStateView(icon: "checklist", title: "No Tasks", message: "Add tasks for this subject.").padding(.horizontal)
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
        }
    }
    
    private func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: date) }
}

// MARK: - 🕹️ ARCADE & RETRO
struct ArcadeSubjectDetailView: View {
    @Bindable var subject: Subject
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Query private var tasks: [StudyTask]
    @State private var showingAddGrade = false
    @State private var showingMarkAttendance = false
    @State private var showingAddTask = false
    @State private var showingEditSubject = false
    @State private var showingDeleteAlert = false
    @State private var showingWhatIf = false
    
    @State private var editingGrade: GradeEntry?
    @State private var editingAttendance: AttendanceEntry?
    @State private var selectedTab = 0
    
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
                    ZStack {
                        LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing).mask(RoundedRectangle(cornerRadius: 24)).shadow(color: .purple.opacity(0.4), radius: 10)
                        VStack(spacing: 8) {
                            Text(subject.title.uppercased()).font(.system(.title, design: .rounded)).fontWeight(.black).foregroundColor(.white).multilineTextAlignment(.center)
                            Text("INSTRUCTOR: \(subject.courseTeacher.uppercased())").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.white.opacity(0.8)).padding(4).background(Color.black.opacity(0.3)).cornerRadius(4)
                        }.padding(24)
                    }.padding(.horizontal)
                    
                    // Stats
                    HStack(spacing: 12) {
                        ArcadeStatPill(icon: "bolt.fill", value: String(format: "%.1f", subject.weightedAverage ?? 0), label: "SCORE", gradient: Gradient(colors: [.yellow, .orange]))
                        ArcadeStatPill(icon: "shield.fill", value: "\(Int(subject.attendanceRate * 100))%", label: "PRESENCE", gradient: Gradient(colors: [.blue, .cyan]))
                    }.padding(.horizontal)
                    
                    // Actions
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ArcadeActionButton(icon: "plus", label: "LOG SCORE", color: .yellow) { showingAddGrade = true }
                            ArcadeActionButton(icon: "checkmark", label: "CHECK IN", color: .cyan) { showingMarkAttendance = true }
                            ArcadeActionButton(icon: "flame", label: "NEW QUEST", color: .red) { showingAddTask = true }
                            ArcadeActionButton(icon: "brain", label: "SIMULATE", color: .purple) { showingWhatIf = true }
                            ArcadeActionButton(icon: "gearshape", label: "CONFIG", color: .gray) { showingEditSubject = true }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Info
                    VStack(spacing: 12) {
                        ArcadeInfoCell(label: "MAIN QUEST (COURSE)", value: "\(subject.courseDaysString) • \(subject.courseTimeString) @ \(subject.courseClassroom)", icon: "map.fill")
                        if !subject.seminarTeacher.isEmpty { ArcadeInfoCell(label: "SIDE QUEST (SEMINAR)", value: "\(subject.seminarDaysString) • \(subject.seminarTimeString) @ \(subject.seminarClassroom)", icon: "map.fill") }
                    }.padding(.horizontal)
                    
                    // Tabs
                    HStack(spacing: 0) {
                        ArcadeTabButton(title: "SCORES", index: 0, selectedTab: $selectedTab)
                        ArcadeTabButton(title: "LOGS", index: 1, selectedTab: $selectedTab)
                        ArcadeTabButton(title: "QUESTS", index: 2, selectedTab: $selectedTab)
                        ArcadeTabButton(title: "BOSSES", index: 3, selectedTab: $selectedTab) // Exams
                    }.padding(4).background(Color(white: 0.1)).cornerRadius(12).padding(.horizontal)
                    
                    // Content
                    VStack(spacing: 12) {
                        if selectedTab == 0 {
                            if (subject.gradeHistory ?? []).filter({ !$0.isExam }).isEmpty {
                                Text("NO SCORES LOGGED").font(.system(.body, design: .rounded)).foregroundColor(.gray)
                            } else {
                                ForEach((subject.gradeHistory ?? []).filter({ !$0.isExam }).sorted(by: { $0.date > $1.date })) { grade in
                                    ArcadeGradeRow(grade: grade).onTapGesture { editingGrade = grade }
                                }
                            }
                        } else if selectedTab == 1 {
                            if (subject.attendanceHistory ?? []).isEmpty {
                                Text("NO LOGS FOUND").font(.system(.body, design: .rounded)).foregroundColor(.gray)
                            } else {
                                ForEach((subject.attendanceHistory ?? []).sorted(by: { $0.date > $1.date })) { att in
                                    HStack {
                                        Text(att.attended ? "PRESENT" : "ABSENT").font(.system(.caption, design: .rounded)).fontWeight(.black).foregroundColor(att.attended ? .green : .red)
                                        Spacer()
                                        Text(formatDate(att.date)).font(.system(.caption, design: .rounded)).foregroundColor(.gray)
                                    }.padding().background(Color(white: 0.1)).cornerRadius(8).onTapGesture { editingAttendance = att }
                                }
                            }
                        } else if selectedTab == 2 {
                            if tasks.filter({ $0.subject == subject }).isEmpty {
                                Text("NO QUESTS ACTIVE").font(.system(.body, design: .rounded)).foregroundColor(.gray)
                            } else {
                                ForEach(tasks.filter({ $0.subject == subject })) { task in
                                    HStack {
                                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle").foregroundColor(task.isCompleted ? .green : .cyan)
                                        Text(task.title).font(.system(.caption, design: .rounded)).fontWeight(.bold).foregroundColor(.white)
                                        Spacer()
                                    }.padding().background(Color(white: 0.1)).cornerRadius(8)
                                }
                            }
                        } else {
                            // BOSSES / EXAMS
                            if (subject.gradeHistory ?? []).filter({ $0.isExam }).isEmpty {
                                Text("NO BOSSES DEFEATED").font(.system(.body, design: .rounded)).foregroundColor(.gray)
                            } else {
                                ForEach((subject.gradeHistory ?? []).filter({ $0.isExam }).sorted(by: { $0.date > $1.date })) { grade in
                                    ArcadeGradeRow(grade: grade).onTapGesture { editingGrade = grade }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { showingDeleteAlert = true } label: { Image(systemName: "trash").foregroundColor(.red) } } }
        .sheet(isPresented: $showingAddGrade) {
            AddGradeSheet(isPresented: $showingAddGrade, accentColor: .yellow) { d, g, w, desc, isExam in
                let new = GradeEntry(date: d, grade: g, weight: w, description: desc, isExam: isExam)
                new.subject = subject
                modelContext.insert(new)
            }
        }
        .sheet(isPresented: $showingMarkAttendance) { MarkAttendanceSheet(isPresented: $showingMarkAttendance) { d, a, n in let new = AttendanceEntry(date: d, attended: a, notes: n); new.subject = subject; modelContext.insert(new) } }
        .sheet(isPresented: $showingAddTask) { AddTaskView(preSelectedSubject: subject) }
        .sheet(isPresented: $showingEditSubject) { EditSubjectView(subject: subject) }
        .sheet(isPresented: $showingWhatIf) { WhatIfGradeView(subject: subject) }
        .sheet(item: $editingGrade) { grade in
            EditGradeSheet(gradeEntry: grade, accentColor: .yellow) { updated in
                if let idx = subject.gradeHistory?.firstIndex(where: { $0.id == updated.id }) {
                    subject.gradeHistory?[idx].date = updated.date
                    subject.gradeHistory?[idx].grade = updated.grade
                    subject.gradeHistory?[idx].weight = updated.weight
                    subject.gradeHistory?[idx].descriptionText = updated.descriptionText
                    subject.gradeHistory?[idx].isExam = updated.isExam
                }
            }
        }
        .sheet(item: $editingAttendance) { attendance in EditAttendanceSheet(attendanceEntry: attendance) { updated in if let idx = subject.attendanceHistory?.firstIndex(where: { $0.id == updated.id }) { subject.attendanceHistory?[idx].date = updated.date; subject.attendanceHistory?[idx].attended = updated.attended; subject.attendanceHistory?[idx].notes = updated.notes } } }
        .alert("DELETE SKILL?", isPresented: $showingDeleteAlert) { Button("CONFIRM", role: .destructive) { modelContext.delete(subject); dismiss() }; Button("CANCEL", role: .cancel) { } }
    }
    private func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: date) }
}

struct RetroSubjectDetailView: View {
    @Bindable var subject: Subject
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Query private var tasks: [StudyTask]
    
    init(subject: Subject) {
        self.subject = subject
        let subjectID = subject.id
        _tasks = Query(filter: #Predicate { $0.subject?.id == subjectID })
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.05).ignoresSafeArea()
            VStack {
                Text("> RETRO_MODE_DETAIL")
                    .font(.system(.title, design: .monospaced))
                    .foregroundColor(.green)
                Text("> \(subject.title)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.green)
            }
        }
    }
}

// MARK: - LOCAL COMPONENTS (Subject Specific) & RAINBOW HELPERS

struct RainbowSectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(color)
            Text(title).font(.title3).fontWeight(.bold).foregroundColor(.white)
            Spacer()
        }
    }
}

struct RainbowActionButton: View {
    let icon: String; let label: String; let color: Color; let action: () -> Void
    var body: some View { Button(action: action) { VStack(spacing: 8) { Image(systemName: icon).font(.headline).foregroundColor(.white).frame(width: 50, height: 50).background(color).clipShape(Circle()); Text(label).font(.caption).fontWeight(.bold).foregroundColor(.white) }.frame(width: 70) } }
}

struct RainbowInfoCard: View {
    let title: String; let icon: String; let lines: [(String, String)]; let color: Color
    var body: some View { RainbowContainer { VStack(alignment: .leading, spacing: 12) { HStack { Image(systemName: icon).foregroundColor(color); Text(title).font(.headline).foregroundColor(.white); Spacer() }; ForEach(lines.indices, id: \.self) { i in HStack { Text(lines[i].0).foregroundColor(.gray).font(.subheadline); Spacer(); Text(lines[i].1).foregroundColor(.white).font(.subheadline).fontWeight(.medium) }; if i < lines.count - 1 { Divider().background(Color.gray.opacity(0.3)) } } } } }
}

struct RainbowTabButton: View {
    let title: String; let index: Int; @Binding var selectedTab: Int; let color: Color
    var body: some View { Button(action: { withAnimation { selectedTab = index } }) { Text(title).font(.subheadline).fontWeight(.bold).frame(maxWidth: .infinity).padding(.vertical, 10).background(selectedTab == index ? color : Color.clear).foregroundColor(selectedTab == index ? .white : .gray).cornerRadius(10) } }
}

struct RainbowGradeRow: View {
    let grade: GradeEntry
    var body: some View {
        RainbowContainer {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if grade.isExam { Image(systemName: "star.fill").font(.caption).foregroundColor(.yellow) }
                        Text(grade.descriptionText.isEmpty ? (grade.isExam ? "Exam Grade" : "Grade") : grade.descriptionText).font(.body).fontWeight(.medium).foregroundColor(.white)
                    }
                    Text(formatDate(grade.date)).font(.caption).foregroundColor(.gray)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.1f", grade.grade)).font(.title3).fontWeight(.bold).foregroundColor(gradeColor)
                    Text("\(Int(grade.weight))%").font(.caption2).fontWeight(.bold).foregroundColor(.gray)
                }
            }
        }
    }
    private var gradeColor: Color { switch grade.grade { case 8.5...10: return RainbowColors.green; case 7...8.4: return RainbowColors.blue; case 5.5...6.9: return RainbowColors.orange; default: return .red } }
    private func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: date) }
}

struct RainbowAttendanceRow: View {
    let attendance: AttendanceEntry
    var body: some View { RainbowContainer { HStack { Image(systemName: attendance.attended ? "checkmark.circle.fill" : "xmark.circle.fill").font(.title2).foregroundColor(attendance.attended ? RainbowColors.green : .red); VStack(alignment: .leading, spacing: 4) { Text(attendance.attended ? "Present" : "Absent").font(.body).fontWeight(.medium).foregroundColor(.white); if !attendance.notes.isEmpty { Text(attendance.notes).font(.caption).foregroundColor(.gray) } }; Spacer(); Text(formatDate(attendance.date)).font(.caption).foregroundColor(.gray) } } }
    private func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: date) }
}

struct RainbowTaskRowPreview: View {
    let task: StudyTask; let color: Color
    var body: some View { RainbowContainer { HStack { Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle").foregroundColor(task.isCompleted ? RainbowColors.green : color); Text(task.title).foregroundColor(.white).strikethrough(task.isCompleted); Spacer(); if let d = task.dueDate { Text(formatDate(d)).font(.caption).foregroundColor(.gray) } } } }
    private func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: date) }
}

struct EmptyRainbowState: View {
    let icon: String; let text: String
    var body: some View { VStack(spacing: 16) { Image(systemName: icon).font(.system(size: 40)).foregroundColor(RainbowColors.darkCard.opacity(2)); Text(text).font(.headline).foregroundColor(.gray) }.frame(maxWidth: .infinity).padding(.vertical, 30) }
}

struct GradeHistoryRow: View {
    let grade: GradeEntry; let averageGrade: Double?
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(gradeColor).frame(width: 44, height: 44)
                Text(String(format: "%.1f", grade.grade)).font(.system(size: 14, weight: .bold)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if grade.isExam { Image(systemName: "star.fill").font(.caption).foregroundColor(.themeWarning) }
                    Text(grade.descriptionText.isEmpty ? (grade.isExam ? "Exam Grade" : "Grade") : grade.descriptionText).font(.body).foregroundColor(.themeTextPrimary)
                }
                HStack(spacing: 8) {
                    Text(formatDate(grade.date)).font(.caption).foregroundColor(.themeTextSecondary)
                    Text("• \(Int(grade.weight))%").font(.caption).foregroundColor(.themePrimary)
                }
            }
            Spacer()
            if let avg = averageGrade {
                let diff = grade.grade - avg
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: diff >= 0 ? "arrow.up" : "arrow.down").font(.caption).foregroundColor(diff >= 0 ? .themeSuccess : .themeError)
                    Text(String(format: "%+.1f", diff)).font(.caption).foregroundColor(diff >= 0 ? .themeSuccess : .themeError)
                }
            }
        }
    }
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

struct ArcadeGradeRow: View {
    let grade: GradeEntry
    var body: some View {
        HStack {
            Text(String(format: "%.1f", grade.grade)).font(.system(.title3, design: .rounded)).fontWeight(.black).foregroundColor(.yellow)
            VStack(alignment: .leading) {
                Text(grade.descriptionText.isEmpty ? "GRADE" : grade.descriptionText).font(.system(.caption, design: .rounded)).fontWeight(.bold).foregroundColor(.white)
                Text("\(Int(grade.weight))% WEIGHT").font(.system(size: 8, weight: .bold)).foregroundColor(.gray)
            }
            Spacer()
        }.padding().background(Color(white: 0.1)).cornerRadius(8)
    }
}

struct ArcadeTabButton: View {
    let title: String; let index: Int; @Binding var selectedTab: Int
    var body: some View { Button(action: { withAnimation { selectedTab = index } }) { Text(title).font(.system(size: 10, weight: .black)).padding(.vertical, 8).frame(maxWidth: .infinity).background(selectedTab == index ? Color.purple : Color.clear).foregroundColor(selectedTab == index ? .white : .gray).cornerRadius(8) } }
}

// MARK: - SHEET VIEWS

struct AddGradeSheet: View {
    @Binding var isPresented: Bool
    var accentColor: Color = .themePrimary
    let onSave: (Date, Double, Double, String, Bool) -> Void
    
    @State private var grade = ""
    @State private var weight = "20"
    @State private var description = ""
    @State private var date = Date()
    @State private var isExam = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Grade Details")) {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    HStack { Text("Grade"); Spacer(); TextField("1-10", text: $grade).keyboardType(.decimalPad).multilineTextAlignment(.trailing); Text("/10") }
                    HStack { Text("Weight"); Spacer(); TextField("Percentage", text: $weight).keyboardType(.numberPad).multilineTextAlignment(.trailing); Text("%") }
                    TextField("Description", text: $description)
                    Toggle("Is Exam", isOn: $isExam).tint(accentColor)
                }
            }
            .navigationTitle("Add Grade")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { isPresented = false } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let g = Double(grade), let w = Double(weight), g >= 1 && g <= 10 {
                            onSave(date, g, w, description, isExam)
                            isPresented = false
                        }
                    }
                    .disabled(grade.isEmpty || weight.isEmpty)
                    .fontWeight(.bold)
                    .foregroundColor(accentColor)
                }
            }
        }
        .preferredColorScheme(colorScheme)
    }
}

struct EditGradeSheet: View {
    let gradeEntry: GradeEntry
    var accentColor: Color = .themePrimary
    let onSave: (GradeEntry) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var grade: String
    @State private var weight: String
    @State private var description: String
    @State private var date: Date
    @State private var isExam: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    init(gradeEntry: GradeEntry, accentColor: Color = .themePrimary, onSave: @escaping (GradeEntry) -> Void) {
        self.gradeEntry = gradeEntry
        self.accentColor = accentColor
        self.onSave = onSave
        _grade = State(initialValue: String(format: "%.1f", gradeEntry.grade))
        _weight = State(initialValue: String(format: "%.0f", gradeEntry.weight))
        _description = State(initialValue: gradeEntry.descriptionText)
        _date = State(initialValue: gradeEntry.date)
        _isExam = State(initialValue: gradeEntry.isExam)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Grade Details")) {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    HStack { Text("Grade"); Spacer(); TextField("1-10", text: $grade).keyboardType(.decimalPad).multilineTextAlignment(.trailing); Text("/10") }
                    HStack { Text("Weight"); Spacer(); TextField("Percentage", text: $weight).keyboardType(.numberPad).multilineTextAlignment(.trailing); Text("%") }
                    TextField("Description", text: $description)
                    Toggle("Is Exam", isOn: $isExam).tint(accentColor)
                }
            }
            .navigationTitle("Edit Grade")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let g = Double(grade), let w = Double(weight), g >= 1 && g <= 10 {
                            let updated = GradeEntry(id: gradeEntry.id, date: date, grade: g, weight: w, description: description, isExam: isExam)
                            onSave(updated)
                            dismiss()
                        }
                    }
                    .fontWeight(.bold)
                    .foregroundColor(accentColor)
                }
            }
        }
        .preferredColorScheme(colorScheme)
    }
}

struct MarkAttendanceSheet: View {
    @Binding var isPresented: Bool; let onSave: (Date, Bool, String) -> Void; @State private var status = true; @State private var notes = ""; @State private var date = Date(); @Environment(\.colorScheme) private var colorScheme; var body: some View { NavigationView { Form { Section(header: Text("Attendance")) { DatePicker("Date", selection: $date, displayedComponents: .date); Toggle("Attended Class", isOn: $status); TextField("Notes", text: $notes) } }.navigationTitle("Mark Attendance").toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { isPresented = false } }; ToolbarItem(placement: .navigationBarTrailing) { Button("Save") { onSave(date, status, notes); isPresented = false } } } }.preferredColorScheme(colorScheme) }
}

struct EditAttendanceSheet: View {
    let attendanceEntry: AttendanceEntry; let onSave: (AttendanceEntry) -> Void; @Environment(\.dismiss) var dismiss; @State private var status: Bool; @State private var notes: String; @State private var date: Date; @Environment(\.colorScheme) private var colorScheme; init(attendanceEntry: AttendanceEntry, onSave: @escaping (AttendanceEntry) -> Void) { self.attendanceEntry = attendanceEntry; self.onSave = onSave; _status = State(initialValue: attendanceEntry.attended); _notes = State(initialValue: attendanceEntry.notes); _date = State(initialValue: attendanceEntry.date) }; var body: some View { NavigationView { Form { Section(header: Text("Attendance")) { DatePicker("Date", selection: $date, displayedComponents: .date); Toggle("Attended Class", isOn: $status); TextField("Notes", text: $notes) } }.navigationTitle("Edit Attendance").toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }; ToolbarItem(placement: .navigationBarTrailing) { Button("Save") { let updated = AttendanceEntry(id: attendanceEntry.id, date: date, attended: status, notes: notes); onSave(updated); dismiss() } } } }.preferredColorScheme(colorScheme) }
}
