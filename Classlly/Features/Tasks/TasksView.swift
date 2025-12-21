import SwiftUI
import SwiftData

struct TasksView: View {
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .rainbow:
                RainbowTasksView()
            default:
                StandardTasksView()
            }
        }
    }
}

// MARK: - 🌈 RAINBOW INTERFACE
struct RainbowTasksView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: AppTheme
    
    @Query(sort: \StudyTask.dueDate, order: .forward) private var allTasks: [StudyTask]
    @State private var selectedFilter: TaskFilter = .today
    @State private var showingAddTask = false
    
    // Custom Filter Enum
    enum TaskFilter: String, CaseIterable {
        case today = "Today"
        case all = "All Tasks"
        case flagged = "Flagged"
        case completed = "Done"
        
        var icon: String {
            switch self {
            case .today: return "calendar"
            case .all: return "tray.full.fill"
            case .flagged: return "flag.fill"
            case .completed: return "checkmark.circle.fill"
            }
        }
    }
    
    var filteredTasks: [StudyTask] {
        switch selectedFilter {
        case .today: return allTasks.filter { guard let d = $0.dueDate else { return false }; return Calendar.current.isDateInToday(d) && !$0.isCompleted }
        case .all: return allTasks.filter { !$0.isCompleted }
        case .flagged: return allTasks.filter { $0.isFlagged && !$0.isCompleted }
        case .completed: return allTasks.filter { $0.isCompleted }
        }
    }
    
    var body: some View {
        let accent = themeManager.selectedTheme.primaryColor
        
        ZStack {
            // 1. Dynamic Background
            Color.black.ignoresSafeArea()
            RadialGradient(colors: [accent.opacity(0.3), .black], center: .topLeading, startRadius: 0, endRadius: 600)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 2. Custom Header
                HStack {
                    Text("MY TASKS")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    // Filter Status Indicator
                    Text("\(filteredTasks.count)")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(accent)
                        .padding(8)
                        .background(Color(white: 0.1))
                        .clipShape(Circle())
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // 3. Horizontal Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(TaskFilter.allCases, id: \.self) { filter in
                            Button(action: { withAnimation(.spring()) { selectedFilter = filter } }) {
                                HStack(spacing: 6) {
                                    Image(systemName: filter.icon)
                                    Text(filter.rawValue)
                                }
                                .font(.system(size: 14, weight: .bold))
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .background(selectedFilter == filter ? accent : Color(white: 0.1))
                                .foregroundColor(selectedFilter == filter ? .white : .gray)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(selectedFilter == filter ? Color.white.opacity(0.5) : Color.clear, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // 4. Task List (Cards)
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if filteredTasks.isEmpty {
                            EmptyStateView(icon: selectedFilter.icon, message: "No tasks found here")
                                .padding(.top, 50)
                        } else {
                            ForEach(filteredTasks) { task in
                                RainbowTaskCard(task: task, accent: accent)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100) // Space for FAB
                }
            }
            
            // 5. Floating Action Button (FAB)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(
                                LinearGradient(colors: [accent, accent.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .clipShape(Circle())
                            .shadow(color: accent.opacity(0.5), radius: 10, x: 0, y: 5)
                            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                    }
                    .padding(20)
                }
            }
        }
        .sheet(isPresented: $showingAddTask) { AddTaskView() }
    }
}

struct RainbowTaskCard: View {
    @Bindable var task: StudyTask
    let accent: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Checkbox
            Button(action: { withAnimation { task.isCompleted.toggle() } }) {
                ZStack {
                    Circle()
                        .stroke(task.isCompleted ? accent : Color.gray, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if task.isCompleted {
                        Circle().fill(accent).frame(width: 14, height: 14)
                    }
                }
            }
            .padding(.top, 4)
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .gray : .white)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    if let subject = task.subject {
                        Text(subject.title.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(subject.color.opacity(0.2))
                            .foregroundColor(subject.color)
                            .cornerRadius(4)
                    }
                    
                    if let date = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(date.formatted(.dateTime.month().day().hour().minute()))
                        }
                        .font(.caption)
                        .foregroundColor(date < Date() && !task.isCompleted ? .red : .gray)
                    }
                    
                    if task.isFlagged {
                        Image(systemName: "flag.fill").font(.caption).foregroundColor(.orange)
                    }
                }
            }
            Spacer()
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(task.isCompleted ? Color.clear : accent.opacity(0.3), lineWidth: 1)
        )
        .opacity(task.isCompleted ? 0.6 : 1.0)
    }
}

struct EmptyStateView: View {
    let icon: String
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))
            Text(message)
                .font(.headline)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - 👔 STANDARD & ARCADE INTERFACE
