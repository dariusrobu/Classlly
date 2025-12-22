import SwiftUI
import SwiftData

struct TasksView: View {
    @EnvironmentObject var themeManager: AppTheme
    var embedInNavigation: Bool = true
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .rainbow:
                AnyView(RainbowTasksView(embedInNavigation: embedInNavigation))
            case .standard:
                AnyView(StandardTasksView(embedInNavigation: embedInNavigation))
            }
        }
    }
}

// MARK: - 🌈 RAINBOW TASKS (Redesigned)
struct RainbowTasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: AppTheme
    
    var embedInNavigation: Bool
    
    @Query var tasks: [StudyTask]
    
    @State private var showingAddTask = false
    @State private var filter: TaskFilter = .pending
    
    init(embedInNavigation: Bool) {
        self.embedInNavigation = embedInNavigation
        _tasks = Query(sort: [SortDescriptor(\StudyTask.dueDate, order: .forward)])
    }
    
    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case pending = "Todo"
        case completed = "Done"
    }
    
    // Computed Progress for the Header
    var taskProgress: Double {
        let total = tasks.count
        let done = tasks.filter { $0.isCompleted }.count
        return total > 0 ? Double(done) / Double(total) : 0
    }
    
    var filteredTasks: [StudyTask] {
        let currentTasks = switch filter {
        case .all: tasks
        case .pending: tasks.filter { !$0.isCompleted }
        case .completed: tasks.filter { $0.isCompleted }
        }
        
        return currentTasks.sorted {
            // Sort: High priority first, then by date
            if $0.isCompleted != $1.isCompleted { return !$0.isCompleted }
            if $0.priority == $1.priority {
                return ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture)
            }
            return $0.priority.rawValue > $1.priority.rawValue
        }
    }
    
    var body: some View {
        let accent = themeManager.selectedTheme.primaryColor
        
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. Header
                RainbowHeader(
                    title: "Tasks",
                    accentColor: accent,
                    showBackButton: !embedInNavigation,
                    backAction: { dismiss() },
                    trailingIcon: "plus",
                    trailingAction: { showingAddTask = true }
                )
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // 2. Progress & Stats Bar
                        VStack(spacing: 10) {
                            HStack {
                                Text("YOUR PROGRESS")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(Int(taskProgress * 100))%")
                                    .font(.caption).fontWeight(.black)
                                    .foregroundColor(accent)
                            }
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color(white: 0.15))
                                    Capsule()
                                        .fill(LinearGradient(colors: [accent, RainbowColors.purple], startPoint: .leading, endPoint: .trailing))
                                        .frame(width: geo.size.width * taskProgress)
                                }
                            }
                            .frame(height: 8)
                            .shadow(color: accent.opacity(0.3), radius: 5)
                            
                            // Filter Pills
                            HStack(spacing: 12) {
                                ForEach(TaskFilter.allCases, id: \.self) { f in
                                    Button(action: { withAnimation { filter = f } }) {
                                        Text(f.rawValue.uppercased())
                                            .font(.system(size: 10, weight: .bold))
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 16)
                                            .background(filter == f ? accent : Color(white: 0.1))
                                            .foregroundColor(filter == f ? .black : .gray)
                                            .cornerRadius(20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(filter == f ? accent : Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    }
                                }
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                        
                        // 3. Task List
                        LazyVStack(spacing: 16) {
                            if filteredTasks.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "checklist").font(.system(size: 60))
                                        .foregroundStyle(LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)], startPoint: .top, endPoint: .bottom))
                                    Text("No Tasks Found").font(.headline).fontWeight(.bold).foregroundColor(.gray)
                                }.padding(.top, 60)
                            } else {
                                ForEach(filteredTasks) { task in
                                    RainbowColorfulTaskRow(task: task)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.bottom, 100)
                    }
                    .padding(.top, 10)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddTask) { AddTaskView() }
    }
}

// MARK: - 🎨 COLORFUL TASK ROW
struct RainbowColorfulTaskRow: View {
    let task: StudyTask
    @State private var showEdit = false
    
