import SwiftUI
import SwiftData

struct TasksView: View {
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .rainbow:
                RainbowTasksView()
            case .arcade:
                ArcadeTasksView()
            case .none:
                StandardTasksView()
            }
        }
    }
}

// MARK: - 🌈 RAINBOW TASKS
struct RainbowTasksView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: AppTheme
    
    @Query(sort: \StudyTask.dueDate, order: .forward)
    var tasks: [StudyTask]
    
    @State private var showAddTask = false
    @State private var taskToEdit: StudyTask? // Tracks task for sheet
    @State private var selectedFilter: TaskFilter = .active
    
    enum TaskFilter: String, CaseIterable {
        case active = "Active"
        case today = "Today"
        case completed = "Done"
    }
    
    var filteredTasks: [StudyTask] {
        let calendar = Calendar.current
        let filtered = tasks.filter { task in
            switch selectedFilter {
            case .active: return !task.isCompleted
            case .today: return !task.isCompleted && calendar.isDateInToday(task.dueDate ?? Date.distantPast)
            case .completed: return task.isCompleted
            }
        }
        return filtered.sorted { t1, t2 in
            if selectedFilter != .completed && t1.priority != t2.priority { return t1.priority == .high }
            return (t1.dueDate ?? Date.distantFuture) < (t2.dueDate ?? Date.distantFuture)
        }
    }
    
    var body: some View {
        let accent = themeManager.selectedTheme.primaryColor
        
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("MISSION LOG").font(.system(size: 10, weight: .black)).foregroundColor(accent).tracking(2)
                            Text("TASKS").font(.system(size: 34, weight: .black)).foregroundColor(.white)
                        }
                        Spacer()
                        Button(action: { showAddTask = true }) {
                            Image(systemName: "plus").font(.title2).fontWeight(.bold).foregroundColor(.black)
                                .padding(12).background(accent).clipShape(Circle()).shadow(color: accent.opacity(0.6), radius: 10)
                        }
                    }.padding(.horizontal).padding(.top, 10)
                    
                    // Filter Tabs
                    HStack(spacing: 0) {
                        ForEach(TaskFilter.allCases, id: \.self) { filter in
                            Button(action: { withAnimation { selectedFilter = filter } }) {
                                VStack(spacing: 8) {
                                    Text(filter.rawValue.uppercased()).font(.system(size: 12, weight: .bold))
                                        .foregroundColor(selectedFilter == filter ? .white : .gray)
                                    Rectangle().fill(selectedFilter == filter ? accent : Color.clear).frame(height: 2).shadow(color: accent.opacity(0.8), radius: 4)
                                }
                            }.frame(maxWidth: .infinity)
                        }
                    }.padding(.top, 20).padding(.bottom, 10).background(Color.black)
                    
                    // List
                    if filteredTasks.isEmpty {
                        VStack(spacing: 20) {
                            Spacer()
                            Image(systemName: selectedFilter == .completed ? "checkmark.circle.fill" : "checklist")
                                .font(.system(size: 60))
                                .foregroundStyle(LinearGradient(colors: [accent, accent.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                            Text("NO TASKS").font(.headline).fontWeight(.black).foregroundColor(.gray)
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredTasks) { task in
                                    RainbowTaskFullRow(task: task, accentColor: accent)
                                        .onTapGesture { taskToEdit = task }
                                        .contextMenu {
                                            Button { taskToEdit = task } label: { Label("Edit", systemImage: "pencil") }
                                            Button(role: .destructive) { withAnimation { modelContext.delete(task) } } label: { Label("Delete", systemImage: "trash") }
                                        }
                                }
                            }.padding(.horizontal).padding(.top, 10).padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddTask) { AddTaskView() }
            .sheet(item: $taskToEdit) { task in AddTaskView(taskToEdit: task) } // ✅ Now works
        }
    }
}

