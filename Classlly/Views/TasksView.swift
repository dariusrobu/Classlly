//
//  TasksView.swift
//  Classlly
//
//  Created by Robu Darius on 14.11.2025.
//


// File: Classlly/Views/TasksView.swift
// Note: This view displays a list of StudyTask models.
// It uses a @Query to fetch all tasks and then filters
// them based on the selected `TaskFilter`.

import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingAddTask = false
    @State private var editingTask: StudyTask?
    @State private var taskFilter: TaskFilter = .today
    @Environment(\.colorScheme) var colorScheme
    
    enum TaskFilter: String, CaseIterable {
        case today = "Today"
        case flagged = "Flagged"
        case all = "All"
        case completed = "Completed"
        
        var iconName: String {
            switch self {
            case .today:
                return "sun.max.fill"
            case .flagged:
                return "flag.fill"
            case .all:
                return "tray.fill"
            case .completed:
                return "checkmark.circle.fill"
            }
        }
        
        var selectionColor: Color {
            switch self {
            case .today:
                return .themePrimary // Blue
            case .flagged:
                // --- THIS IS THE FIX ---
                return .themeError // Changed to Red
            case .all:
                return .themePrimary // Blue
            case .completed:
                return .themeSuccess // Green
            }
        }
    }
    
    @Query private var tasks: [StudyTask]
    
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
            return tasks.filter { $0.isFlagged && !$0.isCompleted }
                        .sorted { $0.dueDate ?? Date.distantFuture < $1.dueDate ?? Date.distantFuture }

        case .all:
            return tasks.filter { !$0.isCompleted }.sorted { $0.dueDate ?? Date.distantFuture < $1.dueDate ?? Date.distantFuture }
            
        case .completed:
            return tasks.filter { $0.isCompleted }.sorted { $0.dueDate ?? Date.distantFuture < $1.dueDate ?? Date.distantFuture }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(TaskFilter.allCases, id: \.self) { filter in
                            FilterButton(
                                title: filter.rawValue,
                                iconName: filter.iconName,
                                color: filter.selectionColor,
                                isSelected: taskFilter == filter,
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
                
                VStack(spacing: 0) {
                    if filteredTasks.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 40))
                                .foregroundColor(.themeTextSecondary)
                            Text(emptyStateTitle)
                                .font(.headline)
                                .foregroundColor(.themeTextPrimary)
                            Text(emptyStateMessage)
                                .font(.subheadline)
                                .foregroundColor(.themeTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        Spacer()
                        
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(filteredTasks) { task in
                                    TaskCard(task: task)
                                        .onTapGesture { editingTask = task }
                                        .contextMenu {
                                            Button { editingTask = task } label: { Label("Edit", systemImage: "pencil") }
                                            if !task.isCompleted {
                                                Button { withAnimation { task.isCompleted = true } } label: { Label("Mark Complete", systemImage: "checkmark") }
                                            }
                                            Button(role: .destructive) { withAnimation { modelContext.delete(task) } } label: { Label("Delete", systemImage: "trash") }
                                        }
                                    
                                    if task != filteredTasks.last {
                                        Divider()
                                            .padding(.leading, 56)
                                    }
                                }
                            }
                            .padding(.vertical, 20)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.themeSurface)
                .cornerRadius(16)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.themePrimary)
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
    
    private var emptyStateTitle: String {
        switch taskFilter {
        case .today: return "No Tasks Today"
        case .flagged: return "No Flagged Tasks"
        case .all: return "No Active Tasks"
        case .completed: return "No Completed Tasks"
        }
    }
    
    private var emptyStateMessage: String {
        switch taskFilter {
        case .today: return "You have no tasks due today."
        case .flagged: return "Flag a task to see it here."
        case .all: return "All tasks are completed! 🎉"
        case .completed: return "Completed tasks will appear here."
        }
    }
}

// --- FilterButton (Unchanged) ---
struct FilterButton: View {
    let title: String
    let iconName: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.caption)
                Text(title)
            }
            .font(.subheadline)
            .fontWeight(isSelected ? .bold : .medium)
            .foregroundColor(isSelected ? color : .themeTextSecondary)
            .lineLimit(1)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(isSelected ? 0.1 : 0.0))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? color : Color.adaptiveBorder, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}


// --- TaskCard (Unchanged) ---
struct TaskCard: View {
    @Bindable var task: StudyTask
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    task.isCompleted.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .stroke(task.priority.color, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if task.isCompleted {
                        Circle()
                            .fill(task.priority.color)
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
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
                        Image(systemName: "flag.fill")
                            .font(.caption)
                            .foregroundColor(.themeWarning) // Flag icon remains orange
                    }
                }
                
                HStack(spacing: 16) {
                    if let subjectTitle = task.subject?.title {
                        HStack(spacing: 6) {
                            Image(systemName: "book.closed.fill")
                                .font(.caption2)
                            Text(subjectTitle)
                        }
                        .font(.caption)
                        .foregroundColor(.themeTextSecondary)
                    }
                    
                    if let dueDate = task.dueDate {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(formatDueDate(dueDate))
                        }
                        .font(.caption)
                        .foregroundColor(dueDate < Date() && !task.isCompleted ? .themeError : .themeTextSecondary)
                    }
                }
            }
            
            Spacer()
            
            if !task.isCompleted {
                VStack(spacing: 4) {
                    Image(systemName: task.priority.iconName)
                        .font(.system(size: 10, weight: .bold))
                    Text(task.priority.rawValue)
                        .font(.system(size: 8, weight: .medium))
                }
                .foregroundColor(task.priority.color)
                .padding(8)
                .background(task.priority.color.opacity(colorScheme == .dark ? 0.2 : 0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}