import SwiftUI
import Combine
import SwiftData

struct SubjectDetailView: View {
    @Bindable var subject: Subject
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var themeManager: AppTheme
    
    // Gamified Mode Setting
    @AppStorage("isGamifiedMode") private var isGamifiedMode = false
    
    @State private var showingAddGrade = false
    @State private var showingMarkAttendance = false
    @State private var showingAddTask = false
    @State private var showingEditSubject = false
    @State private var showingDeleteAlert = false
    @State private var editingGrade: GradeEntry?
    @State private var editingAttendance: AttendanceEntry?
    @State private var selectedTab = 0
    
    // Animation State
    @State private var animateStats = false
    
    @Query private var tasks: [StudyTask]
    
    private var subjectTasks: [StudyTask] {
        tasks.filter { $0.subject == subject }
    }
    
    init(subject: Subject) {
        self.subject = subject
        let subjectID = subject.id
        _tasks = Query(filter: #Predicate { $0.subject?.id == subjectID })
    }
    
    // MARK: - Computed Stats
    private var averageGrade: Double? {
        let history = subject.gradeHistory ?? []
        guard !history.isEmpty else { return nil }
        let total = history.reduce(0.0) { $0 + $1.grade }
        return total / Double(history.count)
    }
    
    // RPG-Style Rank Logic
    private var subjectRank: (title: String, color: Color) {
        guard let avg = averageGrade else { return ("Novice", .gray) }
        switch avg {
        case 9.5...10.0: return ("Mythic", .purple)
        case 9.0..<9.5:  return ("Legendary", .orange)
        case 8.0..<9.0:  return ("Epic", .blue)
        case 7.0..<8.0:  return ("Rare", .green)
        case 5.0..<7.0:  return ("Common", .gray)
        default:         return ("Struggling", .red)
        }
    }
    
    // XP Calculation
    private var subjectXP: Int {
        let gradeXP = (subject.gradeHistory ?? []).count * 100
        let attendanceXP = subject.attendedClasses * 50
        return gradeXP + attendanceXP
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if isGamifiedMode {
                    // --- GAMIFIED LAYOUT ---
                    
                    // 1. Hero Header
                    GamifiedHeader(
                        subject: subject,
                        rank: subjectRank,
                        xp: subjectXP,
                        themeColor: themeManager.selectedTheme.accentColor
                    )
                    
                    // 2. Quick Actions
                    GamifiedSectionTitle(title: "Command Center", themeColor: themeManager.selectedTheme.accentColor)
                    GamifiedQuickActions(
                        themeColor: themeManager.selectedTheme.accentColor,
                        onGrade: { showingAddGrade = true },
                        onAttendance: { showingMarkAttendance = true },
                        onTask: { showingAddTask = true },
                        onEdit: { showingEditSubject = true }
                    )
                    
                    // 3. Academic Summary (Stats Inventory)
                    GamifiedSectionTitle(title: "Character Stats", themeColor: themeManager.selectedTheme.accentColor)
                    GamifiedAcademicSummaryGrid(
                        subject: subject,
                        averageGrade: averageGrade,
                        themeColor: themeManager.selectedTheme.accentColor
                    )
                    
                    // 4. Subject Information (Mission Intel)
                    GamifiedSectionTitle(title: "Mission Intel", themeColor: themeManager.selectedTheme.accentColor)
                    GamifiedSubjectDetailsSection(
                        subject: subject,
                        themeColor: themeManager.selectedTheme.accentColor
                    )
                    
                    // 5. Tabs & Content
                    GamifiedTabSelector(selectedTab: $selectedTab, themeColor: themeManager.selectedTheme.accentColor)
                        .padding(.top, 16)
                    
                    tabContentSection(isGamified: true)
                        .padding(.top, 8)
                    
                } else {
                    // --- STANDARD LAYOUT ---
                    headerSection
                    subjectInfoSection
                    quickActionsSection
                    performanceOverviewSection
                    StandardTabSelector(selectedTab: $selectedTab)
                    tabContentSection(isGamified: false)
                }
            }
        }
        .background(Color.themeBackground)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animateStats = true
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingEditSubject = true }) {
                        Label("Edit Subject", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Delete Subject", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundColor(isGamifiedMode ? themeManager.selectedTheme.accentColor : .themeTextPrimary)
                }
            }
        }
        // Sheets
        .sheet(isPresented: $showingAddGrade) {
            AddGradeSheet(isPresented: $showingAddGrade) { date, grade, description in
                let newGrade = GradeEntry(date: date, grade: grade, description: description)
                newGrade.subject = subject
                modelContext.insert(newGrade)
            }
        }
        .sheet(isPresented: $showingMarkAttendance) {
            MarkAttendanceSheet(isPresented: $showingMarkAttendance) { date, attended, notes in
                let newAttendance = AttendanceEntry(date: date, attended: attended, notes: notes)
                newAttendance.subject = subject
                modelContext.insert(newAttendance)
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(preSelectedSubject: subject)
        }
        .sheet(isPresented: $showingEditSubject) {
            EditSubjectView(subject: subject)
        }
        .sheet(item: $editingGrade) { grade in
            EditGradeSheet(gradeEntry: grade) { updatedGrade in
                grade.date = updatedGrade.date
                grade.grade = updatedGrade.grade
                grade.descriptionText = updatedGrade.descriptionText
            }
        }
        .sheet(item: $editingAttendance) { attendance in
            EditAttendanceSheet(attendanceEntry: attendance) { updatedAttendance in
                attendance.date = updatedAttendance.date
                attendance.attended = updatedAttendance.attended
                attendance.notes = updatedAttendance.notes
            }
        }
        .alert("Delete Subject", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                modelContext.delete(subject)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete \(subject.title)? This will also delete all associated grades, attendance records, and tasks.")
        }
    }
    
    // MARK: - Shared Tab Content Logic
    @ViewBuilder
    private func tabContentSection(isGamified: Bool) -> some View {
        Group {
            switch selectedTab {
            case 0: gradeHistoryList(isGamified: isGamified)
            case 1: attendanceHistoryList(isGamified: isGamified)
            case 2: tasksList(isGamified: isGamified)
            default: EmptyView()
            }
        }
    }
    
    @ViewBuilder private func gradeHistoryList(isGamified: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if !isGamified {
                HStack {
                    Text("Grade History").font(.headline)
                    Spacer()
                    Text("\((subject.gradeHistory ?? []).count) entries")
                        .font(.caption).foregroundColor(.themeTextSecondary)
                }.padding(.horizontal)
            }
            
            if (subject.gradeHistory ?? []).isEmpty {
                DetailEmptyStateView(icon: "chart.line.uptrend.xyaxis", title: "No Grades Yet", message: "Add your first grade to track your progress.").padding(.horizontal)
            } else {
                LazyVStack(spacing: isGamified ? 12 : 1) {
                    ForEach((subject.gradeHistory ?? []).sorted(by: { $0.date > $1.date })) { grade in
                        if isGamified {
                            GamifiedGradeRow(grade: grade, themeColor: themeManager.selectedTheme.accentColor)
                                .padding(.horizontal)
                                .onTapGesture { editingGrade = grade }
                                .contextMenu {
                                    Button(role: .destructive) { modelContext.delete(grade) } label: { Label("Delete", systemImage: "trash") }
                                    Button { editingGrade = grade } label: { Label("Edit", systemImage: "pencil") }
                                }
                        } else {
                            GradeHistoryRow(grade: grade, averageGrade: averageGrade)
                                .padding(.horizontal).padding(.vertical, 12).background(Color.themeSurface)
                                .onTapGesture { editingGrade = grade }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) { modelContext.delete(grade) } label: { Label("Delete", systemImage: "trash.fill") }
                                    Button { editingGrade = grade } label: { Label("Edit", systemImage: "pencil") }.tint(.themePrimary)
                                }
                        }
                    }
                }
                .background(isGamified ? Color.clear : Color.themeSurface)
            }
        }
        .padding(.vertical, 24)
    }
    
    @ViewBuilder private func attendanceHistoryList(isGamified: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if !isGamified {
                HStack {
                    Text("Attendance History").font(.headline)
                    Spacer()
                    Text("\((subject.attendanceHistory ?? []).count) classes")
                        .font(.caption).foregroundColor(.themeTextSecondary)
                }.padding(.horizontal)
            }
            
            if (subject.attendanceHistory ?? []).isEmpty {
                DetailEmptyStateView(icon: "calendar", title: "No Attendance Records", message: "Mark your first attendance.").padding(.horizontal)
            } else {
                LazyVStack(spacing: isGamified ? 12 : 1) {
                    ForEach((subject.attendanceHistory ?? []).sorted(by: { $0.date > $1.date })) { attendance in
                        if isGamified {
                            GamifiedAttendanceRow(attendance: attendance, themeColor: themeManager.selectedTheme.accentColor).padding(.horizontal)
                                .onTapGesture { editingAttendance = attendance }
                                .contextMenu {
                                    Button(role: .destructive) { modelContext.delete(attendance) } label: { Label("Delete", systemImage: "trash") }
                                    Button { editingAttendance = attendance } label: { Label("Edit", systemImage: "pencil") }
                                }
                        } else {
                            AttendanceHistoryRow(attendance: attendance)
                                .padding(.horizontal).padding(.vertical, 12).background(Color.themeSurface).onTapGesture { editingAttendance = attendance }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) { modelContext.delete(attendance) } label: { Label("Delete", systemImage: "trash.fill") }
                                    Button { editingAttendance = attendance } label: { Label("Edit", systemImage: "pencil") }.tint(.themePrimary)
                                }
                        }
                    }
                }
                .background(isGamified ? Color.clear : Color.themeSurface)
            }
        }
        .padding(.vertical, 24)
    }
    
    @ViewBuilder private func tasksList(isGamified: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if !isGamified {
                HStack {
                    Text("Related Tasks").font(.headline)
                    Spacer()
                    Text("\(subjectTasks.count) tasks")
                        .font(.caption).foregroundColor(.themeTextSecondary)
                }.padding(.horizontal)
            }
            
            if subjectTasks.isEmpty {
                DetailEmptyStateView(icon: "checklist", title: "No Tasks", message: "Add tasks related to this subject.").padding(.horizontal)
            } else {
                LazyVStack(spacing: isGamified ? 12 : 1) {
                    ForEach(subjectTasks.prefix(5)) { task in
                        NavigationLink(destination: EditTaskView(task: task)) {
                            if isGamified {
                                GamifiedTaskRowPreview(task: task, themeColor: themeManager.selectedTheme.accentColor).padding(.horizontal)
                            } else {
                                TaskRowPreview(title: task.title, subject: task.subject?.title ?? "General", dueDate: task.dueDate != nil ? formatDate(task.dueDate!) : "No due date", isCompleted: task.isCompleted)
                                    .padding(.horizontal).padding(.vertical, 12).background(Color.themeSurface)
                            }
                        }.buttonStyle(PlainButtonStyle())
                    }
                }
                .background(isGamified ? Color.clear : Color.themeSurface)
            }
        }
        .padding(.vertical, 24)
    }
    
    // MARK: - Standard Layout Components
    private var headerSection: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                ZStack {
                    Circle().fill(LinearGradient(gradient: Gradient(colors: [.themePrimary, .themeSecondary]), startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 100, height: 100)
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
        .padding(.vertical, 24).padding(.horizontal, 20).frame(maxWidth: .infinity).background(Color.themeSurface).cornerRadius(20).padding(.horizontal, 16).padding(.top, 8)
    }
    
    private var subjectInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Subject Information").font(.headline).fontWeight(.semibold).foregroundColor(.themeTextPrimary).padding(.horizontal)
            VStack(spacing: 0) {
                SectionHeader(title: "Course Details", icon: "book.circle.fill").padding(.horizontal).padding(.top, 16)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    DetailInfoCard(icon: "person.crop.circle.fill", title: "Teacher", value: subject.courseTeacher)
                    DetailInfoCard(icon: "mappin.circle.fill", title: "Classroom", value: subject.courseClassroom)
                    DetailInfoCard(icon: "calendar.circle.fill", title: "Days", value: subject.courseDaysString)
                    DetailInfoCard(icon: "clock.circle.fill", title: "Time", value: subject.courseTimeString)
                }
                .padding(.horizontal).padding(.vertical, 12)
                
                if !subject.seminarTeacher.isEmpty || !subject.seminarClassroom.isEmpty {
                    Divider().padding(.horizontal)
                    SectionHeader(title: "Seminar Details", icon: "person.2.circle.fill").padding(.horizontal).padding(.top, 16)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        DetailInfoCard(icon: "person.crop.circle.fill", title: "Seminar Teacher", value: subject.seminarTeacher)
                        DetailInfoCard(icon: "mappin.circle.fill", title: "Seminar Room", value: subject.seminarClassroom)
                        DetailInfoCard(icon: "calendar.circle.fill", title: "Seminar Days", value: subject.seminarDaysString)
                        DetailInfoCard(icon: "clock.circle.fill", title: "Seminar Time", value: subject.seminarTimeString)
                    }
                    .padding(.horizontal).padding(.vertical, 12)
                }
                Divider().padding(.horizontal)
                SectionHeader(title: "Academic Summary", icon: "chart.bar.circle.fill").padding(.horizontal).padding(.top, 16)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    DetailInfoCard(icon: "star.circle.fill", title: "Total Grades", value: "\((subject.gradeHistory ?? []).count)")
                    DetailInfoCard(icon: "checkmark.circle.fill", title: "Classes Attended", value: "\(subject.attendedClasses)/\(subject.totalClasses)")
                    DetailInfoCard(icon: "chart.line.uptrend.xyaxis.circle.fill", title: "Attendance Rate", value: "\(Int(subject.attendanceRate * 100))%")
                    DetailInfoCard(icon: "number.circle.fill", title: "Average Grade", value: averageGrade != nil ? String(format: "%.1f/10", averageGrade!) : "No grades")
                }
                .padding(.horizontal).padding(.vertical, 12)
            }
            .background(Color.themeSurface).cornerRadius(16).padding(.horizontal)
        }
        .padding(.vertical, 16)
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions").font(.headline).fontWeight(.semibold).foregroundColor(.themeTextPrimary).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ActionButton(icon: "plus.circle.fill", title: "Add Grade", subtitle: "Record score", color: .themePrimary, action: { showingAddGrade = true })
                    ActionButton(icon: "checkmark.circle.fill", title: "Mark Attendance", subtitle: "Present/Absent", color: .themeSuccess, action: { showingMarkAttendance = true })
                    ActionButton(icon: "plus.circle.fill", title: "Add Task", subtitle: "New assignment", color: .themeWarning, action: { showingAddTask = true })
                    ActionButton(icon: "pencil", title: "Edit Subject", subtitle: "Update details", color: .themeSecondary, action: { showingEditSubject = true })
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 24).background(Color.themeSurface)
    }
    
    private var performanceOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Overview").font(.headline).fontWeight(.semibold).foregroundColor(.themeTextPrimary).padding(.horizontal)
            HStack(spacing: 12) {
                PerformanceCard(title: "Average Grade", value: averageGrade != nil ? String(format: "%.1f", averageGrade!) : "N/A", subtitle: "/10", color: .themePrimary, icon: "star.fill", progress: (averageGrade ?? 0) / 10)
                PerformanceCard(title: "Attendance Rate", value: "\(Int(subject.attendanceRate * 100))%", subtitle: "\(subject.attendedClasses)/\(subject.totalClasses)", color: .themeSuccess, icon: "person.2.fill", progress: subject.attendanceRate)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 24).background(Color.themeSurface)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter(); formatter.dateStyle = .medium; formatter.timeStyle = .none; return formatter.string(from: date)
    }
}

