import SwiftUI
import SwiftData

struct SubjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: AppTheme
    
    @Bindable var subject: Subject
    
    @State private var showingAddGrade = false
    @State private var showingAddAttendance = false
    @State private var showingAddTask = false
    @State private var showingEditSubject = false
    @State private var showingWhatIf = false
    @State private var showingDeleteAlert = false
    
    // For editing items
    @State private var editingGrade: GradeEntry?
    @State private var editingAttendance: AttendanceEntry?
    
    @Query private var tasks: [StudyTask]
    private var subjectTasks: [StudyTask] {
        tasks.filter { $0.subject == subject && !$0.isCompleted }
    }
    
    // Computed Lists
    private var exams: [GradeEntry] {
        (subject.grades ?? []).filter { $0.isExam }.sorted(by: { $0.date > $1.date })
    }
    
    private var regularGrades: [GradeEntry] {
        (subject.grades ?? []).filter { !$0.isExam }.sorted(by: { $0.date > $1.date })
    }
    
    private var attendanceHistory: [AttendanceEntry] {
        (subject.attendance ?? []).sorted(by: { $0.date > $1.date })
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // 1. HERO SECTION
                    HeroSection(subject: subject)
                    
                    // 2. QUICK ACTIONS (Centered)
                    QuickActionsRow(
                        onAddGrade: { showingAddGrade = true },
                        onAddAttendance: { showingAddAttendance = true },
                        onAddTask: { showingAddTask = true },
                        onEdit: { showingEditSubject = true },
                        onWhatIf: { showingWhatIf = true }
                    )
                    
                    // 3. SUBJECT INFO CARD (Course + Seminar)
                    SubjectInfoCard(subject: subject)
                    
                    // 4. EXAMS SECTION
                    if !exams.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Exams")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(exams) { exam in
                                        ExamCard(exam: exam)
                                            .onTapGesture { editingGrade = exam }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // 5. PERFORMANCE RINGS
                    PerformanceRingsSection(subject: subject)
                    
                    // 6. SCROLLABLE HISTORY CARDS
                    VStack(spacing: 20) {
                        // Grade History
                        ScrollableHistoryCard(title: "Grade History", icon: "chart.bar.fill", height: 200) {
                            if regularGrades.isEmpty {
                                ContentUnavailableView("No grades", systemImage: "chart.bar")
                            } else {
                                LazyVStack(spacing: 0) {
                                    ForEach(regularGrades) { grade in
                                        GradeRow(grade: grade)
                                            .onTapGesture { editingGrade = grade }
                                        Divider()
                                    }
                                }
                            }
                        }
                        
                        // Attendance History
                        ScrollableHistoryCard(title: "Attendance History", icon: "calendar", height: 200) {
                            if attendanceHistory.isEmpty {
                                ContentUnavailableView("No records", systemImage: "calendar.badge.exclamationmark")
                            } else {
                                LazyVStack(spacing: 0) {
                                    ForEach(attendanceHistory) { entry in
                                        AttendanceRow(entry: entry)
                                            .onTapGesture { editingAttendance = entry }
                                        Divider()
                                    }
                                }
                            }
                        }
                        
                        // Tasks History
                        ScrollableHistoryCard(title: "Active Tasks", icon: "checklist", height: 200) {
                            if subjectTasks.isEmpty {
                                ContentUnavailableView("No active tasks", systemImage: "checkmark.circle")
                            } else {
                                LazyVStack(spacing: 0) {
                                    ForEach(subjectTasks) { task in
                                        TaskRow(task: task)
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 50)
                }
                .padding(.bottom)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(role: .destructive) { showingDeleteAlert = true } label: {
                    Image(systemName: "trash").foregroundColor(.red)
                }
            }
        }
        // SHEETS
        .sheet(isPresented: $showingAddGrade) {
            AddGradeSheet(isPresented: $showingAddGrade, accentColor: subject.color) { d, g, w, desc, isExam in
                let new = GradeEntry(date: d, grade: g, weight: w, description: desc, isExam: isExam)
                new.subject = subject
                modelContext.insert(new)
            }
        }
        .sheet(isPresented: $showingAddAttendance) {
            MarkAttendanceSheet(isPresented: $showingAddAttendance) { d, status, n in
                let new = AttendanceEntry(date: d, status: status, note: n)
                new.subject = subject
                modelContext.insert(new)
            }
        }
        .sheet(isPresented: $showingAddTask) { AddTaskView(preSelectedSubject: subject) }
        .sheet(isPresented: $showingEditSubject) { EditSubjectView(subject: subject) }
        .sheet(isPresented: $showingWhatIf) { WhatIfGradeView(subject: subject) }
        
        // EDIT SHEETS
        .sheet(item: $editingGrade) { grade in
            EditGradeSheet(gradeEntry: grade, accentColor: subject.color) { updated in
                grade.date = updated.date
                grade.score = updated.score
                grade.weight = updated.weight
                grade.title = updated.title
                grade.isExam = updated.isExam
                try? modelContext.save()
            }
        }
        .sheet(item: $editingAttendance) { entry in
            EditAttendanceSheet(attendanceEntry: entry) { updated in
                entry.date = updated.date
                entry.statusRaw = updated.statusRaw
                entry.note = updated.note
                try? modelContext.save()
            }
        }
        .alert("Delete Subject", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                modelContext.delete(subject)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure? All grades, attendance, and tasks for this subject will be deleted.")
        }
    }
}

