import SwiftUI
import Combine
import SwiftData

struct SubjectDetailView: View {
    @Bindable var subject: Subject
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: AppTheme
    
    @State private var showingAddGrade = false
    @State private var showingMarkAttendance = false
    @State private var showingAddTask = false
    @State private var showingEditSubject = false
    @State private var showingDeleteAlert = false
    @State private var editingGrade: GradeEntry?
    @State private var editingAttendance: AttendanceEntry?
    @State private var selectedTab = 0
    @Environment(\.colorScheme) private var colorScheme
    
    @Query private var tasks: [StudyTask]
    
    private var subjectTasks: [StudyTask] {
        tasks.filter { $0.subject == subject }
    }
    
    init(subject: Subject) {
        self.subject = subject
        let subjectID = subject.id
        _tasks = Query(filter: #Predicate { $0.subject?.id == subjectID })
    }
    
    // FIX: Safely unwrap gradeHistory
    private var averageGrade: Double? {
        guard let history = subject.gradeHistory, !history.isEmpty else { return nil }
        let total = history.reduce(0.0) { $0 + $1.grade }
        return total / Double(history.count)
    }
    
    // FIX: Safely unwrap gradeHistory
    private var gradeTrend: (icon: String, color: Color, description: String) {
        guard let history = subject.gradeHistory, history.count >= 2 else {
            return ("minus.circle", .gray, "No trend data")
        }
        
        let sortedGrades = history.sorted { $0.date > $1.date }
        
        guard let firstGrade = sortedGrades.first?.grade,
              let secondGrade = sortedGrades.dropFirst().first?.grade else {
            return ("minus.circle", .gray, "No trend data")
        }
        
        let difference = firstGrade - secondGrade
        
        if difference > 0.3 {
            return ("arrow.up.circle.fill", .themeSuccess, "Improving")
        } else if difference < -0.3 {
            return ("arrow.down.circle.fill", .themeError, "Declining")
        } else {
            return ("minus.circle", .themeTextSecondary, "Stable")
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                headerSection
                subjectInfoSection
                quickActionsSection
                performanceOverviewSection
                tabContentSection
            }
            .padding()
        }
        .background(Color.clear)
        .navigationBarTitleDisplayMode(.inline)
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
                        .foregroundColor(.themeTextPrimary)
                }
            }
        }
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
                // Update logic handles SwiftData reference directly via ID if needed
                // Just updating the passed object usually reflects in context
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
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.themePrimary, .themeSecondary]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)
                        .shadow(color: .themePrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "book.fill")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 8) {
                    Text(subject.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.themeTextPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Course: \(subject.courseTeacher)")
                        .font(.subheadline)
                        .foregroundColor(.themeTextSecondary)
                        .multilineTextAlignment(.center)
                    
                    if !subject.courseDaysString.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                                .foregroundColor(.themePrimary)
                            Text(subject.courseDaysString)
                                .font(.caption)
                                .foregroundColor(.themeTextSecondary)
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundColor(.themePrimary)
                            Text(subject.courseTimeString)
                                .font(.caption)
                                .foregroundColor(.themeTextSecondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .adaptiveCard()
    }
    
    // MARK: - Info Section
    private var subjectInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Subject Information")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.themeTextPrimary)
            
            VStack(spacing: 0) {
                SectionHeader(title: "Course Details", icon: "book.circle.fill")
                    .padding(.top, 16)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    DetailInfoCard(icon: "person.crop.circle.fill", title: "Teacher", value: subject.courseTeacher)
                    DetailInfoCard(icon: "mappin.circle.fill", title: "Classroom", value: subject.courseClassroom)
                    DetailInfoCard(icon: "calendar.circle.fill", title: "Days", value: subject.courseDaysString)
                    DetailInfoCard(icon: "clock.circle.fill", title: "Time", value: subject.courseTimeString)
                }
                .padding(.vertical, 12)
                
                if !subject.seminarTeacher.isEmpty || !subject.seminarClassroom.isEmpty {
                    Divider().background(Color.adaptiveBorder)
                    
                    SectionHeader(title: "Seminar Details", icon: "person.2.circle.fill")
                        .padding(.top, 16)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        if !subject.seminarTeacher.isEmpty {
                            DetailInfoCard(icon: "person.crop.circle.fill", title: "Seminar Teacher", value: subject.seminarTeacher)
                        }
                        if !subject.seminarClassroom.isEmpty {
                            DetailInfoCard(icon: "mappin.circle.fill", title: "Seminar Room", value: subject.seminarClassroom)
                        }
                        if !subject.seminarDaysString.isEmpty {
                            DetailInfoCard(icon: "calendar.circle.fill", title: "Seminar Days", value: subject.seminarDaysString)
                        }
                        if !subject.seminarTimeString.isEmpty {
                            DetailInfoCard(icon: "clock.circle.fill", title: "Seminar Time", value: subject.seminarTimeString)
                        }
                    }
                    .padding(.vertical, 12)
                }
            }
            .padding(.horizontal)
            .adaptiveCard()
        }
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.themeTextPrimary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ActionButton(icon: "plus.circle.fill", title: "Add Grade", subtitle: "Record score", color: .themePrimary, action: { showingAddGrade = true })
                    ActionButton(icon: "checkmark.circle.fill", title: "Mark Attendance", subtitle: "Present/Absent", color: .themeSuccess, action: { showingMarkAttendance = true })
                    ActionButton(icon: "plus.circle.fill", title: "Add Task", subtitle: "New assignment", color: .themeWarning, action: { showingAddTask = true })
                    ActionButton(icon: "pencil", title: "Edit Subject", subtitle: "Update details", color: .themeSecondary, action: { showingEditSubject = true })
                }
            }
        }
    }
    
    // MARK: - Performance Overview
    private var performanceOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Overview")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.themeTextPrimary)
            
            HStack(spacing: 12) {
                PerformanceCard(
                    title: "Average Grade",
                    value: averageGrade != nil ? String(format: "%.1f", averageGrade!) : "N/A",
                    subtitle: averageGrade != nil ? "/10" : "No grades",
                    color: .themePrimary,
                    icon: "star.fill",
                    progress: (averageGrade ?? 0) / 10
                ).adaptiveCard()
                
                PerformanceCard(
                    title: "Attendance",
                    value: "\(Int(subject.attendanceRate * 100))%",
                    subtitle: "\(subject.attendedClasses)/\(subject.totalClasses)",
                    color: .themeSuccess,
                    icon: "person.2.fill",
                    progress: subject.attendanceRate
                ).adaptiveCard()
            }
        }
    }
    
    // MARK: - Tab Content
    private var tabContentSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 0) {
                ForEach(0..<3) { index in
                    Button(action: { selectedTab = index }) {
                        VStack(spacing: 8) {
                            Text(tabTitles[index])
                                .font(.subheadline)
                                .fontWeight(selectedTab == index ? .semibold : .medium)
                                .foregroundColor(selectedTab == index ? .themePrimary : .themeTextSecondary)
                            Rectangle()
                                .fill(selectedTab == index ? Color.themePrimary : Color.clear)
                                .frame(height: 2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.top, 8)
            .background(themeManager.isGamified ? GameColor.darkSurface : Color.themeSurface)
            .cornerRadius(12)
            
            Group {
                switch selectedTab {
                case 0: gradeHistorySection
                case 1: attendanceHistorySection
                case 2: tasksSection
                default: EmptyView()
                }
            }
        }
    }
    
    private var gradeHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // FIX: Safely unwrap
            if let history = subject.gradeHistory, !history.isEmpty {
                ForEach(history.sorted(by: { $0.date > $1.date })) { grade in
                    GradeHistoryRow(grade: grade, averageGrade: averageGrade)
                        .padding()
                        .adaptiveCard()
                        .onTapGesture { editingGrade = grade }
                        .contextMenu {
                            Button(role: .destructive) { modelContext.delete(grade) } label: { Label("Delete", systemImage: "trash") }
                            Button { editingGrade = grade } label: { Label("Edit", systemImage: "pencil") }
                        }
                }
            } else {
                EmptyStateView(icon: "chart.line.uptrend.xyaxis", title: "No Grades Yet", message: "Add your first grade.")
                    .adaptiveCard()
            }
        }
    }
    
    private var attendanceHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // FIX: Safely unwrap
            if let history = subject.attendanceHistory, !history.isEmpty {
                ForEach(history.sorted(by: { $0.date > $1.date })) { attendance in
                    AttendanceHistoryRow(attendance: attendance)
                        .padding()
                        .adaptiveCard()
                        .onTapGesture { editingAttendance = attendance }
                        .contextMenu {
                            Button(role: .destructive) { modelContext.delete(attendance) } label: { Label("Delete", systemImage: "trash") }
                            Button { editingAttendance = attendance } label: { Label("Edit", systemImage: "pencil") }
                        }
                }
            } else {
                EmptyStateView(icon: "calendar", title: "No Attendance Records", message: "Mark your first attendance.")
                    .adaptiveCard()
            }
        }
    }
    
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !subjectTasks.isEmpty {
                ForEach(subjectTasks) { task in
                    TaskRowPreview(
                        title: task.title,
                        subject: task.subject?.title ?? "General",
                        dueDate: task.dueDate != nil ? formatDate(task.dueDate!) : "No due date",
                        isCompleted: task.isCompleted
                    )
                    .padding()
                    .adaptiveCard()
                }
            } else {
                EmptyStateView(icon: "checklist", title: "No Tasks", message: "No tasks for this subject.")
                    .adaptiveCard()
            }
        }
    }
    
    private var tabTitles: [String] { ["Grades", "Attendance", "Tasks"] }
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// ... Helper views (DetailInfoCard, ActionButton, PerformanceCard, GradeHistoryRow, AttendanceHistoryRow, EmptyStateView, TaskRowPreview, Sheets)
// remain exactly as they were in previous responses (omitted here for brevity but assume they are present in the file).