// MARK: - GAMIFIED COMPONENTS

struct GamifiedHeader: View {
    let subject: Subject; let rank: (title: String, color: Color); let xp: Int; let themeColor: Color
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(.white.opacity(0.2)).frame(width: 80, height: 80)
                Image(systemName: "book.fill").font(.system(size: 35)).foregroundColor(.white)
            }
            Text(subject.title).font(.title).fontWeight(.bold).foregroundColor(.white)
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill").foregroundColor(rank.color)
                    Text(rank.title).fontWeight(.bold).foregroundColor(rank.color)
                }.padding(.horizontal, 10).padding(.vertical, 4).background(Color.white).cornerRadius(12)
                
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill").foregroundColor(.yellow)
                    Text("\(xp) XP").fontWeight(.bold).foregroundColor(.white)
                }
            }
            
            HStack(spacing: 12) {
                Label(subject.courseTeacher, systemImage: "person.fill")
                Label(subject.courseClassroom, systemImage: "mappin.circle.fill")
            }
            .font(.subheadline).foregroundColor(.white.opacity(0.9))
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [themeColor, themeColor.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .shadow(radius: 5)
    }
}

struct GamifiedQuickActions: View {
    let themeColor: Color; let onGrade: () -> Void; let onAttendance: () -> Void; let onTask: () -> Void; let onEdit: () -> Void
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                GamifiedActionButton(icon: "plus", label: "Log Grade", badge: "+100 XP", color: .green, action: onGrade)
                GamifiedActionButton(icon: "checkmark", label: "Check In", badge: "+50 XP", color: .blue, action: onAttendance)
                GamifiedActionButton(icon: "list.bullet", label: "New Quest", badge: "", color: .orange, action: onTask)
                GamifiedActionButton(icon: "pencil", label: "Edit Info", badge: "", color: .purple, action: onEdit)
            }
            .padding()
        }
    }
}

