import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var themeManager: AppTheme
    @AppStorage("isGamifiedMode") private var isGamifiedMode = false
    
    @State private var showingAddTask = false
    @State private var editingTask: StudyTask?
    @State private var taskFilter: TaskFilter = .today
    
    @Query private var tasks: [StudyTask]
    
    public init() {}
    
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
    }
    
    var filteredTasks: [StudyTask] {
        let now = Date()
        let calendar = Calendar.current
        
        switch taskFilter {
        case .today:
            return tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return !task.isCompleted && calendar.isDate(dueDate, inSameDayAs: now)
            }.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
            
        case .flagged:
            return tasks.filter { $0.isFlagged && !$0.isCompleted }
                        .sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }

        case .all:
            return tasks.filter { !$0.isCompleted }
                        .sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
            
        case .completed:
            return tasks.filter { $0.isCompleted }
                        .sorted { ($0.dueDate ?? Date.distantFuture) > ($1.dueDate ?? Date.distantFuture) }
        }
    }
    
    var body: some View {
        // NavigationStack/View is handled by ContentView, so we use a simple container
        VStack(spacing: 0) {
            // Filter Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TaskFilter.allCases, id: \.self) { filter in
                        FilterButton(
                            title: filter.rawValue,
                            iconName: filter.iconName,
                            isSelected: taskFilter == filter,
                            themeColor: themeManager.selectedTheme.accentColor,
                            isGamified: isGamifiedMode,
                            action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    taskFilter = filter
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            
            // Content
            if filteredTasks.isEmpty {
                TasksEmptyStateView(filter: taskFilter, isGamified: isGamifiedMode)
            } else {
                ScrollView {
                    LazyVStack(spacing: isGamifiedMode ? 12 : 0) {
                        ForEach(filteredTasks) { task in
                            if isGamifiedMode {
                                GamifiedTaskRow(task: task, themeColor: themeManager.selectedTheme.accentColor)
                                    .onTapGesture { editingTask = task }
                                    .contextMenu { taskContextMenu(for: task) }
                                    .padding(.horizontal)
                            } else {
                                TaskCard(task: task)
                                    .onTapGesture { editingTask = task }
                                    .contextMenu { taskContextMenu(for: task) }
                                
                                if task != filteredTasks.last {
                                    Divider().padding(.leading, 56)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .background(Color.themeBackground)
        .navigationTitle("Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddTask = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(isGamifiedMode ? themeManager.selectedTheme.accentColor : .themePrimary)
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
    
    @ViewBuilder
    private func taskContextMenu(for task: StudyTask) -> some View {
        Button { editingTask = task } label: { Label("Edit", systemImage: "pencil") }
        if !task.isCompleted {
            Button { withAnimation { task.isCompleted = true } } label: { Label("Mark Complete", systemImage: "checkmark") }
        }
        Button(role: .destructive) { withAnimation { modelContext.delete(task) } } label: { Label("Delete", systemImage: "trash") }
    }
}

// MARK: - 1. Filter Button
struct FilterButton: View {
    let title: String
    let iconName: String
    let isSelected: Bool
    let themeColor: Color
    let isGamified: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: iconName).font(.caption)
                Text(title)
            }
            .font(.subheadline)
            .fontWeight(isSelected ? .bold : .medium)
            .foregroundColor(textColor)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(backgroundView)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(borderColor, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var textColor: Color {
        if isSelected {
            return isGamified ? .white : themeColor
        }
        return .themeTextSecondary
    }
    
    private var borderColor: Color {
        if isSelected && !isGamified { return themeColor }
        return .clear
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if isSelected {
            if isGamified {
                LinearGradient(
                    gradient: Gradient(colors: [themeColor, themeColor.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                themeColor.opacity(0.1)
            }
        } else {
            Color.themeSurface
        }
    }
}

// MARK: - 2. Gamified Task Row
struct GamifiedTaskRow: View {
    @Bindable var task: StudyTask
    let themeColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: { withAnimation { task.isCompleted.toggle() }}) {
                ZStack {
                    Circle().fill(.white).frame(width: 28, height: 28)
                    if task.isCompleted {
                        Image(systemName: "checkmark").font(.caption.bold()).foregroundColor(themeColor)
                    } else {
                        Circle().stroke(themeColor.opacity(0.3), lineWidth: 2).frame(width: 28, height: 28)
                    }
                }
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .strikethrough(task.isCompleted)
                
                HStack(spacing: 8) {
                    if let subject = task.subject {
                        Label(subject.title, systemImage: "book.fill")
                    }
                    if let date = task.dueDate {
                        Label(formatDate(date), systemImage: "calendar")
                    }
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            if !task.isCompleted {
                Image(systemName: task.priority.iconName)
                    .foregroundColor(.white)
                    .padding(6)
                    .background(.white.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [themeColor, themeColor.opacity(0.7)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(24)
        .shadow(color: themeColor.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) { return "Today" }
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - 3. Standard Task Card
struct TaskCard: View {
    @Bindable var task: StudyTask
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: { withAnimation { task.isCompleted.toggle() } }) {
                ZStack {
                    Circle().stroke(task.priority.color, lineWidth: 2).frame(width: 24, height: 24)
                    if task.isCompleted {
                        Circle().fill(task.priority.color).frame(width: 24, height: 24)
                        Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(task.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(task.isCompleted ? .themeTextSecondary : .themeTextPrimary)
                        .strikethrough(task.isCompleted)
                    
                    if task.isFlagged && !task.isCompleted {
                        Image(systemName: "flag.fill").font(.caption).foregroundColor(.themeWarning)
                    }
                }
                
                HStack(spacing: 16) {
                    if let subjectTitle = task.subject?.title {
                        HStack(spacing: 6) { Image(systemName: "book.closed.fill").font(.caption2); Text(subjectTitle) }
                            .font(.caption).foregroundColor(.themeTextSecondary)
                    }
                    if let dueDate = task.dueDate {
                        HStack(spacing: 6) { Image(systemName: "calendar").font(.caption2); Text(formatDueDate(dueDate)) }
                            .font(.caption).foregroundColor(dueDate < Date() && !task.isCompleted ? .themeError : .themeTextSecondary)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Color.themeSurface)
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInTomorrow(date) { return "Tomorrow" }
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - 4. Empty State
struct TasksEmptyStateView: View {
    let filter: TasksView.TaskFilter
    let isGamified: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(isGamified ? .white.opacity(0.5) : .themeTextSecondary)
            
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(isGamified ? .white : .themeTextPrimary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(isGamified ? .white.opacity(0.7) : .themeTextSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }
    
    private var title: String {
        switch filter {
        case .today: return "No Tasks Today"
        case .flagged: return "No Flagged Tasks"
        case .all: return "No Active Tasks"
        case .completed: return "No Completed Tasks"
        }
    }
    
    private var message: String {
        switch filter {
        case .today: return "You're free for the day!"
        case .flagged: return "Flag important tasks to see them here."
        case .all: return "You've completed everything. Great job!"
        case .completed: return "Completed tasks will show up here."
        }
    }
}