// MARK: - 1. HERO SECTION
struct HeroSection: View {
    let subject: Subject
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(subject.color.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "book.fill")
                    .font(.system(size: 32))
                    .foregroundColor(subject.color)
            }
            .padding(.top, 20)
            
            Text(subject.title)
                .font(.system(size: 24, weight: .bold)) // ✅ Fixed Font Syntax
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text(subject.courseTeacher)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 2. QUICK ACTIONS (CENTERED)
struct QuickActionsRow: View {
    let onAddGrade: () -> Void
    let onAddAttendance: () -> Void
    let onAddTask: () -> Void
    let onEdit: () -> Void
    let onWhatIf: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            Spacer()
            ActionButton(icon: "graduationcap.fill", label: "Grade", color: .blue, action: onAddGrade)
            ActionButton(icon: "hand.raised.fill", label: "Attend", color: .green, action: onAddAttendance)
            ActionButton(icon: "checklist", label: "Task", color: .orange, action: onAddTask)
            ActionButton(icon: "function", label: "Calc", color: .purple, action: onWhatIf)
            ActionButton(icon: "pencil", label: "Edit", color: .gray, action: onEdit)
            Spacer()
        }
        .padding(.horizontal)
    }
    
    struct ActionButton: View {
        let icon: String
        let label: String
        let color: Color
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 8) {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: icon)
                                .foregroundColor(color)
                                .font(.headline)
                        )
                    
                    Text(label)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

// MARK: - 3. INFO CARD (COURSE & SEMINAR)
struct SubjectInfoCard: View {
    let subject: Subject
    