struct GamifiedActionButton: View {
    let icon: String; let label: String; let badge: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle().fill(color.opacity(0.15)).frame(width: 56, height: 56)
                    Image(systemName: icon).font(.system(size: 22, weight: .bold)).foregroundColor(color)
                }
                Text(label).font(.caption).fontWeight(.bold).foregroundColor(.primary)
                if !badge.isEmpty {
                    Text(badge).font(.caption2).fontWeight(.heavy).foregroundColor(color)
                }
            }
        }
    }
}

struct GamifiedSectionTitle: View {
    let title: String; let themeColor: Color
    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.black)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            Spacer()
        }
        .padding(.top, 10)
    }
}

// ✅ NEW: Gamified Academic Summary Grid (Stats Inventory)
struct GamifiedAcademicSummaryGrid: View {
    let subject: Subject
    let averageGrade: Double?
    let themeColor: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            GamifiedStatBox(title: "Total Grades", value: "\((subject.gradeHistory ?? []).count)", icon: "star.fill", color: .yellow, themeColor: themeColor)
            GamifiedStatBox(title: "Attended", value: "\(subject.attendedClasses)/\(subject.totalClasses)", icon: "checkmark.seal.fill", color: .green, themeColor: themeColor)
            GamifiedStatBox(title: "Attendance", value: "\(Int(subject.attendanceRate * 100))%", icon: "percent", color: .cyan, themeColor: themeColor)
            GamifiedStatBox(title: "Avg Grade", value: averageGrade != nil ? String(format: "%.1f", averageGrade!) : "-", icon: "graduationcap.fill", color: themeColor, themeColor: themeColor)
        }
        .padding(.horizontal)
    }
}