    // Determine base color based on Subject, or fallback to Task Type
    var baseColor: Color {
        if let subject = task.subject {
            return subject.color
        }
        // Fallback colors if no subject
        switch task.type {
        case .exam, .quiz: return RainbowColors.red
        case .homework: return RainbowColors.blue
        case .project: return RainbowColors.purple
        default: return RainbowColors.orange
        }
    }
    
    // Icon for the big circle
    var typeIcon: String {
        switch task.type {
        case .exam: return "graduationcap.fill"
        case .homework: return "doc.text.fill"
        case .project: return "folder.fill"
        case .quiz: return "pencil.and.outline"
        case .presentation: return "person.wave.2.fill"
        default: return "checkmark.circle.fill"
        }
    }
    
    var body: some View {
        ZStack {
            // Background Card
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            task.isCompleted ? Color(white: 0.1) : baseColor.opacity(0.2),
                            Color(white: 0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    task.isCompleted ? Color.gray.opacity(0.3) : baseColor.opacity(0.6),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )

            HStack(spacing: 16) {
                // 1. Checkbox Area
                Button(action: { withAnimation(.spring()) { task.isCompleted.toggle() } }) {
                    ZStack {
                        Circle()
                            .fill(task.isCompleted ? RainbowColors.green : Color.black.opacity(0.3))
                            .frame(width: 32, height: 32)
                            .overlay(Circle().stroke(task.isCompleted ? RainbowColors.green : Color.gray, lineWidth: 2))
                        
                        if task.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.caption).fontWeight(.black)
                                .foregroundColor(.black)
                        }
                    }
                }
                .padding(.leading, 16)
                
                // 2. Main Content
                VStack(alignment: .leading, spacing: 6) {
                    // Badges Row
                    HStack(spacing: 6) {
                        if let subject = task.subject {
                            Text(subject.title.uppercased())
                                .font(.system(size: 9, weight: .black))
                                .padding(.vertical, 3)
                                .padding(.horizontal, 6)
                                .background(subject.color)
                                .foregroundColor(.black)
                                .cornerRadius(4)
                        }
                        
                        if task.priority == .high && !task.isCompleted {
                            Text("URGENT")
                                .font(.system(size: 9, weight: .black))
                                .padding(.vertical, 3)
                                .padding(.horizontal, 6)
                                .background(RainbowColors.red)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                                .shadow(color: RainbowColors.red.opacity(0.5), radius: 4)
                        }
                    }
                    
                    Text(task.title)
                        .font(.headline).fontWeight(.bold)
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .gray : .white)
                        .lineLimit(2)
                    
                    // Date & Time
                    if let due = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(due.formatted(date: .abbreviated, time: .shortened))
                        }
                        .font(.caption).fontWeight(.bold)
                        .foregroundColor(dateColor(for: due))
                    }
                }
                
                Spacer()
                
                // 3. Task Type Graphic
                ZStack {
                    Circle()
                        .fill(task.isCompleted ? Color.gray.opacity(0.2) : baseColor)
                        .frame(width: 44, height: 44)
                        .shadow(color: task.isCompleted ? .clear : baseColor.opacity(0.4), radius: 8)
                    
                    Image(systemName: typeIcon)
                        .font(.system(size: 20))
                        .foregroundColor(task.isCompleted ? .gray : .white) // Icon is white on colored circle
                }
                .padding(.trailing, 16)
                .onTapGesture {
                    showEdit = true
                }
            }
            .padding(.vertical, 16)
        }
        .opacity(task.isCompleted ? 0.6 : 1.0)
        .scaleEffect(task.isCompleted ? 0.98 : 1.0)
        .animation(.spring(), value: task.isCompleted)
        .sheet(isPresented: $showEdit) {
            EditTaskView(task: task)
        }
    }
    
    // Helper for Date Color
    func dateColor(for date: Date) -> Color {
        if task.isCompleted { return .gray }
        let calendar = Calendar.current
        if date < Date() { return RainbowColors.red } // Overdue
        if calendar.isDateInToday(date) { return RainbowColors.orange }
        if calendar.isDateInTomorrow(date) { return RainbowColors.blue }
        return .gray
    }
}

