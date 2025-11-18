import SwiftUI
import SwiftData

struct EditTaskView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var task: StudyTask
    
    @Query(sort: \Subject.title) var subjects: [Subject]

    @State private var title: String
    @State private var selectedSubject: Subject?
    @State private var priority: TaskPriority
    @State private var dueDate: Date
    @State private var hasDueDate: Bool
    @State private var reminderTime: TaskReminderTime
    @State private var isFlagged: Bool
    @State private var notes: String // NEW
    @State private var showingDeleteAlert = false
    
    init(task: StudyTask) {
        self.task = task
        _title = State(initialValue: task.title)
        _selectedSubject = State(initialValue: task.subject)
        _priority = State(initialValue: task.priority)
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _hasDueDate = State(initialValue: task.dueDate != nil)
        _reminderTime = State(initialValue: task.reminderTime)
        _isFlagged = State(initialValue: task.isFlagged)
        _notes = State(initialValue: task.notes) // NEW
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task title", text: $title)
                    
                    Picker("Subject", selection: $selectedSubject) {
                        Text("No Subject").tag(nil as Subject?)
                        ForEach(subjects) { subject in
                            Text(subject.title).tag(subject as Subject?)
                        }
                    }
                    
                    Toggle(isOn: $isFlagged) {
                        HStack {
                            Image(systemName: "flag.fill")
                                .foregroundColor(.themeWarning)
                            Text("Flag task")
                        }
                    }
                }
                
                // NEW: Notes Section
                Section(header: Text("Description")) {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Priority")) {
                    PriorityPicker(selectedPriority: $priority)
                }
                
                Section(header: Text("Due Date")) {
                    Toggle("Add Due Date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            
                        Picker("Reminder", selection: $reminderTime) {
                            ForEach(TaskReminderTime.allCases, id: \.self) { time in
                                Text(time.rawValue).tag(time)
                            }
                        }
                    }
                }
                
                Section {
                    Button("Delete Task", role: .destructive) {
                        showingDeleteAlert = true
                    }
                    .foregroundColor(.themeError)
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Delete Task", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    modelContext.delete(task)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete \"\(task.title)\"?")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.themeError)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        task.title = title
                        task.subject = selectedSubject
                        task.priority = priority
                        task.dueDate = hasDueDate ? dueDate : nil
                        task.reminderTime = hasDueDate ? reminderTime : .none
                        task.isFlagged = isFlagged
                        task.notes = notes // Save notes
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                    .fontWeight(.semibold)
                    .foregroundColor(.themePrimary)
                }
            }
        }
    }
}

// --- HELPER STRUCT ---

fileprivate struct PriorityPicker: View {
    @Binding var selectedPriority: TaskPriority
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(TaskPriority.allCases, id: \.self) { priority in
                Button(action: {
                    selectedPriority = priority
                }) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(priority.color.opacity(0.1))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: priority.iconName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(priority.color)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(priority.rawValue)
                                .font(.body)
                                .foregroundColor(.themeTextPrimary)
                            
                            Text(priorityDescription(for: priority))
                                .font(.caption)
                                .foregroundColor(.themeTextSecondary)
                        }
                        
                        Spacer()
                        
                        if selectedPriority == priority {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.themePrimary)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                if priority != TaskPriority.allCases.last {
                    Divider()
                        .padding(.leading, 52)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func priorityDescription(for priority: TaskPriority) -> String {
        switch priority {
        case .low:
            return "Not urgent, can be done later"
        case .medium:
            return "Should be completed soon"
        case .high:
            return "Urgent, needs immediate attention"
        }
    }
}