struct GamifiedStatBox: View {
    let title: String; let value: String; let icon: String; let color: Color; let themeColor: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon).foregroundColor(color).font(.title3)
                Spacer()
            }
            Text(value).font(.title2).fontWeight(.black).foregroundColor(.primary)
            Text(title.uppercased()).font(.caption2).fontWeight(.bold).foregroundColor(.secondary)
        }
        .padding()
        .background(
            // TINTED BACKGROUND for Light Mode / Standard Background for Dark Mode
            ZStack {
                Color.themeSurface
                color.opacity(colorScheme == .dark ? 0.1 : 0.05) // Subtle color tint
            }
        )
        .cornerRadius(20)
        .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.3), lineWidth: 2)
        )
    }
}

// ✅ NEW: Gamified Subject Details (Mission Cards)
struct GamifiedSubjectDetailsSection: View {
    let subject: Subject; let themeColor: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            // Course Mission Card
            GamifiedMissionCard(title: "Course Details", subtitle: "Main Quest", icon: "book.closed.fill", color: themeColor) {
                VStack(spacing: 12) {
                    HStack {
                        GamifiedInfoRow(label: "Teacher", value: subject.courseTeacher, icon: "person.fill")
                        Spacer()
                        GamifiedInfoRow(label: "Room", value: subject.courseClassroom, icon: "mappin.circle.fill")
                    }
                    Divider().background(Color.primary.opacity(0.2))
                    HStack {
                        GamifiedInfoRow(label: "Days", value: subject.courseDaysString, icon: "calendar")
                        Spacer()
                        GamifiedInfoRow(label: "Time", value: subject.courseTimeString, icon: "clock.fill")
                    }
                }
            }
            
