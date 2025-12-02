import SwiftUI
import Combine
import SwiftData

struct SubjectDetailView: View {
    @Bindable var subject: Subject
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
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
    
    // SAFE ACCESS: Use (subject.gradeHistory ?? [])
    private var averageGrade: Double? {
        let grades = subject.gradeHistory ?? []
        guard !grades.isEmpty else { return nil }
        let total = grades.reduce(0.0) { $0 + $1.grade }
        return total / Double(grades.count)
    }
    
    // SAFE ACCESS: Use (subject.gradeHistory ?? [])
    private var gradeTrend: (icon: String, color: Color, description: String) {
        let grades = subject.gradeHistory ?? []
        guard grades.count >= 2 else {
            return ("minus.circle", .gray, "No trend data")
        }
        
        let sortedGrades = grades.sorted { $0.date > $1.date }
        
        guard sortedGrades.count >= 2,
              let firstGrade = sortedGrades.first?.grade,
              let secondGrade = sortedGrades.dropFirst().first?.grade else {
            return ("minus.circle", .gray, "No trend data")
        }
        
        let difference = firstGrade - secondGrade
        
        if difference > 0.3 {
            return ("arrow.up.circle.fill", Color.themeSuccess, "Improving")
        } else if difference < -0.3 {
            return ("arrow.down.circle.fill", Color.themeError, "Declining")
        } else {
            return ("minus.circle", Color.themeTextSecondary, "Stable")
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                headerSection
                subjectInfoSection
                quickActionsSection
                performanceOverviewSection
                tabContentSection
            }
        }
        .background(Color.themeBackground)
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
                        .foregroundColor(Color.themeTextPrimary)
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
                // SAFE ACCESS: Optional Chaining on gradeHistory
                if let index = subject.gradeHistory?.firstIndex(where: { $0.id == updatedGrade.id }) {
                    subject.gradeHistory?[index].date = updatedGrade.date
                    subject.gradeHistory?[index].grade = updatedGrade.grade
                    subject.gradeHistory?[index].descriptionText = updatedGrade.descriptionText
                }
            }
        }
        .sheet(item: $editingAttendance) { attendance in
            EditAttendanceSheet(attendanceEntry: attendance) { updatedAttendance in
                 // SAFE ACCESS: Optional Chaining on attendanceHistory
                if let index = subject.attendanceHistory?.firstIndex(where: { $0.id == updatedAttendance.id }) {
                    subject.attendanceHistory?[index].date = updatedAttendance.date
                    subject.attendanceHistory?[index].attended = updatedAttendance.attended
                    subject.attendanceHistory?[index].notes = updatedAttendance.notes
                }
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
                            gradient: Gradient(colors: [Color.themePrimary, Color.themeSecondary]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)
                        .shadow(
                            color: Color.themePrimary.opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    
                    Image(systemName: "book.fill")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 8) {
                    Text(subject.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.themeTextPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Course: \(subject.courseTeacher)")
                        .font(.subheadline)
                        .foregroundColor(Color.themeTextSecondary)
                        .multilineTextAlignment(.center)
                    
                    if !subject.courseDaysString.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                                .foregroundColor(Color.themePrimary)
                            
                            Text(subject.courseDaysString)
                                .font(.caption)
                                .foregroundColor(Color.themeTextSecondary)
                            
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundColor(Color.themePrimary)
                            
                            Text(subject.courseTimeString)
                                .font(.caption)
                                .foregroundColor(Color.themeTextSecondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(Color.themeSurface)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.adaptiveBorder.opacity(0.3), lineWidth: 1)
        )
        .shadow(
            color: colorScheme == .dark ? .black.opacity(0.3) : .gray.opacity(0.1),
            radius: 10,
            x: 0,
            y: 5
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Subject Info Section
    private var subjectInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Subject Information")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color.themeTextPrimary)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                SectionHeader(title: "Course Details", icon: "book.circle.fill")
                    .padding(.horizontal)
                    .padding(.top, 16)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    DetailInfoCard(icon: "person.crop.circle.fill", title: "Teacher", value: subject.courseTeacher)
                    DetailInfoCard(icon: "mappin.circle.fill", title: "Classroom", value: subject.courseClassroom)
                    DetailInfoCard(icon: "calendar.circle.fill", title: "Days", value: subject.courseDaysString)
                    DetailInfoCard(icon: "clock.circle.fill", title: "Time", value: subject.courseTimeString)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                
                if !subject.seminarTeacher.isEmpty || !subject.seminarClassroom.isEmpty {
                    Divider()
                        .padding(.horizontal)
                        .background(Color.adaptiveBorder)
                    
                    SectionHeader(title: "Seminar Details", icon: "person.2.circle.fill")
                        .padding(.horizontal)
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
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                
                Divider()
                    .padding(.horizontal)
                    .background(Color.adaptiveBorder)
                
                SectionHeader(title: "Academic Summary", icon: "chart.bar.circle.fill")
                    .padding(.horizontal)
                    .padding(.top, 16)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    // SAFE ACCESS: Use count on optional arrays
                    DetailInfoCard(icon: "star.circle.fill", title: "Total Grades", value: "\(subject.gradeHistory?.count ?? 0)")
                    DetailInfoCard(icon: "checkmark.circle.fill", title: "Classes Attended", value: "\(subject.attendedClasses)/\(subject.totalClasses)")
                    DetailInfoCard(icon: "chart.line.uptrend.xyaxis.circle.fill", title: "Attendance Rate", value: "\(Int(subject.attendanceRate * 100))%")
                    if let avgGrade = averageGrade {
                        DetailInfoCard(icon: "number.circle.fill", title: "Average Grade", value: String(format: "%.1f/10", avgGrade))
                    } else {
                        DetailInfoCard(icon: "number.circle.fill", title: "Average Grade", value: "No grades")
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(Color.themeSurface)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.adaptiveTertiaryBackground, lineWidth: 1)
            )
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Quick Actions (Unchanged)
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color.themeTextPrimary)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ActionButton(
                        icon: "plus.circle.fill",
                        title: "Add Grade",
                        subtitle: "Record score",
                        color: Color.themePrimary,
                        action: { showingAddGrade = true }
                    )
                    
                    ActionButton(
                        icon: "checkmark.circle.fill",
                        title: "Mark Attendance",
                        subtitle: "Present/Absent",
                        color: Color.themeSuccess,
                        action: { showingMarkAttendance = true }
                    )
                    
                    ActionButton(
                        icon: "plus.circle.fill",
                        title: "Add Task",
                        subtitle: "New assignment",
                        color: Color.themeWarning,
                        action: { showingAddTask = true }
                    )
                    
                    ActionButton(
                        icon: "pencil",
                        title: "Edit Subject",
                        subtitle: "Update details",
                        color: Color.themeSecondary,
                        action: { showingEditSubject = true }
                    )
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 24)
        .background(Color.themeSurface)
    }
    
    // MARK: - Performance Overview
    private var performanceOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Overview")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color.themeTextPrimary)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                PerformanceCard(
                    title: "Average Grade",
                    value: averageGrade != nil ? String(format: "%.1f", averageGrade!) : "N/A",
                    subtitle: averageGrade != nil ? "/10 • \(subject.gradeHistory?.count ?? 0) grades" : "No grades yet",
                    color: Color.themePrimary,
                    icon: "star.fill",
                    progress: (averageGrade ?? 0) / 10,
                    trendIcon: gradeTrend.icon,
                    trendColor: gradeTrend.color
                )
                
                PerformanceCard(
                    title: "Attendance Rate",
                    value: "\(Int(subject.attendanceRate * 100))%",
                    subtitle: "\(subject.attendedClasses)/\(subject.totalClasses) classes",
                    color: Color.themeSuccess,
                    icon: "person.2.fill",
                    progress: subject.attendanceRate
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 24)
        .background(Color.themeSurface)
    }
    
    // MARK: - Tab Content
    private var tabContentSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(0..<3) { index in
                    Button(action: { selectedTab = index }) {
                        VStack(spacing: 8) {
                            Text(tabTitles[index])
                                .font(.subheadline)
                                .fontWeight(selectedTab == index ? .semibold : .medium)
                                .foregroundColor(selectedTab == index ? Color.themePrimary : Color.themeTextSecondary)
                            
                            Rectangle()
                                .fill(selectedTab == index ? Color.themePrimary : Color.clear)
                                .frame(height: 2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 24)
            .background(Color.themeSurface)
            
            Group {
                switch selectedTab {
                case 0:
                    gradeHistorySection
                case 1:
                    attendanceHistorySection
                case 2:
                    tasksSection
                default:
                    EmptyView()
                }
            }
        }
    }
    
    // MARK: - Grade History Section
    private var gradeHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Grade History")
                    .font(.headline)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    // SAFE ACCESS: Use coalescing
                    Text("\(subject.gradeHistory?.count ?? 0) entries")
                        .font(.caption)
                    if let average = averageGrade {
                        Text("Average: \(String(format: "%.1f", average))/10")
                            .font(.caption2)
                    }
                }
                .foregroundColor(Color.themeTextSecondary)
            }
            .padding(.horizontal)
            
            if (subject.gradeHistory ?? []).isEmpty {
                // FIX: Use renamed struct
                SubjectEmptyStateView(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "No Grades Yet",
                    message: "Add your first grade to track your progress and see your average."
                )
                .padding(.horizontal)
            } else {
                LazyVStack(spacing: 1) {
                    // SAFE ACCESS: Force unwrap safely with coalescing above
                    ForEach((subject.gradeHistory ?? []).sorted(by: { $0.date > $1.date })) { grade in
                        GradeHistoryRow(grade: grade, averageGrade: averageGrade)
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .background(Color.themeSurface)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingGrade = grade
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    modelContext.delete(grade)
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                }
                                
                                Button {
                                    editingGrade = grade
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(Color.themePrimary)
                            }
                    }
                }
                .background(Color.themeSurface)
            }
        }
        .padding(.vertical, 24)
        .background(Color.themeBackground)
    }
    
    // MARK: - Attendance History Section
    private var attendanceHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Attendance History")
                    .font(.headline)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    // SAFE ACCESS
                    Text("\(subject.attendanceHistory?.count ?? 0) classes")
                    Text("\(Int(subject.attendanceRate * 100))% overall")
                }
                .font(.caption)
                .foregroundColor(Color.themeTextSecondary)
            }
            .padding(.horizontal)
            
            if (subject.attendanceHistory ?? []).isEmpty {
                // FIX: Use renamed struct
                SubjectEmptyStateView(
                    icon: "calendar",
                    title: "No Attendance Records",
                    message: "Mark your first attendance to track your presence."
                )
                .padding(.horizontal)
            } else {
                LazyVStack(spacing: 1) {
                    // SAFE ACCESS
                    ForEach((subject.attendanceHistory ?? []).sorted(by: { $0.date > $1.date })) { attendance in
                        AttendanceHistoryRow(attendance: attendance)
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .background(Color.themeSurface)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingAttendance = attendance
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    modelContext.delete(attendance)
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                }
                                
                                Button {
                                    editingAttendance = attendance
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(Color.themePrimary)
                            }
                    }
                }
                .background(Color.themeSurface)
            }
        }
        .padding(.vertical, 24)
        .background(Color.themeBackground)
    }
    
    // MARK: - Tasks Section (Unchanged, uses Computed Prop)
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Related Tasks")
                    .font(.headline)
                Spacer()
                Text("\(subjectTasks.count) tasks")
                    .font(.caption)
                    .foregroundColor(Color.themeTextSecondary)
            }
            .padding(.horizontal)
            
            if subjectTasks.isEmpty {
                // FIX: Use renamed struct
                SubjectEmptyStateView(
                    icon: "checklist",
                    title: "No Tasks",
                    message: "Add tasks related to this subject."
                )
                .padding(.horizontal)
            } else {
                LazyVStack(spacing: 1) {
                    ForEach(subjectTasks.prefix(5)) { task in
                        NavigationLink(destination: EditTaskView(task: task)) {
                            TaskRowPreview(
                                title: task.title,
                                subject: task.subject?.title ?? "General",
                                dueDate: task.dueDate != nil ? formatDate(task.dueDate!) : "No due date",
                                isCompleted: task.isCompleted
                            )
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .background(Color.themeSurface)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .background(Color.themeSurface)
            }
        }
        .padding(.vertical, 24)
        .background(Color.themeBackground)
    }
    
    // MARK: - Helper Properties & Subviews
    private var tabTitles: [String] {
        ["Grades", "Attendance", "Tasks"]
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Components

struct DetailInfoCard: View {
    let icon: String
    let title: String
    let value: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(Color.themePrimary)
                    .frame(width: 16)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color.themeTextSecondary)
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.themeTextPrimary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.adaptiveTertiaryBackground)
        .cornerRadius(10)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.themePrimary)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color.themeTextPrimary)
            
            Spacer()
        }
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color.themeTextPrimary)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(Color.themeTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PerformanceCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    let progress: Double
    var trendIcon: String?
    var trendColor: Color?
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.themeTextSecondary)
                
                Spacer()
                
                if let trendIcon = trendIcon, let trendColor = trendColor {
                    Image(systemName: trendIcon)
                        .font(.system(size: 14))
                        .foregroundColor(trendColor)
                }
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.themeTextPrimary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(Color.themeTextSecondary)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.adaptiveTertiaryBackground)
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding()
        .background(Color.themeSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.adaptiveTertiaryBackground, lineWidth: 1)
        )
    }
}

