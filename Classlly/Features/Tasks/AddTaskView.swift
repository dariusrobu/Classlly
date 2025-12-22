import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: AppTheme
    
    var taskToEdit: StudyTask?
    
    // Configuration
    var preSelectedSubject: Subject?
    var initialTitle: String?
    var initialPriority: TaskPriority?
    var initialType: TaskType?
    
    @Query(sort: \Subject.title) var subjects: [Subject]
    
    @State private var title = ""
    @State private var dueDate = Date()
    @State private var hasDueDate = true
    @State private var priority: TaskPriority = .medium
    @State private var selectedType: TaskType = .task
    @State private var selectedSubject: Subject?
    @State private var notes = ""
    @State private var isFlagged = false
    @State private var selectedReminder: TaskReminderTime = .none // ✅ NEW
    
    init(
        taskToEdit: StudyTask? = nil,
        preSelectedSubject: Subject? = nil,
        initialTitle: String? = nil,
        initialPriority: TaskPriority? = nil,
        initialType: TaskType? = nil
    ) {
        self.taskToEdit = taskToEdit
        self.preSelectedSubject = preSelectedSubject
        self.initialTitle = initialTitle
        self.initialPriority = initialPriority
        self.initialType = initialType
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(TaskType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    
                    Picker("Subject", selection: $selectedSubject) {
                        Text("None").tag(nil as Subject?)
                        ForEach(subjects) { subject in
                            Text(subject.title).tag(subject as Subject?)
                        }
                    }
                    
                    Picker("Priority", selection: $priority) {
                        Text("Low").tag(TaskPriority.low)
                        Text("Medium").tag(TaskPriority.medium)
                        Text("High").tag(TaskPriority.high)
                    }
                    .pickerStyle(.segmented)
                    
                    Toggle("Flag Important", isOn: $isFlagged)
                        .tint(themeManager.selectedTheme.primaryColor)
                }
                
                Section("Due Date") {
                    Toggle("Has Due Date", isOn: $hasDueDate)
                        .tint(themeManager.selectedTheme.primaryColor)
                    
                    if hasDueDate {
                        DatePicker("Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                        
                        // ✅ NEW: Reminder Picker
                        Picker("Reminder", selection: $selectedReminder) {
                            ForEach(TaskReminderTime.allCases, id: \.self) { reminder in
                                Text(reminder.rawValue).tag(reminder)
                            }
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle(taskToEdit == nil ? "New Task" : "Edit Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.isEmpty)
                        .fontWeight(.bold)
                }
            }
            .onAppear { setupInitialValues() }
        }
    }
    
    private func setupInitialValues() {
        if let task = taskToEdit {
            title = task.title
            priority = task.priority
            selectedType = task.type
            selectedSubject = task.subject
            notes = task.notes
            isFlagged = task.isFlagged
            selectedReminder = task.reminderTime // ✅ Load Reminder
            
            if let due = task.dueDate {
                dueDate = due
                hasDueDate = true
            } else {
                hasDueDate = false
            }
        } else {
            // Pre-fill logic
            if let subject = preSelectedSubject { selectedSubject = subject }
            if let initTitle = initialTitle { title = initTitle }
            if let initPriority = initialPriority { priority = initPriority }
            if let initType = initialType { selectedType = initType }
        }
    }
    
    private func save() {
        if let task = taskToEdit {
            task.title = title
            task.priority = priority
            task.type = selectedType
            task.subject = selectedSubject
            task.notes = notes
            task.dueDate = hasDueDate ? dueDate : nil
            task.isFlagged = isFlagged
            task.reminderTime = hasDueDate ? selectedReminder : .none // ✅ Save Reminder
        } else {
            let newTask = StudyTask(
                title: title,
                isCompleted: false,
                dueDate: hasDueDate ? dueDate : nil,
                priority: priority,
                type: selectedType,
                reminderTime: hasDueDate ? selectedReminder : .none, // ✅ Save Reminder
                subject: selectedSubject,
                isFlagged: isFlagged,
                notes: notes
            )
            modelContext.insert(newTask)
        }
        dismiss()
    }
}