            // Seminar Mission Card
            if !subject.seminarTeacher.isEmpty || !subject.seminarClassroom.isEmpty {
                GamifiedMissionCard(title: "Seminar Details", subtitle: "Side Quest", icon: "person.2.fill", color: .orange) {
                    VStack(spacing: 12) {
                        HStack {
                            GamifiedInfoRow(label: "Teacher", value: subject.seminarTeacher, icon: "person.fill")
                            Spacer()
                            GamifiedInfoRow(label: "Room", value: subject.seminarClassroom, icon: "mappin.circle.fill")
                        }
                        Divider().background(Color.primary.opacity(0.2))
                        HStack {
                            GamifiedInfoRow(label: "Days", value: subject.seminarDaysString, icon: "calendar")
                            Spacer()
                            GamifiedInfoRow(label: "Time", value: subject.seminarTimeString, icon: "clock.fill")
                        }
                    }
                }
            }
        }.padding(.horizontal)
    }
}

struct GamifiedInfoRow: View {
    let label: String; let value: String; let icon: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.caption).foregroundColor(.secondary)
                Text(label.uppercased()).font(.caption2).fontWeight(.bold).foregroundColor(.secondary)
            }
            Text(value).font(.subheadline).fontWeight(.bold).foregroundColor(.primary).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct GamifiedMissionCard<Content: View>: View {
    let title: String; let subtitle: String; let icon: String; let color: Color; let content: Content
    @Environment(\.colorScheme) var colorScheme
    
    init(title: String, subtitle: String, icon: String, color: Color, @ViewBuilder content: () -> Content) { self.title = title; self.subtitle = subtitle; self.icon = icon; self.color = color; self.content = content() }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(subtitle.uppercased()).font(.caption2).fontWeight(.black).opacity(0.7).foregroundColor(color)
                    Text(title).font(.title3).fontWeight(.heavy).foregroundColor(.primary)
                }
                Spacer()
                Image(systemName: icon).font(.largeTitle).opacity(0.3).foregroundColor(color)
            }
            
            content
        }
        .padding(20)
        .background(
            ZStack {
                Color.themeSurface
                color.opacity(colorScheme == .dark ? 0.1 : 0.05)
            }
        )
        .cornerRadius(24)
        .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(color.opacity(0.3), lineWidth: 2))
    }
}