// MARK: - Helper Views & Sheets
// ... (Same helpers from previous turns: DetailInfoCard, ActionButton, etc. kept here for compilation) ...

struct DetailInfoCard: View {
    let icon: String; let title: String; let value: String
    @EnvironmentObject var themeManager: AppTheme
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.caption).foregroundColor(.themePrimary).frame(width: 16)
                Text(title).font(.caption).fontWeight(.medium).foregroundColor(.themeTextSecondary)
            }
            Text(value).font(.subheadline).fontWeight(.medium).foregroundColor(.themeTextPrimary).multilineTextAlignment(.leading).lineLimit(2).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
        .background(themeManager.isGamified ? Color.white.opacity(0.05) : Color.adaptiveTertiaryBackground).cornerRadius(10)
    }
}

struct SectionHeader: View {
    let title: String; let icon: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 14, weight: .medium)).foregroundColor(.themePrimary)
            Text(title).font(.headline).fontWeight(.semibold).foregroundColor(.themeTextPrimary)
            Spacer()
        }
    }
}

struct ActionButton: View {
    let icon: String; let title: String; let subtitle: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title2).foregroundColor(color)
                Text(title).font(.caption).fontWeight(.medium).foregroundColor(.themeTextPrimary).multilineTextAlignment(.center)
                Text(subtitle).font(.caption2).foregroundColor(.themeTextSecondary).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity).padding().adaptiveCard()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PerformanceCard: View {
    let title: String; let value: String; let subtitle: String; let color: Color; let icon: String; let progress: Double; var trendIcon: String? = nil; var trendColor: Color? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon).font(.system(size: 16)).foregroundColor(color)
                Text(title).font(.subheadline).fontWeight(.medium).foregroundColor(.themeTextSecondary)
                Spacer()
                if let tIcon = trendIcon, let tColor = trendColor { Image(systemName: tIcon).font(.system(size: 14)).foregroundColor(tColor) }
            }
            Text(value).font(.title2).fontWeight(.bold).foregroundColor(.themeTextPrimary)
            Text(subtitle).font(.caption).foregroundColor(.themeTextSecondary)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.adaptiveTertiaryBackground).frame(height: 4)
                    Rectangle().fill(color).frame(width: geometry.size.width * progress, height: 4)
                }
            }.frame(height: 4)
        }.padding()
    }
}