struct GradeHistoryRow: View {
    let grade: GradeEntry
    let averageGrade: Double?
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(gradeColor)
                    .frame(width: 44, height: 44)
                
                Text(String(format: "%.1f", grade.grade))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(grade.descriptionText.isEmpty ? "Grade" : grade.descriptionText)
                    .font(.body)
                    .foregroundColor(Color.themeTextPrimary)
                
                Text(formatDate(grade.date))
                    .font(.caption)
                    .foregroundColor(Color.themeTextSecondary)
            }
            
            Spacer()
            
            if let average = averageGrade {
                let difference = grade.grade - average
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: difference >= 0 ? "arrow.up" : "arrow.down")
                        .font(.caption)
                        .foregroundColor(difference >= 0 ? Color.themeSuccess : Color.themeError)
                    
                    Text(String(format: "%+.1f", difference))
                        .font(.caption)
                        .foregroundColor(difference >= 0 ? Color.themeSuccess : Color.themeError)
                }
            }
        }
    }
    
    private var gradeColor: Color {
        switch grade.grade {
        case 8.5...10: return Color.themeSuccess
        case 7...8.4: return Color.themePrimary
        case 5.5...6.9: return Color.themeWarning
        default: return Color.themeError
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct AttendanceHistoryRow: View {
    let attendance: AttendanceEntry
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(attendance.attended ? Color.themeSuccess : Color.themeError)
                    .frame(width: 44, height: 44)
                
                Image(systemName: attendance.attended ? "checkmark" : "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(attendance.attended ? "Present" : "Absent")
                    .font(.body)
                    .foregroundColor(Color.themeTextPrimary)
                
                Text(formatDate(attendance.date))
                    .font(.caption)
                    .foregroundColor(Color.themeTextSecondary)
                
                if !attendance.notes.isEmpty {
                    Text(attendance.notes)
                        .font(.caption2)
                        .foregroundColor(Color.themeTextSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.themeTextSecondary)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// FIX: Renamed struct
struct SubjectEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(Color.themeTextSecondary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(Color.themeTextPrimary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(Color.themeTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.themeSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.adaptiveTertiaryBackground, lineWidth: 1)
        )
    }
}

struct TaskRowPreview: View {
    let title: String
    let subject: String
    let dueDate: String
    let isCompleted: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isCompleted ? Color.themeSuccess : Color.adaptiveTertiary)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .foregroundColor(isCompleted ? Color.themeTextSecondary : Color.themeTextPrimary)
                    .strikethrough(isCompleted)
                
                HStack(spacing: 8) {
                    Text(subject)
                        .font(.caption)
                        .foregroundColor(Color.themeTextSecondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(Color.themeTextSecondary)
                    
                    Text(dueDate)
                        .font(.caption)
                        .foregroundColor(Color.themeTextSecondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.themeTextSecondary)
        }
    }
}

// MARK: - Sheet Views

struct AddGradeSheet: View {
    @Binding var isPresented: Bool
    let onSave: (Date, Double, String) -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var grade = ""
    @State private var description = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Grade Details").foregroundColor(Color.themeTextPrimary)) {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    HStack {
                        Text("Grade")
                        TextField("1-10", text: $grade)
                            .keyboardType(.decimalPad)
                        Text("/10")
                    }
                    TextField("Description (optional)", text: $description)
                }
                .listRowBackground(Color.themeSurface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.themeBackground)
            .navigationTitle("Add Grade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(Color.themePrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let gradeValue = Double(grade), gradeValue >= 1 && gradeValue <= 10 {
                            onSave(date, gradeValue, description)
                            isPresented = false
                        }
                    }
                    .disabled(grade.isEmpty || Double(grade) == nil || Double(grade)! < 1 || Double(grade)! > 10)
                    .foregroundColor(Color.themePrimary)
                }
            }
        }
        .preferredColorScheme(colorScheme)
    }
}