struct GamifiedTabSelector: View {
    @Binding var selectedTab: Int; let themeColor: Color; let tabs = ["Grades", "Attendance", "Tasks"]
    var body: some View {
        HStack { ForEach(0..<3) { index in Button(action: { withAnimation { selectedTab = index } }) { Text(tabs[index]).font(.subheadline).fontWeight(selectedTab == index ? .bold : .medium).padding(.vertical, 8).frame(maxWidth: .infinity).background(selectedTab == index ? themeColor : Color.themeSurface).foregroundColor(selectedTab == index ? .white : .primary).cornerRadius(20) } } }
        .padding(6).background(Color.themeSurface).cornerRadius(24).padding(.horizontal)
    }
}

struct StandardTabSelector: View {
    @Binding var selectedTab: Int; let tabs = ["Grades", "Attendance", "Tasks"]
    var body: some View { HStack(spacing: 0) { ForEach(0..<3) { index in Button(action: { selectedTab = index }) { VStack(spacing: 8) { Text(tabs[index]).font(.subheadline).fontWeight(selectedTab == index ? .semibold : .medium).foregroundColor(selectedTab == index ? .themePrimary : .themeTextSecondary); Rectangle().fill(selectedTab == index ? Color.themePrimary : Color.clear).frame(height: 2) }.frame(maxWidth: .infinity) } } }.padding(.horizontal).padding(.top, 24).background(Color.themeSurface) }
}

struct GamifiedGradeRow: View {
    let grade: GradeEntry; let themeColor: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack { Image(systemName: "shield.fill").resizable().frame(width: 48, height: 54).foregroundColor(rankColor); VStack(spacing: 0) { Text(rankLetter).font(.title2).fontWeight(.black).foregroundColor(.white) } }.shadow(color: rankColor.opacity(0.5), radius: 4)
            VStack(alignment: .leading, spacing: 4) { Text(grade.descriptionText.isEmpty ? "Assignment" : grade.descriptionText).font(.headline).fontWeight(.bold); Text(formatDate(grade.date)).font(.caption).foregroundColor(.secondary) }
            Spacer()
            Text(String(format: "%.1f", grade.grade)).font(.title3).fontWeight(.bold).foregroundColor(rankColor)
        }
        .padding()
        .background(
             ZStack {
                 Color.themeSurface
                 rankColor.opacity(colorScheme == .dark ? 0.1 : 0.05)
             }
         )
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(rankColor.opacity(0.3), lineWidth: 1.5))
    }
    var rankLetter: String { if grade.grade >= 9.5 { return "S" } else if grade.grade >= 8.5 { return "A" } else if grade.grade >= 7.0 { return "B" } else if grade.grade >= 5.0 { return "C" } else { return "F" } }
    var rankColor: Color { if grade.grade >= 9.5 { return .purple } else if grade.grade >= 8.5 { return .green } else if grade.grade >= 7.0 { return .blue } else if grade.grade >= 5.0 { return .gray } else { return .red } }
    private func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: date) }
}

struct GamifiedAttendanceRow: View {
    let attendance: AttendanceEntry; let themeColor: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            ZStack { Circle().fill(attendance.attended ? Color.green.opacity(0.2) : Color.red.opacity(0.2)).frame(width: 44, height: 44); Image(systemName: attendance.attended ? "checkmark.shield.fill" : "exclamationmark.shield.fill").font(.title3).foregroundColor(attendance.attended ? .green : .red) }
            VStack(alignment: .leading, spacing: 4) { Text(attendance.attended ? "Check-in Bonus" : "Missed Event").font(.headline).fontWeight(.bold); Text(formatDate(attendance.date)).font(.caption).foregroundColor(.secondary) }
            Spacer()
            Text(attendance.attended ? "+50 XP" : "0 XP").font(.caption).fontWeight(.bold).padding(6).background(attendance.attended ? Color.green : Color.red).foregroundColor(.white).cornerRadius(8)
        }
        .padding()
        .background(
            ZStack {
                Color.themeSurface
                (attendance.attended ? Color.green : Color.red).opacity(colorScheme == .dark ? 0.1 : 0.05)
            }
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
    private func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: date) }
}

