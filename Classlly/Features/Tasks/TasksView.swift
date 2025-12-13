import SwiftUI
import SwiftData

struct TasksView: View {
    @EnvironmentObject var themeManager: AppTheme
    var embedInNavigationStack: Bool = true
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .rainbow:
                RainbowTasksView(embedInNavigationStack: embedInNavigationStack)
            case .arcade:
                ArcadeTasksView()
            case .none:
                StandardTasksView()
            }
        }
    }
}

// MARK: - 🌈 RAINBOW TASKS (Custom Header & Dynamic Color)
struct RainbowTasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var tasks: [StudyTask]
    @EnvironmentObject var themeManager: AppTheme
    
    @State private var showingAddTask = false
    @State private var editingTask: StudyTask?
    @State private var taskFilter: TaskFilter = .today
    
    var embedInNavigationStack: Bool = true
    
    // Vibrant palette for tasks to cycle through
    private let cardColors: [Color] = [
        RainbowColors.blue,
        RainbowColors.orange,
        RainbowColors.green,
        RainbowColors.purple,
        Color.pink,
        Color.teal,
        Color.indigo
    ]
    
    var body: some View {
        // Dynamic Accent Color
        let accentColor = themeManager.selectedTheme.primaryColor
        
        VStack(spacing: 0) {
            // CUSTOM HEADER
            RainbowHeader(
                title: "Tasks",
                accentColor: accentColor,
                showBackButton: !embedInNavigationStack,
                backAction: { dismiss() },
                trailingIcon: "plus",
                trailingAction: { showingAddTask = true }
            )
            
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // 1. Filter Bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(TaskFilter.allCases, id: \.self) { filter in
                                Button(action: { withAnimation { taskFilter = filter } }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: filter.iconName)
                                        Text(filter.rawValue)
                                    }
                                    .font(.subheadline)
                                    .fontWeight(taskFilter == filter ? .bold : .medium)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 16)
                                    // Active filter uses dynamic accent color
                                    .background(taskFilter == filter ? accentColor : RainbowColors.darkCard)
                                    .foregroundColor(taskFilter == filter ? .white : .gray)
                                    .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 10)
                    
                    // 2. Task List
                    if filteredTasks.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "checklist")
                                .font(.system(size: 60))
                                .foregroundColor(RainbowColors.darkCard.opacity(2))
                            Text("No tasks found")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(Array(filteredTasks.enumerated()), id: \.element.id) { index, task in
                                    // Cycle through colors for solid cards
                                    let color = cardColors[index % cardColors.count]
                                    
                                    RainbowTaskCard(task: task, color: color)
                                        .onTapGesture { editingTask = task }
                                        .contextMenu {
                                            Button { editingTask = task } label: { Label("Edit", systemImage: "pencil") }
                                            Button(role: .destructive) { modelContext.delete(task) } label: { Label("Delete", systemImage: "trash") }
                                        }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .navigationBarHidden(true) // HIDE SYSTEM NAV BAR
        .sheet(isPresented: $showingAddTask) { AddTaskView() }
        .sheet(item: $editingTask) { task in EditTaskView(task: task) }
    }
    
    var filteredTasks: [StudyTask] {
        let calendar = Calendar.current; let now = Date()
        switch taskFilter {
        case .today: return tasks.filter { guard let d = $0.dueDate else { return false }; return !$0.isCompleted && calendar.isDate(d, inSameDayAs: now) }.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
        case .flagged: return tasks.filter { $0.isFlagged && !$0.isCompleted }.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
        case .all: return tasks.filter { !$0.isCompleted }.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
        case .completed: return tasks.filter { $0.isCompleted }.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
        }
    }
}

