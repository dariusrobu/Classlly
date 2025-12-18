import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: AppTheme
    
    @Query(sort: \StudyTask.dueDate, order: .forward) private var allTasks: [StudyTask]
    @State private var selectedFilter: TaskFilter = .all
    @State private var showingAddTask = false
    
    enum TaskFilter {
        case today, all, flagged, completed
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background adaptation
                if themeManager.selectedGameMode == .rainbow {
                    LinearGradient(
                        colors: [themeManager.selectedTheme.primaryColor.opacity(0.15), .black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ).ignoresSafeArea()
                } else if themeManager.selectedGameMode == .arcade {
                    Color.black.ignoresSafeArea()
                } else {
                    Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                }
                
                VStack(spacing: 0) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        FilterCard(title: "Today", icon: "calendar", count: tasksForFilter(.today).count, color: .blue, isSelected: selectedFilter == .today) { selectedFilter = .today }
                        FilterCard(title: "All", icon: "tray.fill", count: allTasks.count, color: .gray, isSelected: selectedFilter == .all) { selectedFilter = .all }
                        FilterCard(title: "Flagged", icon: "flag.fill", count: tasksForFilter(.flagged).count, color: .orange, isSelected: selectedFilter == .flagged) { selectedFilter = .flagged }
                        FilterCard(title: "Completed", icon: "checkmark", count: tasksForFilter(.completed).count, color: .green, isSelected: selectedFilter == .completed) { selectedFilter = .completed }
                    }
                    .padding([.horizontal, .top])
                    
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
                                    TaskRowView(task: task)
                                        .listRowBackground(themeManager.selectedGameMode == .none ? Color(uiColor: .secondarySystemGroupedBackground) : Color.white.opacity(0.05))
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
                        Image(systemName: "plus.circle.fill")
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

struct FilterCard: View {
    let title: String; let icon: String; let count: Int; let color: Color; let isSelected: Bool; let action: () -> Void
    @EnvironmentObject var themeManager: AppTheme
    
    private var displayColor: Color {
        if themeManager.selectedGameMode == .rainbow {
            let accent = themeManager.selectedTheme.primaryColor
            return Color(
                red: (color.components.red * 0.6) + (accent.components.red * 0.4),
                green: (color.components.green * 0.6) + (accent.components.green * 0.4),
                blue: (color.components.blue * 0.6) + (accent.components.blue * 0.4)
            )
        }
        return color
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(displayColor)
                        .clipShape(Circle())
                    Spacer()
                    Text("\(count)").font(.title3).fontWeight(.bold)
                        .foregroundColor(themeManager.selectedGameMode == .none ? .primary : .white)
                }
                Text(title).font(.caption).fontWeight(.semibold)
                    .foregroundColor(themeManager.selectedGameMode == .none ? .secondary : .white.opacity(0.7))
            }
            .padding(10)
            .background(themeManager.selectedGameMode == .none ? Color(uiColor: .secondarySystemGroupedBackground) : Color.white.opacity(0.1))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? displayColor : Color.clear, lineWidth: 2))
        }.buttonStyle(.plain)
    }
}

struct TaskRowView: View {
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