struct GamifiedTaskRowPreview: View {
    let task: StudyTask; let themeColor: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.isCompleted ? "scroll.fill" : "scroll").font(.largeTitle).foregroundColor(task.isCompleted ? .yellow : .secondary)
            VStack(alignment: .leading) { Text(task.title).font(.headline).strikethrough(task.isCompleted); if task.isCompleted { Text("Quest Completed").font(.caption).foregroundColor(.yellow) } else { Text("Active Quest").font(.caption).foregroundColor(themeColor) } }
            Spacer()
            if let date = task.dueDate { Text(formatDate(date)).font(.caption).padding(6).background(Color.gray.opacity(0.1)).cornerRadius(8) }
        }
        .padding()
        .background(
            ZStack {
                Color.themeSurface
                (task.isCompleted ? Color.yellow : themeColor).opacity(colorScheme == .dark ? 0.1 : 0.05)
            }
        )
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(task.isCompleted ? Color.yellow.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: 1.5))
    }
    private func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.dateFormat = "MMM d"; return f.string(from: date) }
}

// MARK: - SHARED / STANDARD COMPONENTS

struct DetailEmptyStateView: View {
    let icon: String; let title: String; let message: String
    var body: some View { VStack(spacing: 12) { Image(systemName: icon).font(.system(size: 48)).foregroundColor(.themeTextSecondary); Text(title).font(.headline).foregroundColor(.themeTextPrimary); Text(message).font(.subheadline).foregroundColor(.themeTextSecondary).multilineTextAlignment(.center) }.padding().frame(maxWidth: .infinity).background(Color.themeSurface).cornerRadius(12) }
}

struct DetailInfoCard: View {
    let icon: String; let title: String; let value: String
    var body: some View { VStack(alignment: .leading, spacing: 8) { HStack(spacing: 8) { Image(systemName: icon).font(.caption).foregroundColor(.themePrimary); Text(title).font(.caption).fontWeight(.medium).foregroundColor(.themeTextSecondary) }; Text(value).font(.subheadline).fontWeight(.medium).foregroundColor(.themeTextPrimary).lineLimit(2) }.frame(maxWidth: .infinity, alignment: .leading).padding(12).background(Color.themeBackground).cornerRadius(10) }
}

struct SectionHeader: View {
    let title: String; let icon: String
    var body: some View { HStack { Image(systemName: icon).foregroundColor(.themePrimary); Text(title).font(.headline); Spacer() } }
}

struct ActionButton: View {
    let icon: String; let title: String; let subtitle: String; let color: Color; let action: () -> Void
    var body: some View { Button(action: action) { VStack(spacing: 8) { Image(systemName: icon).font(.title2).foregroundColor(color); Text(title).font(.caption).bold(); Text(subtitle).font(.caption2).foregroundColor(.secondary) }.frame(maxWidth: .infinity).padding().background(color.opacity(0.1)).cornerRadius(12) } }
}

struct PerformanceCard: View {
    let title: String; let value: String; let subtitle: String; let color: Color; let icon: String; let progress: Double; var trendIcon: String? = nil; var trendColor: Color? = nil
    var body: some View { VStack(alignment: .leading, spacing: 12) { HStack { Image(systemName: icon).foregroundColor(color); Text(title).font(.subheadline).fontWeight(.medium).foregroundColor(.themeTextSecondary); Spacer(); if let tI = trendIcon, let tC = trendColor { Image(systemName: tI).foregroundColor(tC) } }; Text(value).font(.title2).bold().foregroundColor(.themeTextPrimary); Text(subtitle).font(.caption).foregroundColor(.themeTextSecondary); GeometryReader { g in ZStack(alignment: .leading) { Rectangle().fill(Color.gray.opacity(0.2)); Rectangle().fill(color).frame(width: g.size.width * max(0, min(progress, 1.0))) } }.frame(height: 4) }.padding().background(Color.themeSurface).cornerRadius(12) }
}

