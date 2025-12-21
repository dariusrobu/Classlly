import SwiftUI
import SwiftData

struct TasksView: View {
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .rainbow:
                AnyView(RainbowTasksView())
            case .arcade:
                AnyView(ArcadeTasksView())
            case .standard:
                AnyView(StandardTasksView())
            }
        }
    }
}

// MARK: - 🌈 RAINBOW TASKS
struct RainbowTasksView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: AppTheme
    
    @Query var tasks: [StudyTask]
    
    @State private var showingAddTask = false
    @State private var filter: TaskFilter = .all
    
    // ✅ EXPLICIT INIT
    init() {
        // Correctly initializing Query with SortDescriptor
        _tasks = Query(sort: [
            SortDescriptor(\StudyTask.dueDate, order: .forward)
        ])
    }
    
    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case pending = "Todo"
        case completed = "Done"
    }
    
    var filteredTasks: [StudyTask] {
        let currentTasks = switch filter {
        case .all: tasks
        case .pending: tasks.filter { !$0.isCompleted }
        case .completed: tasks.filter { $0.isCompleted }
        }
        
        return currentTasks.sorted {
            if $0.isCompleted != $1.isCompleted { return !$0.isCompleted }
            return ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture)
        }
    }
    
    var body: some View {
        let accent = themeManager.selectedTheme.primaryColor
        
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                RainbowHeader(
                    title: "Tasks",
                    accentColor: accent,
                    showBackButton: false,
                    trailingIcon: "plus",
                    trailingAction: { showingAddTask = true }
                )
                
                HStack {
                    ForEach(TaskFilter.allCases, id: \.self) { f in
                        Button(action: { withAnimation { filter = f } }) {
                            Text(f.rawValue)
                                .font(.caption).fontWeight(.bold).padding(.vertical, 8).padding(.horizontal, 16)
                                .background(filter == f ? accent : Color(white: 0.15))
                                .foregroundColor(filter == f ? .black : .gray).cornerRadius(20)
                        }
                    }
                    Spacer()
                }.padding()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if filteredTasks.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "checklist").font(.system(size: 60)).foregroundColor(Color(white: 0.2))
                                Text("No Tasks").font(.headline).foregroundColor(.gray)
                            }.padding(.top, 50)
                        } else {
                            ForEach(filteredTasks) { task in
                                TasksRainbowRow(task: task, accentColor: accent)
                            }
                        }
                    }.padding(.horizontal).padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showingAddTask) { AddTaskView() }
    }
}

struct TasksRainbowRow: View {
    let task: StudyTask
    let accentColor: Color
    @State private var showEdit = false
    
    // ✅ Explicit Init
    init(task: StudyTask, accentColor: Color) {
        self.task = task
        self.accentColor = accentColor
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Button(action: { withAnimation { task.isCompleted.toggle() } }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(task.isCompleted ? .gray : (task.priority == .high ? RainbowColors.red : accentColor))
            }.padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title).font(.headline).fontWeight(.bold).strikethrough(task.isCompleted).foregroundColor(task.isCompleted ? .gray : .white)
                if let subject = task.subject {
                    Text(subject.title.uppercased()).font(.caption).fontWeight(.bold).padding(4).background(subject.color.opacity(0.2)).foregroundColor(subject.color).cornerRadius(4)
                }
                HStack {
                    if let due = task.dueDate { Label(due.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar") }
                    if task.priority == .high { Label("High Priority", systemImage: "exclamationmark.3").foregroundColor(RainbowColors.red) }
                }.font(.caption).foregroundColor(.gray)
            }
            Spacer()
            Button(action: { showEdit = true }) { Image(systemName: "ellipsis").rotationEffect(.degrees(90)).foregroundColor(.gray).padding() }
        }
        .padding().background(Color(white: 0.1)).cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(task.priority == .high && !task.isCompleted ? RainbowColors.red.opacity(0.5) : Color.clear, lineWidth: 1)).opacity(task.isCompleted ? 0.6 : 1.0)
        .sheet(isPresented: $showEdit) { EditTaskView(task: task) }
    }
}