// Local Component: Solid Colorful Task Card
struct RainbowTaskCard: View {
    @Bindable var task: StudyTask
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Checkbox (White on colored card looks clean)
            Button(action: { withAnimation { task.isCompleted.toggle() } }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .strikethrough(task.isCompleted)
                
                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
                
                HStack(spacing: 12) {
                    if let subjectTitle = task.subject?.title {
                        HStack(spacing: 4) {
                            Image(systemName: "book.fill").font(.caption2)
                            Text(subjectTitle).font(.caption).fontWeight(.semibold)
                        }
                        .foregroundColor(.white.opacity(0.9))
                    }
                    
                    if let dueDate = task.dueDate {
                        Text(formatDueDate(dueDate))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            
            Spacer()
            
            // Priority Indicator or Arrow
            if task.priority == .high && !task.isCompleted {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.white)
                    .font(.caption)
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(20)
        .background(task.isCompleted ? Color(white: 0.2) : color) // Turn gray if completed
        .cornerRadius(20)
        .shadow(color: (task.isCompleted ? Color.black : color).opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d"; return "Due \(f.string(from: date))"
    }
}

// ... (Rest of Standard/Arcade/Retro views unchanged)
// [Preserving existing code]

struct StandardTasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @State private var showingAddTask = false
    @State private var editingTask: StudyTask?
    @State private var taskFilter: TaskFilter = .today
    @Query private var tasks: [StudyTask]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(TaskFilter.allCases, id: \.self) { filter in
                            FilterButton(title: filter.rawValue, iconName: filter.iconName, color: filter.selectionColor, isSelected: taskFilter == filter) { withAnimation { taskFilter = filter } }
                        }
                    }.padding()
                }
                if filteredTasks.isEmpty { TasksEmptyStateView(filter: taskFilter) }
                else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredTasks) { task in
                                TaskCard(task: task)
                                    .onTapGesture { editingTask = task }
                                    .contextMenu { Button { editingTask = task } label: { Label("Edit", systemImage: "pencil") }; Button(role: .destructive) { modelContext.delete(task) } label: { Label("Delete", systemImage: "trash") } }
                                if task != filteredTasks.last { Divider().padding(.leading, 56) }
                            }
                        }.padding(.vertical).background(Color.themeSurface).cornerRadius(16).padding(.horizontal)
                    }
                }
            }
            .background(Color.themeBackground)
            .navigationTitle("Tasks").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button(action: { showingAddTask = true }) { Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(.themePrimary) } } }
            .sheet(isPresented: $showingAddTask) { AddTaskView() }
            .sheet(item: $editingTask) { task in EditTaskView(task: task) }
        }
    }
    
    var filteredTasks: [StudyTask] {
        let calendar = Calendar.current; let now = Date()
        switch taskFilter {
        case .today: return tasks.filter { guard let d = $0.dueDate else { return false }; return !$0.isCompleted && calendar.isDate(d, inSameDayAs: now) }.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
        case .flagged: return tasks.filter { $0.isFlagged && !$0.isCompleted }.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
        case .all: return tasks.filter { !$0.isCompleted }.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
        case .completed: return tasks.filter { $0.isCompleted }.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
        }
    }
}

struct ArcadeTasksView: View {
    @Environment(\.modelContext) private var modelContext; @Query private var tasks: [StudyTask]
    @State private var showingAddTask = false; @State private var editingTask: StudyTask?; @State private var taskFilter: TaskFilter = .today
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 20) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(TaskFilter.allCases, id: \.self) { filter in
                                Button(action: { withAnimation { taskFilter = filter } }) {
                                    HStack { Image(systemName: filter.iconName); Text(filter.rawValue.uppercased()).font(.system(.caption, design: .rounded)).fontWeight(.bold) }
                                    .padding(.horizontal, 16).padding(.vertical, 8)
                                    .background(taskFilter == filter ? filter.selectionColor : Color.white.opacity(0.1)).foregroundColor(taskFilter == filter ? .white : .gray).cornerRadius(20)
                                }
                            }
                        }.padding(.horizontal).padding(.top)
                    }
                    if filteredTasks.isEmpty { VStack(spacing: 16) { Image(systemName: "trophy.fill").font(.system(size: 50)).foregroundColor(.yellow); Text("NO ACTIVE QUESTS").font(.system(.title3, design: .rounded)).fontWeight(.black).foregroundColor(.white) }.frame(maxWidth: .infinity, maxHeight: .infinity) }
                    else { ScrollView { LazyVStack(spacing: 16) { ForEach(filteredTasks) { task in ArcadeTaskRow(task: task).onTapGesture { editingTask = task } } }.padding(.horizontal) } }
                }
            }
            .navigationTitle("Quest Board").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button(action: { showingAddTask = true }) { Image(systemName: "plus.circle.fill").foregroundColor(.cyan) } } }
            .sheet(isPresented: $showingAddTask) { AddTaskView() }.sheet(item: $editingTask) { task in EditTaskView(task: task) }
        }.preferredColorScheme(.dark)
    }
    
    var filteredTasks: [StudyTask] {
        let calendar = Calendar.current; let now = Date()
        switch taskFilter {
        case .today: return tasks.filter { guard let d = $0.dueDate else { return false }; return !$0.isCompleted && calendar.isDate(d, inSameDayAs: now) }.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
        case .flagged: return tasks.filter { $0.isFlagged && !$0.isCompleted }.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
        case .all: return tasks.filter { !$0.isCompleted }.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
        case .completed: return tasks.filter { $0.isCompleted }.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
        }
    }
}

