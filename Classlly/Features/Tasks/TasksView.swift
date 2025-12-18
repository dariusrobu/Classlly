import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: AppTheme
    
    // Fetch all tasks for local filtering
    @Query(sort: \StudyTask.dueDate, order: .forward) private var allTasks: [StudyTask]
    
    @State private var selectedFilter: TaskFilter = .all
    @State private var showingAddTask = false
    
    enum TaskFilter {
        case today, all, flagged, completed
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background adaptation based on GameMode
                if themeManager.selectedGameMode != .none {
                    Color.black.ignoresSafeArea()
                } else {
                    Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                }
                
                VStack(spacing: 0) {
                    // --- 1. Compact Smart List Grid (Apple Reminders Style) ---
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        FilterCard(
                            title: "Today",
                            icon: "calendar",
                            count: tasksForFilter(.today).count,
                            color: .blue,
                            isSelected: selectedFilter == .today
                        ) { selectedFilter = .today }
                        
                        FilterCard(
                            title: "All",
                            icon: "tray.fill",
                            count: allTasks.count,
                            color: .gray,
                            isSelected: selectedFilter == .all
                        ) { selectedFilter = .all }
                        
                        FilterCard(
                            title: "Flagged",
                            icon: "flag.fill",
                            count: tasksForFilter(.flagged).count,
                            color: .orange,
                            isSelected: selectedFilter == .flagged
                        ) { selectedFilter = .flagged }
                        
                        FilterCard(
                            title: "Completed",
                            icon: "checkmark",
                            count: tasksForFilter(.completed).count,
                            color: .green,
                            isSelected: selectedFilter == .completed
                        ) { selectedFilter = .completed }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    
                    // --- 2. Task List Section ---
                    VStack(alignment: .leading, spacing: 0) {
                        Text(filterTitle)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.selectedGameMode == .none ? .primary : .white)
                            .padding(.horizontal, 20)
                            .padding(.top, 15)
                        
                        List {
                            let tasks = tasksForFilter(selectedFilter)
                            if tasks.isEmpty {
                                ContentUnavailableView("No Tasks", systemImage: "checklist")
                                    .listRowBackground(Color.clear)
                            } else {
                                ForEach(tasks) { task in
                                    // ✅ TaskRowView is now defined within this file scope
                                    TaskRowView(task: task)
                                        .listRowBackground(themeManager.selectedGameMode == .none ? Color(uiColor: .secondarySystemGroupedBackground) : Color(white: 0.1))
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
            .navigationBarTitleDisplayMode(.inline) // Centralized title like Subjects tab
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.headline)
                            .foregroundColor(themeManager.selectedTheme.primaryColor)
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
        }
    }
    
    // MARK: - Logic Helpers
    
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
        case .today:
            return allTasks.filter { task in
                guard let date = task.dueDate else { return false }
                return Calendar.current.isDateInToday(date) && !task.isCompleted
            }
        case .all:
            return allTasks.filter { !$0.isCompleted }
        case .flagged:
            return allTasks.filter { $0.isFlagged && !$0.isCompleted }
        case .completed:
            return allTasks.filter { $0.isCompleted }
        }
    }
    
    private func deleteTasks(offsets: IndexSet) {
        let filteredTasks = tasksForFilter(selectedFilter)
        for index in offsets {
            modelContext.delete(filteredTasks[index])
        }
    }
}

// MARK: - Filter Card Component
struct FilterCard: View {
    let title: String
    let icon: String
    let count: Int
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(color)
                        .clipShape(Circle())
                    
                    Spacer()
                    
                    Text("\(count)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.selectedGameMode == .none ? .primary : .white)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            .padding(10)
            .background(themeManager.selectedGameMode == .none ? Color(uiColor: .secondarySystemGroupedBackground) : Color(white: 0.15))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ✅ Task Row Component
struct TaskRowView: View {
    @Bindable var task: StudyTask
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: { task.isCompleted.toggle() }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : (themeManager.selectedGameMode == .none ? .primary : .white))
                
                if let dueDate = task.dueDate {
                    Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(isOverdue ? .red : .secondary)
                }
                
                if let subject = task.subject {
                    Text(subject.title)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(subject.color.opacity(0.2))
                        .foregroundColor(subject.color)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            if task.isFlagged {
                Image(systemName: "flag.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var isOverdue: Bool {
        guard let date = task.dueDate, !task.isCompleted else { return false }
        return date < Date()
    }
}