struct GradeHistoryRow: View {
    let grade: GradeEntry; let averageGrade: Double?
    private var gradeColor: Color {
        switch grade.grade { case 8.5...10: return .themeSuccess; case 7...8.4: return .themePrimary; case 5.5...6.9: return .themeWarning; default: return .themeError }
    }
    private func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: date) }
    var body: some View {
        HStack(spacing: 16) {
            ZStack { Circle().fill(gradeColor).frame(width: 44, height: 44); Text(String(format: "%.1f", grade.grade)).font(.system(size: 14, weight: .bold)).foregroundColor(.white) }
            VStack(alignment: .leading, spacing: 4) { Text(grade.descriptionText.isEmpty ? "Grade" : grade.descriptionText).font(.body).foregroundColor(.themeTextPrimary); Text(formatDate(grade.date)).font(.caption).foregroundColor(.themeTextSecondary) }
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
}

struct AttendanceHistoryRow: View {
    let attendance: AttendanceEntry
    private func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: date) }
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(attendance.attended ? Color.themeSuccess : Color.themeError).frame(width: 44, height: 44)
                Image(systemName: attendance.attended ? "checkmark" : "xmark").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(attendance.attended ? "Present" : "Absent").font(.body).foregroundColor(.themeTextPrimary)
                Text(formatDate(attendance.date)).font(.caption).foregroundColor(.themeTextSecondary)
                if !attendance.notes.isEmpty { Text(attendance.notes).font(.caption2).foregroundColor(.themeTextSecondary).lineLimit(1) }
            }
            Spacer()
        }
    }
}