// (This preserves your original clean layout for standard modes)
struct StandardTasksView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: AppTheme
    
    @Query(sort: \StudyTask.dueDate, order: .forward) private var allTasks: [StudyTask]
    @State private var selectedFilter: TaskFilter = .today
    @State private var showingAddTask = false
    
    enum TaskFilter { case today, all, flagged, completed }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                if themeManager.selectedGameMode == .arcade {
                    Color.black.ignoresSafeArea()
                } else {
                    Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                }
                
                VStack(spacing: 0) {
                    // Filter Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        StandardFilterCard(title: "Today", icon: "calendar", count: tasksForFilter(.today).count, color: .blue, isSelected: selectedFilter == .today) { selectedFilter = .today }
                        StandardFilterCard(title: "All", icon: "tray.fill", count: allTasks.count, color: .gray, isSelected: selectedFilter == .all) { selectedFilter = .all }
                        StandardFilterCard(title: "Flagged", icon: "flag.fill", count: tasksForFilter(.flagged).count, color: .orange, isSelected: selectedFilter == .flagged) { selectedFilter = .flagged }
                        StandardFilterCard(title: "Completed", icon: "checkmark", count: tasksForFilter(.completed).count, color: .green, isSelected: selectedFilter == .completed) { selectedFilter = .completed }
                    }
                    .padding([.horizontal, .top])
                    
                    // Task List
                    VStack(alignment: .leading, spacing: 0) {
                        Text(filterTitle)
                            .font(.title3).fontWeight(.bold)
                            .foregroundColor(themeManager.selectedGameMode == .none ? .primary : .white)
                            .padding(.horizontal, 20).padding(.top, 15)
                        
                        List {
                            let tasks = tasksForFilter(selectedFilter)
                            if tasks.isEmpty {
                                ContentUnavailableView("No Tasks", systemImage: "checklist")
                                    .listRowBackground(Color.clear)
                            } else {
                                ForEach(tasks) { task in
                                    StandardTaskRow(task: task)
                                        .listRowBackground(themeManager.selectedGameMode == .none ? Color(uiColor: .secondarySystemGroupedBackground) : Color.white.opacity(0.1))
                                }
                                .onDelete(perform: deleteTasks)
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus")
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.selectedTheme.primaryColor)
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) { AddTaskView() }
        }
    }
    
    private var filterTitle: String {
        switch selectedFilter {
        case .today: return "Today"
        case .all: return "All Tasks"
        case .flagged: return "Flagged"
        case .completed: return "Completed"
        }
    }
    
    private func tasksForFilter(_ filter: TaskFilter) -> [StudyTask] {
        switch filter {
        case .today: return allTasks.filter { guard let d = $0.dueDate else { return false }; return Calendar.current.isDateInToday(d) && !$0.isCompleted }
        case .all: return allTasks.filter { !$0.isCompleted }
        case .flagged: return allTasks.filter { $0.isFlagged && !$0.isCompleted }
        case .completed: return allTasks.filter { $0.isCompleted }
        }
    }
    
    private func deleteTasks(offsets: IndexSet) {
        let filteredTasks = tasksForFilter(selectedFilter)
        for index in offsets { modelContext.delete(filteredTasks[index]) }
    }
}

struct StandardFilterCard: View {
    let title: String; let icon: String; let count: Int; let color: Color; let isSelected: Bool; let action: () -> Void
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: icon).foregroundColor(.white).frame(width: 28, height: 28).background(color).clipShape(Circle())
                    Spacer()
                    Text("\(count)").font(.title3).fontWeight(.bold).foregroundColor(themeManager.selectedGameMode == .none ? .primary : .white)
                }
                Text(title).font(.caption).fontWeight(.semibold).foregroundColor(themeManager.selectedGameMode == .none ? .secondary : .white.opacity(0.7))
            }
            .padding(10)
            .background(themeManager.selectedGameMode == .none ? Color(uiColor: .secondarySystemGroupedBackground) : Color.white.opacity(0.1))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? color : Color.clear, lineWidth: 2))
        }.buttonStyle(.plain)
    }
}

struct StandardTaskRow: View {
    @Bindable var task: StudyTask
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: { task.isCompleted.toggle() }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : (themeManager.selectedGameMode == .none ? .secondary : .white.opacity(0.5)))
            }.buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title).strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : (themeManager.selectedGameMode == .none ? .primary : .white))
                if let date = task.dueDate {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption).foregroundColor(date < Date() && !task.isCompleted ? .red : .secondary)
                }
            }
            Spacer()
            if task.isFlagged { Image(systemName: "flag.fill").foregroundColor(.orange).font(.caption) }
        }.padding(.vertical, 4)
    }
}