struct ArcadeTaskRow: View {
    let task: StudyTask
    var body: some View {
        HStack(spacing: 16) {
            Circle().strokeBorder(task.priority.color, lineWidth: 2).background(Circle().fill(task.priority.color.opacity(0.2))).frame(width: 32, height: 32).overlay(Image(systemName: task.isCompleted ? "checkmark" : task.priority.iconName).font(.system(size: 14, weight: .bold)).foregroundColor(task.isCompleted ? .white : task.priority.color))
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title).font(.system(.body, design: .rounded)).fontWeight(.bold).foregroundColor(task.isCompleted ? .gray : .white).strikethrough(task.isCompleted)
                if !task.notes.isEmpty { Text("INTEL: \(task.notes)").font(.caption).foregroundColor(.gray).lineLimit(1) }
                HStack { if let sub = task.subject { Text(sub.title).foregroundColor(.cyan) }; if let d = task.dueDate { Text("• \(formatDate(d))").foregroundColor(.gray) } }.font(.caption).fontWeight(.medium)
            }
            Spacer()
        }.padding().background(Color(white: 0.1)).cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(task.isCompleted ? Color.gray.opacity(0.3) : task.priority.color.opacity(0.3), lineWidth: 1))
    }
    private func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.dateFormat = "MMM d"; return f.string(from: date) }
}

struct RetroTasksView: View {
    @Environment(\.modelContext) private var modelContext; @Query private var tasks: [StudyTask]
    @State private var showingAddTask = false; @State private var editingTask: StudyTask?; @State private var taskFilter: TaskFilter = .today
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.05).ignoresSafeArea()
                VStack(spacing: 20) {
                    ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 0) { ForEach(TaskFilter.allCases, id: \.self) { filter in Button(action: { taskFilter = filter }) { Text("[\(filter.rawValue.uppercased())]").font(.system(.caption, design: .monospaced)).fontWeight(taskFilter == filter ? .bold : .regular).foregroundColor(taskFilter == filter ? .green : .gray).padding(8).background(taskFilter == filter ? Color.green.opacity(0.2) : Color.clear) } } }.padding(.horizontal).padding(.top).overlay(Rectangle().frame(height: 1).foregroundColor(.green), alignment: .bottom) }
                    if filteredTasks.isEmpty { VStack(spacing: 16) { Text("> SYSTEM_IDLE").font(.system(.title, design: .monospaced)).foregroundColor(.green); Text("No active processes.").font(.system(.body, design: .monospaced)).foregroundColor(.gray) }.frame(maxWidth: .infinity, maxHeight: .infinity) }
                    else { ScrollView { LazyVStack(spacing: 0) { ForEach(filteredTasks) { task in RetroTaskRow(task: task).onTapGesture { editingTask = task } } }.padding() } }
                }
            }
            .navigationTitle("CMD_TASKS").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button(action: { showingAddTask = true }) { Text("[ ADD ]").font(.system(.caption, design: .monospaced)).foregroundColor(.green) } } }
            .sheet(isPresented: $showingAddTask) { AddTaskView() }.sheet(item: $editingTask) { task in EditTaskView(task: task) }
        }.preferredColorScheme(.dark)
    }
    var filteredTasks: [StudyTask] {
        let calendar = Calendar.current; let now = Date()
        switch taskFilter {
        case .today: return tasks.filter { guard let d = $0.dueDate else { return false }; return !$0.isCompleted && calendar.isDate(d, inSameDayAs: now) }.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
        case .flagged: return tasks.filter { $0.isFlagged && !$0.isCompleted }.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
        case .all: return tasks.filter { !$0.isCompleted }.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
        case .completed: return tasks.filter { $0.isCompleted }.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
        }
    }
}