struct EmptyStateView: View {
    let icon: String; let title: String; let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 48)).foregroundColor(.themeTextSecondary)
            Text(title).font(.headline).foregroundColor(.themeTextPrimary)
            Text(message).font(.subheadline).foregroundColor(.themeTextSecondary).multilineTextAlignment(.center)
        }.padding().frame(maxWidth: .infinity)
    }
}

struct TaskRowPreview: View {
    let title: String; let subject: String; let dueDate: String; let isCompleted: Bool
    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(isCompleted ? Color.themeSuccess : Color.adaptiveTertiary).frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.body).foregroundColor(isCompleted ? .themeTextSecondary : .themeTextPrimary).strikethrough(isCompleted)
                HStack(spacing: 8) {
                    Text(subject).font(.caption).foregroundColor(.themeTextSecondary)
                    Text("•").font(.caption).foregroundColor(.themeTextSecondary)
                    Text(dueDate).font(.caption).foregroundColor(.themeTextSecondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 14, weight: .medium)).foregroundColor(.themeTextSecondary)
        }
    }
}

// MARK: - Sheets
struct AddGradeSheet: View {
    @Binding var isPresented: Bool; let onSave: (Date, Double, String) -> Void
    @State private var grade = ""; @State private var description = ""; @State private var date = Date()
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Grade Details")) {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    HStack { Text("Grade"); TextField("1-10", text: $grade).keyboardType(.decimalPad); Text("/10") }
                    TextField("Description (optional)", text: $description)
                }.adaptiveListRow()
            }
            .scrollContentBackground(.hidden).background(Color.themeBackground)
            .navigationTitle("Add Grade")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { isPresented = false } }
                ToolbarItem(placement: .navigationBarTrailing) { Button("Save") { if let val = Double(grade), val >= 1, val <= 10 { onSave(date, val, description); isPresented = false } }.disabled(grade.isEmpty) }
            }
        }
    }
}

struct MarkAttendanceSheet: View {
    @Binding var isPresented: Bool; let onSave: (Date, Bool, String) -> Void
    @State private var status = true; @State private var notes = ""; @State private var date = Date()
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Attendance")) {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Toggle("Attended Class", isOn: $status)
                    TextField("Notes (optional)", text: $notes)
                }.adaptiveListRow()
            }
            .scrollContentBackground(.hidden).background(Color.themeBackground)
            .navigationTitle("Mark Attendance")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { isPresented = false } }
                ToolbarItem(placement: .navigationBarTrailing) { Button("Save") { onSave(date, status, notes); isPresented = false } }
            }
        }
    }
}

struct EditGradeSheet: View {
    let gradeEntry: GradeEntry; let onSave: (GradeEntry) -> Void
    @Environment(\.dismiss) var dismiss; @State private var grade: String; @State private var description: String; @State private var date: Date
    init(gradeEntry: GradeEntry, onSave: @escaping (GradeEntry) -> Void) {
        self.gradeEntry = gradeEntry; self.onSave = onSave
        _grade = State(initialValue: String(format: "%.1f", gradeEntry.grade))
        _description = State(initialValue: gradeEntry.descriptionText)
        _date = State(initialValue: gradeEntry.date)
    }
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Grade Details")) {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    HStack { Text("Grade"); TextField("1-10", text: $grade).keyboardType(.decimalPad); Text("/10") }
                    TextField("Description", text: $description)
                }.adaptiveListRow()
            }
            .scrollContentBackground(.hidden).background(Color.themeBackground)
            .navigationTitle("Edit Grade")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) { Button("Save") { if let val = Double(grade), val >= 1, val <= 10 { let u = GradeEntry(id: gradeEntry.id, date: date, grade: val, description: description); onSave(u); dismiss() } }.disabled(grade.isEmpty) }
            }
        }
    }
}

struct EditAttendanceSheet: View {
    let attendanceEntry: AttendanceEntry; let onSave: (AttendanceEntry) -> Void
    @Environment(\.dismiss) var dismiss; @State private var status: Bool; @State private var notes: String; @State private var date: Date
    init(attendanceEntry: AttendanceEntry, onSave: @escaping (AttendanceEntry) -> Void) {
        self.attendanceEntry = attendanceEntry; self.onSave = onSave
        _status = State(initialValue: attendanceEntry.attended)
        _notes = State(initialValue: attendanceEntry.notes)
        _date = State(initialValue: attendanceEntry.date)
    }
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Attendance")) {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Toggle("Attended Class", isOn: $status)
                    TextField("Notes", text: $notes)
                }.adaptiveListRow()
            }
            .scrollContentBackground(.hidden).background(Color.themeBackground)
            .navigationTitle("Edit Attendance")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) { Button("Save") { let u = AttendanceEntry(id: attendanceEntry.id, date: date, attended: status, notes: notes); onSave(u); dismiss() } }
            }
        }
    }
}