struct RainbowTaskFullRow: View {
    @Bindable var task: StudyTask
    let accentColor: Color
    var body: some View {
        HStack(spacing: 16) {
            Button(action: { withAnimation(.spring) { task.isCompleted.toggle() } }) {
                ZStack {
                    Circle().stroke(task.isCompleted ? RainbowColors.green : Color.gray, lineWidth: 2).frame(width: 24, height: 24)
                    if task.isCompleted { Circle().fill(RainbowColors.green).frame(width: 14, height: 14) }
                }
            }.buttonStyle(PlainButtonStyle())
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title).font(.headline).fontWeight(.bold).strikethrough(task.isCompleted).foregroundColor(task.isCompleted ? .gray : .white)
                HStack(spacing: 8) {
                    if let subject = task.subject { Text(subject.title.uppercased()).font(.system(size: 8, weight: .black)).padding(.horizontal, 6).padding(.vertical, 3).background(subject.color.opacity(0.2)).foregroundColor(subject.color).cornerRadius(4) }
                    if let due = task.dueDate { HStack(spacing: 4) { Image(systemName: "calendar"); Text(due.formatted(date: .numeric, time: .omitted)) }.font(.caption2).fontWeight(.bold).foregroundColor(due < Date() && !task.isCompleted ? RainbowColors.red : .gray) }
                }
            }
            Spacer()
            if task.priority == .high && !task.isCompleted { Image(systemName: "exclamationmark.triangle.fill").foregroundColor(RainbowColors.red).shadow(color: RainbowColors.red.opacity(0.5), radius: 5) }
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray.opacity(0.5))
        }.padding().background(Color(white: 0.1)).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(task.isCompleted ? Color.clear : (task.priority == .high ? RainbowColors.red.opacity(0.3) : Color(white: 0.2)), lineWidth: 1))
        .opacity(task.isCompleted ? 0.6 : 1.0).contentShape(Rectangle())
    }
}

// MARK: - 🏠 STANDARD TASKS
struct StandardTasksView: View {
    @EnvironmentObject var themeManager: AppTheme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StudyTask.dueDate, order: .forward) var tasks: [StudyTask]
    @State private var showAddTask = false
    @State private var taskToEdit: StudyTask?
    @State private var filter: FilterOption = .active
    
    enum FilterOption: String, CaseIterable { case active = "To Do"; case completed = "Done" }
    var filteredTasks: [StudyTask] { tasks.filter { filter == .active ? !$0.isCompleted : $0.isCompleted } }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Filter", selection: $filter) { ForEach(FilterOption.allCases, id: \.self) { option in Text(option.rawValue).tag(option) } }.pickerStyle(.segmented).padding()
                List {
                    if filteredTasks.isEmpty { ContentUnavailableView("No Tasks", systemImage: "checklist") } else {
                        ForEach(filteredTasks) { task in
                            StandardTaskRowView(task: task).onTapGesture { taskToEdit = task }
                        }.onDelete(perform: deleteTask)
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar { ToolbarItem(placement: .primaryAction) { Button(action: { showAddTask = true }) { Image(systemName: "plus.circle.fill").font(.system(size: 22)) } } }
            .sheet(isPresented: $showAddTask) { AddTaskView() }
            .sheet(item: $taskToEdit) { task in AddTaskView(taskToEdit: task) } // ✅ Now works
        }
    }
    private func deleteTask(at offsets: IndexSet) { for index in offsets { modelContext.delete(filteredTasks[index]) } }
}

struct StandardTaskRowView: View {
    @Bindable var task: StudyTask
    var body: some View {
        HStack {
            Button(action: { withAnimation { task.isCompleted.toggle() } }) { Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle").foregroundColor(task.isCompleted ? .green : .secondary).font(.title3) }.buttonStyle(PlainButtonStyle())
            VStack(alignment: .leading) { Text(task.title).strikethrough(task.isCompleted).foregroundColor(task.isCompleted ? .secondary : .primary); if let due = task.dueDate { Text(due.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundColor(due < Date() && !task.isCompleted ? .red : .secondary) } }
            Spacer()
            if task.priority == .high { Image(systemName: "exclamationmark").foregroundColor(.red).font(.caption) }
        }.contentShape(Rectangle())
    }
}

// MARK: - 🕹️ ARCADE TASKS (Stub)
struct ArcadeTasksView: View {
    var body: some View {
        ZStack { Color.black.ignoresSafeArea(); Text("Arcade Tasks").font(.system(.title, design: .monospaced)).foregroundColor(.cyan) }
    }
}