struct GradeHistoryRow: View {
    let grade: GradeEntry; let averageGrade: Double?
    var body: some View { HStack { ZStack { Circle().fill(gradeColor).frame(width: 44, height: 44); Text(String(format: "%.1f", grade.grade)).font(.system(size: 14, weight: .bold)).foregroundColor(.white) }; VStack(alignment: .leading) { Text(grade.descriptionText.isEmpty ? "Grade" : grade.descriptionText).font(.body); Text(formatDate(grade.date)).font(.caption).foregroundColor(.secondary) }; Spacer() } }
    private var gradeColor: Color { grade.grade >= 9 ? .themeSuccess : (grade.grade >= 7 ? .themePrimary : .themeWarning) }
    private func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: date) }
}

struct AttendanceHistoryRow: View {
    let attendance: AttendanceEntry
    var body: some View { HStack { ZStack { Circle().fill(attendance.attended ? Color.themeSuccess : Color.themeError).frame(width: 44, height: 44); Image(systemName: attendance.attended ? "checkmark" : "xmark").font(.headline).foregroundColor(.white) }; VStack(alignment: .leading) { Text(attendance.attended ? "Present" : "Absent").font(.body); Text(formatDate(attendance.date)).font(.caption).foregroundColor(.secondary) }; Spacer() } }
    private func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: date) }
}

struct TaskRowPreview: View {
    let title: String; let subject: String; let dueDate: String; let isCompleted: Bool
    var body: some View { HStack { Circle().fill(isCompleted ? Color.themeSuccess : Color.secondary).frame(width: 12, height: 12); VStack(alignment: .leading) { Text(title).strikethrough(isCompleted); HStack { Text(subject); Text("•"); Text(dueDate) }.font(.caption).foregroundColor(.secondary) }; Spacer(); Image(systemName: "chevron.right").foregroundColor(.secondary) } }
}

// MARK: - SHEET VIEWS

struct AddGradeSheet: View {
    @Binding var isPresented: Bool; let onSave: (Date, Double, String) -> Void
    @State private var grade = ""; @State private var description = ""; @State private var date = Date()
    var body: some View { NavigationView { Form { DatePicker("Date", selection: $date, displayedComponents: .date); TextField("Grade", text: $grade).keyboardType(.decimalPad); TextField("Description", text: $description) }.toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { isPresented = false } }; ToolbarItem(placement: .confirmationAction) { Button("Save") { if let g = Double(grade) { onSave(date, g, description) }; isPresented = false } } } } }
}

struct MarkAttendanceSheet: View {
    @Binding var isPresented: Bool; let onSave: (Date, Bool, String) -> Void
    @State private var status = true; @State private var notes = ""; @State private var date = Date()
    var body: some View { NavigationView { Form { DatePicker("Date", selection: $date, displayedComponents: .date); Toggle("Present", isOn: $status); TextField("Notes", text: $notes) }.toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { isPresented = false } }; ToolbarItem(placement: .confirmationAction) { Button("Save") { onSave(date, status, notes); isPresented = false } } } } }
}

struct EditGradeSheet: View {
    let gradeEntry: GradeEntry; let onSave: (GradeEntry) -> Void; @Environment(\.dismiss) var dismiss
    @State private var grade = ""; @State private var description = ""; @State private var date = Date()
    init(gradeEntry: GradeEntry, onSave: @escaping (GradeEntry) -> Void) { self.gradeEntry = gradeEntry; self.onSave = onSave; _grade = State(initialValue: String(gradeEntry.grade)); _description = State(initialValue: gradeEntry.descriptionText); _date = State(initialValue: gradeEntry.date) }
    var body: some View { NavigationView { Form { DatePicker("Date", selection: $date, displayedComponents: .date); TextField("Grade", text: $grade).keyboardType(.decimalPad); TextField("Description", text: $description) }.toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Save") { let n = GradeEntry(id: gradeEntry.id, date: date, grade: Double(grade) ?? 0, description: description); onSave(n); dismiss() } } } } }
}

struct EditAttendanceSheet: View {
    let attendanceEntry: AttendanceEntry; let onSave: (AttendanceEntry) -> Void; @Environment(\.dismiss) var dismiss
    @State private var attended = false; @State private var notes = ""; @State private var date = Date()
    init(attendanceEntry: AttendanceEntry, onSave: @escaping (AttendanceEntry) -> Void) { self.attendanceEntry = attendanceEntry; self.onSave = onSave; _attended = State(initialValue: attendanceEntry.attended); _notes = State(initialValue: attendanceEntry.notes); _date = State(initialValue: attendanceEntry.date) }
    var body: some View { NavigationView { Form { DatePicker("Date", selection: $date, displayedComponents: .date); Toggle("Present", isOn: $attended); TextField("Notes", text: $notes) }.toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Save") { let e = AttendanceEntry(id: attendanceEntry.id, date: date, attended: attended, notes: notes); onSave(e); dismiss() } } } } }
}