    var body: some View {
        VStack(spacing: 0) {
            // Course Info
            InfoRow(
                icon: "studentdesk",
                title: "Course",
                time: subject.courseTimeString,
                day: subject.courseDaysString,
                room: subject.courseClassroom,
                teacher: subject.courseTeacher,
                color: subject.color
            )
            
            // ✅ Seminar Info (Always shown if hasSeminar is true)
            if subject.hasSeminar {
                Divider().padding(.leading, 50)
                
                InfoRow(
                    icon: "person.2.fill",
                    title: "Seminar",
                    time: subject.seminarTimeString,
                    day: subject.seminarDaysString,
                    room: subject.seminarClassroom,
                    teacher: subject.seminarTeacher,
                    color: .orange
                )
            }
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    struct InfoRow: View {
        let icon: String
        let title: String
        let time: String
        let day: String
        let room: String
        let teacher: String
        let color: Color
        
        var body: some View {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 32)
                    .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    
                    HStack {
                        Label(day, systemImage: "calendar")
                        Spacer()
                        Label(time, systemImage: "clock")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    HStack {
                        Label(room, systemImage: "mappin.and.ellipse")
                        Spacer()
                        Label(teacher, systemImage: "person.fill")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
}

// MARK: - 4. EXAM CARD
struct ExamCard: View {
    let exam: GradeEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.white)
                Spacer()
                Text("\(Int(exam.score))/10")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Text(exam.title)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(2)
            
            Text(exam.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .frame(width: 140, height: 100)
        .background(
            LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(12)
        .shadow(radius: 3)
    }
}

// MARK: - 5. PERFORMANCE RINGS
struct PerformanceRingsSection: View {
    let subject: Subject
    
    var body: some View {
        HStack(spacing: 20) {
            PerformanceRing(
                title: "Average",
                value: String(format: "%.1f", subject.currentGrade ?? 0),
                progress: (subject.currentGrade ?? 0) / 10.0,
                color: .blue
            )
            
            PerformanceRing(
                title: "Attendance",
                value: "\(Int(subject.attendanceRate * 100))%",
                progress: subject.attendanceRate,
                color: .green
            )
        }
        .padding(.horizontal)
    }
    
    struct PerformanceRing: View {
        let title: String
        let value: String
        let progress: Double
        let color: Color
        
        var body: some View {
            HStack {
                ZStack {
                    Circle().stroke(color.opacity(0.2), lineWidth: 8)
                    Circle().trim(from: 0, to: progress)
                        .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(value).font(.headline).fontWeight(.bold)
                }
                .frame(width: 60, height: 60)
                
                Text(title).font(.subheadline).foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }
}

// MARK: - 6. SCROLLABLE HISTORY
struct ScrollableHistoryCard<Content: View>: View {
    let title: String
    let icon: String
    let height: CGFloat
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: icon).foregroundColor(.secondary)
                Text(title).font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            
            Divider()
            
            ScrollView {
                content().padding(.vertical, 8)
            }
            .frame(height: height)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
        }
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Rows
struct GradeRow: View {
    let grade: GradeEntry
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(grade.title).font(.body)
                Text(grade.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(String(format: "%.1f", grade.score))
                    .font(.headline).foregroundColor(grade.score >= 5 ? .green : .red)
                Text("\(Int(grade.weight))% wgt").font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(.horizontal).padding(.vertical, 8)
    }
}

struct AttendanceRow: View {
    let entry: AttendanceEntry
    var body: some View {
        HStack {
            Image(systemName: entry.status == .present ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(entry.status == .present ? .green : .red)
            VStack(alignment: .leading) {
                Text(entry.status.rawValue).font(.body)
                if let note = entry.note, !note.isEmpty {
                    Text(note).font(.caption).foregroundColor(.gray)
                }
            }
            Spacer()
            Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption).foregroundColor(.secondary)
        }
        .padding(.horizontal).padding(.vertical, 8)
    }
}

struct TaskRow: View {
    let task: StudyTask
    var body: some View {
        HStack {
            Image(systemName: task.isCompleted ? "circle.inset.filled" : "circle")
                .foregroundColor(task.isCompleted ? .green : .blue)
            Text(task.title).strikethrough(task.isCompleted)
            Spacer()
            if let due = task.dueDate {
                Text(due.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption).foregroundColor(.red)
            }
        }
        .padding(.horizontal).padding(.vertical, 8)
    }
}

// MARK: - SHEETS & HELPERS

struct AddGradeSheet: View {
    @Binding var isPresented: Bool; var accentColor: Color; let onSave: (Date, Double, Double, String, Bool) -> Void
    @State private var grade = ""; @State private var weight = "100"; @State private var description = ""; @State private var date = Date(); @State private var isExam = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title (e.g. Midterm)", text: $description)
                    Toggle("Is Exam?", isOn: $isExam).tint(accentColor)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                Section("Score") {
                    HStack { TextField("Score", text: $grade).keyboardType(.decimalPad); Text("/ 10") }
                    HStack { TextField("Weight %", text: $weight).keyboardType(.numberPad); Text("%") }
                }
            }
            .navigationTitle("Add Grade")
            .toolbar {
                Button("Save") {
                    if let g = Double(grade.replacingOccurrences(of: ",", with: ".")),
                       let w = Double(weight) {
                        onSave(date, g, w, description, isExam)
                        isPresented = false
                    }
                }.fontWeight(.bold)
            }
        }
    }
}

struct EditGradeSheet: View {
    let gradeEntry: GradeEntry; var accentColor: Color; let onSave: (GradeEntry) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var grade: String
    @State private var weight: String
    @State private var description: String
    @State private var date: Date
    @State private var isExam: Bool
    
    init(gradeEntry: GradeEntry, accentColor: Color, onSave: @escaping (GradeEntry) -> Void) {
        self.gradeEntry = gradeEntry
        self.accentColor = accentColor
        self.onSave = onSave
        _grade = State(initialValue: String(format: "%.1f", gradeEntry.score))
        _weight = State(initialValue: String(format: "%.0f", gradeEntry.weight))
        _description = State(initialValue: gradeEntry.title)
        _date = State(initialValue: gradeEntry.date)
        _isExam = State(initialValue: gradeEntry.isExam)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $description)
                    Toggle("Is Exam?", isOn: $isExam).tint(accentColor)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                Section("Score") {
                    HStack { TextField("Score", text: $grade).keyboardType(.decimalPad); Text("/ 10") }
                    HStack { TextField("Weight %", text: $weight).keyboardType(.numberPad); Text("%") }
                }
            }
            .navigationTitle("Edit Grade")
            .toolbar {
                Button("Save") {
                    if let g = Double(grade.replacingOccurrences(of: ",", with: ".")),
                       let w = Double(weight) {
                        let updated = GradeEntry(date: date, grade: g, weight: w, description: description, isExam: isExam)
                        onSave(updated)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MarkAttendanceSheet: View {
    @Binding var isPresented: Bool; let onSave: (Date, AttendanceStatus, String) -> Void
    @State private var status: AttendanceStatus = .present; @State private var notes = ""; @State private var date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Picker("Status", selection: $status) {
                    ForEach(AttendanceStatus.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                TextField("Notes", text: $notes)
            }
            .navigationTitle("Add Attendance")
            .toolbar { Button("Save") { onSave(date, status, notes); isPresented = false } }
        }
    }
}

struct EditAttendanceSheet: View {
    let attendanceEntry: AttendanceEntry; let onSave: (AttendanceEntry) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var status: AttendanceStatus
    @State private var notes: String
    @State private var date: Date
    
    init(attendanceEntry: AttendanceEntry, onSave: @escaping (AttendanceEntry) -> Void) {
        self.attendanceEntry = attendanceEntry
        self.onSave = onSave
        _status = State(initialValue: attendanceEntry.status)
        _notes = State(initialValue: attendanceEntry.note ?? "")
        _date = State(initialValue: attendanceEntry.date)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Picker("Status", selection: $status) {
                    ForEach(AttendanceStatus.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                TextField("Notes", text: $notes)
            }
            .navigationTitle("Edit Attendance")
            .toolbar {
                Button("Save") {
                    let updated = AttendanceEntry(date: date, status: status, note: notes)
                    onSave(updated)
                    dismiss()
                }
            }
        }
    }
}
