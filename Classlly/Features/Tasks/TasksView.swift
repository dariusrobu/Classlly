import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isGamified") private var isGamified = false
    
    @State private var showingAddTask = false
    @State private var editingTask: StudyTask?
    @State private var taskFilter: TaskFilter = .today
    
    @Query private var tasks: [StudyTask]
    
    enum TaskFilter: String, CaseIterable {
        case today = "Today"
        case flagged = "Flagged"
        case all = "All"
        case completed = "Done"
        
        var iconName: String {
            switch self {
            case .today: return "sun.max.fill"
            case .flagged: return "flag.fill"
            case .all: return "tray.fill"
            case .completed: return "checkmark.circle.fill"
            }
        }
        
        var selectionColor: Color {
            switch self {
            case .today: return .themePrimary
            case .flagged: return .themeError
            case .all: return .themePrimary
            case .completed: return .themeSuccess
            }
        }
    }
    
    public init() {}
    
    var filteredTasks: [StudyTask] {
        let now = Date()
        let calendar = Calendar.current
        switch taskFilter {
        case .today:
            return tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return !task.isCompleted && calendar.isDate(dueDate, inSameDayAs: now)
            }.sorted { $0.dueDate ?? Date.distantFuture < $1.dueDate ?? Date.distantFuture }
        case .flagged:
            return tasks.filter { $0.isFlagged && !$0.isCompleted }.sorted { $0.dueDate ?? Date.distantFuture < $1.dueDate ?? Date.distantFuture }
        case .all:
            return tasks.filter { !$0.isCompleted }.sorted { $0.dueDate ?? Date.distantFuture < $1.dueDate ?? Date.distantFuture }
        case .completed:
            return tasks.filter { $0.isCompleted }.sorted { $0.dueDate ?? Date.distantFuture < $1.dueDate ?? Date.distantFuture }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Filter Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(TaskFilter.allCases, id: \.self) { filter in
                            FilterButton(
                                title: filter.rawValue,
                                iconName: filter.iconName,
                                color: filter.selectionColor,
                                isSelected: taskFilter == filter,
                                isGamified: isGamified,
                                action: {
                                    withAnimation { taskFilter = filter }
                                }
                            )
                        }
                    }
                    .padding()
                }
                
                // MARK: - Task List
                if filteredTasks.isEmpty {
                    EmptyStateView(filter: taskFilter, isGamified: isGamified)
                        .padding(.top, 40)
                    Spacer()
                } else {
                    List {
                        ForEach(filteredTasks) { task in
                            Group {
                                if isGamified {
                                    GamifiedTaskRow(task: task)
                                } else {
                                    ModernTaskRow(task: task)
                                }
                            }
                            // Swipe Actions work for both
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    modelContext.delete(task)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    editingTask = task
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    withAnimation { task.isCompleted.toggle() }
                                } label: {
                                    Label("Done", systemImage: "checkmark")
                                }
                                .tint(.green)
                            }
                            // Hide separators for gamified to keep "Card" look
                            .listRowSeparator(isGamified ? .hidden : .visible)
                            .listRowInsets(isGamified ? EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16) : nil)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(isGamified ? .themePrimary : .primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
            .sheet(item: $editingTask) { task in
                EditTaskView(task: task)
            }
        }
    }
}

// MARK: - 1. Filter Button
struct FilterButton: View {
    let title: String
    let iconName: String
    let color: Color
    let isSelected: Bool
    let isGamified: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.caption)
                Text(title)
            }
            .font(.subheadline)
            .fontWeight(isSelected ? .semibold : .medium)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                Group {
                    if isSelected {
                        if isGamified {
                            color.opacity(0.15)
                        } else {
                            Color.primary // Solid black/white for minimalist
                        }
                    } else {
                        Color.clear
                    }
                }
            )
            .foregroundColor(
                isSelected ? (isGamified ? color : .white) : // Text color
                (isGamified ? .secondary : .primary)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isGamified && isSelected ? color : Color.adaptiveBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 2. Modern Minimalist Row (Gamified OFF)
struct ModernTaskRow: View {
    let task: StudyTask
    
    var body: some View {
        HStack(spacing: 12) {
            // Priority Indicator Strip
            if !task.isCompleted {
                Capsule()
                    .fill(task.priority.color)
                    .frame(width: 4, height: 36)
            }
            
            // Checkbox Button
            Button {
                withAnimation { task.isCompleted.toggle() }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                
                HStack(spacing: 4) {
                    if let subject = task.subject {
                        Text(subject.title)
                    }
                    
                    if let due = task.dueDate {
                        if task.subject != nil { Text("•") }
                        Text(due.formatted(date: .abbreviated, time: .shortened))
                            .foregroundColor(due < Date() && !task.isCompleted ? .themeError : .secondary)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if task.isFlagged && !task.isCompleted {
                Image(systemName: "flag.fill")
                    .font(.caption)
                    .foregroundColor(.themeWarning)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - 3. Gamified Row (Gamified ON)
struct GamifiedTaskRow: View {
    let task: StudyTask
    
    var xpReward: Int {
        switch task.priority {
        case .high: return 50
        case .medium: return 30
        case .low: return 10
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Gamified Checkbox
            Button {
                withAnimation { task.isCompleted.toggle() }
            } label: {
                ZStack {
                    Circle()
                        .fill(task.priority.color.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: task.isCompleted ? "checkmark" : "circle")
                        .foregroundColor(task.priority.color)
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .themeTextPrimary)
                
                if !task.isCompleted {
                    Text("Reward: \(xpReward) XP")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(task.priority.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(task.priority.color.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            if task.isFlagged {
                Image(systemName: "flag.fill")
                    .foregroundColor(.themeWarning)
            }
        }
        .padding(12)
        .background(Color.themeSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(task.priority.color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: task.priority.color.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 4. Empty State
struct EmptyStateView: View {
    let filter: TasksView.TaskFilter
    let isGamified: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: filter == .completed ? "checkmark.circle" : "tray")
                .font(.system(size: 48))
                .foregroundColor(isGamified ? .themeSecondary : .secondary)
                .opacity(0.5)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    var title: String {
        switch filter {
        case .today: return "No tasks today"
        case .flagged: return "No flagged tasks"
        case .all: return "No tasks"
        case .completed: return "No completed tasks"
        }
    }
    
    var message: String {
        if isGamified {
            return "Check back later for new quests!"
        } else {
            return "Tap + to add a new task."
        }
    }
}