struct MarkAttendanceSheet: View {
    @Binding var isPresented: Bool
    let onSave: (Date, Bool, String) -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var status = true
    @State private var notes = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Attendance").foregroundColor(Color.themeTextPrimary)) {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Toggle("Attended Class", isOn: $status)
                    TextField("Notes (optional)", text: $notes)
                }
                .listRowBackground(Color.themeSurface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.themeBackground)
            .navigationTitle("Mark Attendance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(Color.themePrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(date, status, notes)
                        isPresented = false
                    }
                    .foregroundColor(Color.themePrimary)
                }
            }
        }
        .preferredColorScheme(colorScheme)
    }
}

struct EditGradeSheet: View {
    let gradeEntry: GradeEntry
    let onSave: (GradeEntry) -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var grade: String
    @State private var description: String
    @State private var date: Date
    
    init(gradeEntry: GradeEntry, onSave: @escaping (GradeEntry) -> Void) {
        self.gradeEntry = gradeEntry
        self.onSave = onSave
        _grade = State(initialValue: String(format: "%.1f", gradeEntry.grade))
        _description = State(initialValue: gradeEntry.descriptionText)
        _date = State(initialValue: gradeEntry.date)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Grade Details").foregroundColor(Color.themeTextPrimary)) {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    HStack {
                        Text("Grade")
                        TextField("1-10", text: $grade)
                            .keyboardType(.decimalPad)
                        Text("/10")
                    }
                    TextField("Description", text: $description)
                }
                .listRowBackground(Color.themeSurface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.themeBackground)
            .navigationTitle("Edit Grade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.themePrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let gradeValue = Double(grade), gradeValue >= 1 && gradeValue <= 10 {
                            let updatedGrade = GradeEntry(
                                id: gradeEntry.id,
                                date: date,
                                grade: gradeValue,
                                description: description
                            )
                            onSave(updatedGrade)
                            dismiss()
                        }
                    }
                    .disabled(grade.isEmpty || Double(grade) == nil || Double(grade)! < 1 || Double(grade)! > 10)
                    .foregroundColor(Color.themePrimary)
                }
            }
        }
        .preferredColorScheme(colorScheme)
    }
}

struct EditAttendanceSheet: View {
    let attendanceEntry: AttendanceEntry
    let onSave: (AttendanceEntry) -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var status: Bool
    @State private var notes: String
    @State private var date: Date
    
    init(attendanceEntry: AttendanceEntry, onSave: @escaping (AttendanceEntry) -> Void) {
        self.attendanceEntry = attendanceEntry
        self.onSave = onSave
        _status = State(initialValue: attendanceEntry.attended)
        _notes = State(initialValue: attendanceEntry.notes)
        _date = State(initialValue: attendanceEntry.date)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Attendance").foregroundColor(Color.themeTextPrimary)) {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Toggle("Attended Class", isOn: $status)
                    TextField("Notes", text: $notes)
                }
                .listRowBackground(Color.themeSurface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.themeBackground)
            .navigationTitle("Edit Attendance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.themePrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let updatedAttendance = AttendanceEntry(
                            id: attendanceEntry.id,
                            date: date,
                            attended: status,
                            notes: notes
                        )
                        onSave(updatedAttendance)
                        dismiss()
                    }
                    .foregroundColor(Color.themePrimary)
                }
            }
        }
        .preferredColorScheme(colorScheme)
    }
}