// MARK: - 👔 STANDARD TASKS
struct StandardTasksView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: AppTheme
    var embedInNavigation: Bool
    
    @Query(sort: [SortDescriptor(\StudyTask.dueDate, order: .forward)]) var allTasks: [StudyTask]
    
    @State private var showingAddTask = false
    @State private var selectedFilter: StandardFilter = .today
    
    enum StandardFilter: String, CaseIterable, Identifiable {
        case today = "Today"
        case all = "All"
        case flagged = "Flagged"
        case done = "Done"
        var id: String { rawValue }
    }
    
    var filteredTasks: [StudyTask] {
        let calendar = Calendar.current
        switch selectedFilter {
        case .today:
            return allTasks.filter { !$0.isCompleted && $0.dueDate != nil && calendar.isDateInToday($0.dueDate!) }
        case .all:
            return allTasks.filter { !$0.isCompleted }
        case .flagged:
            return allTasks.filter { $0.isFlagged && !$0.isCompleted }
        case .done:
            return allTasks.filter { $0.isCompleted }
        }
    }
    
    var body: some View {
        if embedInNavigation {
            NavigationStack { content }
        } else {
            content
        }
    }
    
    @ViewBuilder
    private var content: some View {
        VStack(spacing: 0) {
            Picker("Filter", selection: $selectedFilter) {
                ForEach(StandardFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            List {
                if filteredTasks.isEmpty {
                    ContentUnavailableView { Label("No Tasks", systemImage: "checklist") } description: { Text(emptyStateDescription) }
                } else {
                    ForEach(filteredTasks) { task in
                        TasksStandardRow(task: task, isStandardMode: themeManager.selectedGameMode == .standard)
                            .swipeActions(edge: .leading) {
                                Button { withAnimation { task.isCompleted.toggle() } } label: { Label(task.isCompleted ? "Undo" : "Complete", systemImage: "checkmark") }.tint(.green)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { modelContext.delete(task) } label: { Label("Delete", systemImage: "trash") }
                                Button { task.isFlagged.toggle() } label: { Label("Flag", systemImage: "flag") }.tint(.orange)
                            }
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddTask = true }) { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAddTask) { AddTaskView() }
    }
    
    private var emptyStateDescription: String {
        switch selectedFilter {
        case .today: return "You have no tasks due today."
        case .all: return "No active tasks found."
        case .flagged: return "No flagged tasks."
        case .done: return "No completed tasks yet."
        }
    }
}

struct TasksStandardRow: View {
    let task: StudyTask
    let isStandardMode: Bool
    @State private var showingEdit = false
    
    init(task: StudyTask, isStandardMode: Bool) {
        self.task = task
        self.isStandardMode = isStandardMode
    }
    
    var body: some View {
        HStack {
            Button(action: { withAnimation { task.isCompleted.toggle() } }) {
                Image(systemName: task.isCompleted ? "circle.inset.filled" : "circle")
                    .font(.title2)
                    .foregroundColor(task.isCompleted ? .gray : (task.priority == .high ? .red : .blue))
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 8)
            
            HStack {
                VStack(alignment: .leading) {
                    Text(task.title).strikethrough(task.isCompleted).foregroundColor(task.isCompleted ? .secondary : (isStandardMode ? .primary : .white))
                    HStack {
                        if let subject = task.subject { Text(subject.title).font(.caption).padding(2).background(subject.color.opacity(0.2)).cornerRadius(4) }
                        if let due = task.dueDate {
                            Text(due, style: .date).font(.caption).foregroundColor(isOverdue(due) && !task.isCompleted ? .red : .secondary)
                        }
                    }
                }
                Spacer()
                if task.isFlagged { Image(systemName: "flag.fill").foregroundColor(.orange).font(.caption) }
            }
            .contentShape(Rectangle())
            .onTapGesture { showingEdit = true }
        }
        .sheet(isPresented: $showingEdit) { EditTaskView(task: task) }
    }
    
    private func isOverdue(_ date: Date) -> Bool {
        return date < Date() && !Calendar.current.isDateInToday(date)
    }
}