struct RetroTaskRow: View {
    let task: StudyTask
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(task.isCompleted ? "[X]" : "[ ]").font(.system(.body, design: .monospaced)).foregroundColor(task.isCompleted ? .gray : .green)
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title.uppercased()).font(.system(.body, design: .monospaced)).foregroundColor(task.isCompleted ? .gray : .white).strikethrough(task.isCompleted)
                if !task.notes.isEmpty { Text("> DATA: \(task.notes)").font(.system(size: 10, design: .monospaced)).foregroundColor(.gray).lineLimit(1) }
                HStack { if let s = task.subject { Text("SUB: \(s.title)") }; if let d = task.dueDate { Text("DUE: \(formatDate(d))") } }.font(.system(size: 10, design: .monospaced)).foregroundColor(.gray)
            }
            Spacer()
        }.padding(.vertical, 12).overlay(Rectangle().frame(height: 1).foregroundColor(Color.green.opacity(0.3)), alignment: .bottom)
    }
    private func formatDate(_ date: Date) -> String { let f = DateFormatter(); f.dateFormat = "MM-dd"; return f.string(from: date) }
}

enum TaskFilter: String, CaseIterable {
    case today = "Today"; case flagged = "Flagged"; case all = "All"; case completed = "Completed"
    var iconName: String { switch self { case .today: return "sun.max.fill"; case .flagged: return "flag.fill"; case .all: return "tray.fill"; case .completed: return "checkmark.circle.fill" } }
    var selectionColor: Color { switch self { case .today: return .themePrimary; case .flagged: return .themeError; case .all: return .themePrimary; case .completed: return .themeSuccess } }
}
struct FilterButton: View {
    let title: String; let iconName: String; let color: Color; let isSelected: Bool; let action: () -> Void
    var body: some View { Button(action: action) { HStack(spacing: 6) { Image(systemName: iconName).font(.caption); Text(title) }.font(.subheadline).fontWeight(isSelected ? .bold : .medium).foregroundColor(isSelected ? color : .themeTextSecondary).padding(.vertical, 8).padding(.horizontal, 12).background(RoundedRectangle(cornerRadius: 10).fill(color.opacity(isSelected ? 0.1 : 0.0))).overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? color : Color.adaptiveBorder, lineWidth: 1)) }.buttonStyle(PlainButtonStyle()) }
}
struct TasksEmptyStateView: View {
    let filter: TaskFilter
    var body: some View { VStack(spacing: 12) { Image(systemName: "checkmark.circle").font(.system(size: 40)).foregroundColor(.themeTextSecondary); Text(title).font(.headline).foregroundColor(.themeTextPrimary); Text(message).font(.subheadline).foregroundColor(.themeTextSecondary).multilineTextAlignment(.center) }.frame(maxWidth: .infinity, maxHeight: .infinity) }
    var title: String { switch filter { case .today: return "No Tasks Today"; case .flagged: return "No Flagged Tasks"; case .all: return "No Active Tasks"; case .completed: return "No Completed Tasks" } }
    var message: String { switch filter { case .today: return "You have no tasks due today."; case .flagged: return "Flag a task to see it here."; case .all: return "All tasks are completed! 🎉"; case .completed: return "Completed tasks will appear here." } }
}
struct TaskCard: View {
    @Bindable var task: StudyTask; @Environment(\.colorScheme) var colorScheme
    var body: some View { HStack(spacing: 16) { Button(action: { withAnimation { task.isCompleted.toggle() } }) { ZStack { Circle().stroke(task.priority.color, lineWidth: 2).frame(width: 24, height: 24); if task.isCompleted { Circle().fill(task.priority.color).frame(width: 24, height: 24); Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(.white) } } }.buttonStyle(PlainButtonStyle()); VStack(alignment: .leading, spacing: 4) { Text(task.title).font(.body).fontWeight(.medium).foregroundColor(task.isCompleted ? .themeTextSecondary : .themeTextPrimary).strikethrough(task.isCompleted); if !task.notes.isEmpty { Text(task.notes).font(.caption).foregroundColor(.themeTextSecondary).lineLimit(1) }; HStack(spacing: 12) { if let subjectTitle = task.subject?.title { Text(subjectTitle).font(.caption).foregroundColor(.themeTextSecondary) }; if let dueDate = task.dueDate { Text(formatDueDate(dueDate)).font(.caption).foregroundColor(dueDate < Date() && !task.isCompleted ? .themeError : .themeTextSecondary) } } }; Spacer() }.padding() }
    private func formatDueDate(_ date: Date) -> String { let f = DateFormatter(); f.dateFormat = "MMM d"; return f.string(from: date) }
}