// MARK: - 👔 STANDARD TASKS
struct StandardTasksView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: AppTheme
    @Query var tasks: [StudyTask]
    @State private var showingAddTask = false
    
    // ✅ Explicit Init
    init() {
        _tasks = Query(sort: [
            SortDescriptor(\StudyTask.dueDate, order: .forward)
        ])
    }
    
    var body: some View {
        NavigationStack {
            List {
                if tasks.isEmpty { ContentUnavailableView("No Tasks", systemImage: "checklist") } else {
                    ForEach(tasks) { task in
                        TasksStandardRow(task: task, isStandardMode: themeManager.selectedGameMode == .standard)
                            .swipeActions(edge: .leading) { Button { task.isCompleted.toggle() } label: { Label(task.isCompleted ? "Undo" : "Complete", systemImage: "checkmark") }.tint(.green) }
                    }
                    .onDelete(perform: deleteTasks)
                }
            }
            .navigationTitle("Tasks")
            .toolbar { ToolbarItem(placement: .primaryAction) { Button(action: { showingAddTask = true }) { Image(systemName: "plus") } } }
            .sheet(isPresented: $showingAddTask) { AddTaskView() }
        }
    }
    private func deleteTasks(offsets: IndexSet) { withAnimation { for index in offsets { modelContext.delete(tasks[index]) } } }
}

struct TasksStandardRow: View {
    let task: StudyTask
    let isStandardMode: Bool
    @State private var showingEdit = false
    
    // ✅ Explicit Init
    init(task: StudyTask, isStandardMode: Bool) {
        self.task = task
        self.isStandardMode = isStandardMode
    }
    
    var body: some View {
        HStack {
            Button(action: { withAnimation { task.isCompleted.toggle() } }) {
                Image(systemName: task.isCompleted ? "circle.inset.filled" : "circle")
                    .foregroundColor(task.isCompleted ? .gray : (task.priority == .high ? .red : .blue))
            }.buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading) {
                Text(task.title).strikethrough(task.isCompleted).foregroundColor(task.isCompleted ? .secondary : (isStandardMode ? .primary : .white))
                HStack {
                    if let subject = task.subject { Text(subject.title).font(.caption).padding(2).background(subject.color.opacity(0.2)).cornerRadius(4) }
                    if let due = task.dueDate { Text(due, style: .date).font(.caption).foregroundColor(due < Date() && !task.isCompleted ? .red : .secondary) }
                }
            }
            Spacer()
            if task.isFlagged { Image(systemName: "flag.fill").foregroundColor(.orange).font(.caption) }
        }
        .contentShape(Rectangle())
        .onTapGesture { showingEdit = true }
        .sheet(isPresented: $showingEdit) { EditTaskView(task: task) }
    }
}

// MARK: - 🕹️ ARCADE TASKS
struct ArcadeTasksView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: AppTheme
    @Query var tasks: [StudyTask]
    @State private var showingAddTask = false
    
    // ✅ Explicit Init
    init() {
        // Sorted only by completion and due date to avoid 'priorityRaw' string crash
        _tasks = Query(sort: [
            SortDescriptor(\StudyTask.dueDate, order: .forward)
        ])
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Text("MISSION LOG").font(.system(size: 30, weight: .black, design: .rounded)).foregroundColor(.cyan)
                        Spacer()
                        Button(action: { showingAddTask = true }) { Image(systemName: "plus").font(.title).foregroundColor(.black).padding(8).background(Color.cyan).cornerRadius(8) }
                    }.padding()
                    
                    if tasks.isEmpty {
                        VStack { Image(systemName: "gamecontroller.fill").font(.largeTitle).foregroundColor(.gray); Text("NO MISSIONS").font(.headline).foregroundColor(.gray) }.padding(.top, 50)
                    }
                    ForEach(tasks) { task in
                        TasksArcadeRow(task: task)
                    }
                }
            }
        }.sheet(isPresented: $showingAddTask) { AddTaskView() }
    }
}

struct TasksArcadeRow: View {
    let task: StudyTask
    @State private var showingEdit = false
    
    // ✅ Explicit Init
    init(task: StudyTask) {
        self.task = task
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: { withAnimation { task.isCompleted.toggle() } }) {
                Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square").font(.title).foregroundColor(task.isCompleted ? .gray : .cyan)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title.uppercased()).font(.system(.headline, design: .monospaced)).fontWeight(.bold).strikethrough(task.isCompleted).foregroundColor(task.isCompleted ? .gray : .white)
                HStack {
                    if let subject = task.subject { Text("[\(subject.title)]").font(.system(size: 10, design: .monospaced)).foregroundColor(.purple) }
                    if task.priority == .high { Text("!!! CRITICAL !!!").font(.system(size: 10, design: .monospaced)).foregroundColor(.red) }
                }
            }
            Spacer()
        }
        .padding().background(Color(white: 0.08)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(task.isCompleted ? Color.gray.opacity(0.3) : Color.cyan.opacity(0.5), lineWidth: 1)).padding(.horizontal)
        .onTapGesture { showingEdit = true }
        .sheet(isPresented: $showingEdit) { EditTaskView(task: task) }
    }
}
