import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: AppTheme
    
    // Optional: Pass a task to edit
    var taskToEdit: StudyTask?
    
    // Optional: Pre-select subject (for Subject Detail view)
    var preSelectedSubject: Subject?
    
    @Query(sort: \Subject.title) var subjects: [Subject]
    
    @State private var title = ""
    @State private var dueDate = Date()
    @State private var hasDueDate = true
    @State private var priority: TaskPriority = .medium
    @State private var selectedSubject: Subject?
    @State private var notes = ""
    
    // Initialize for Edit Mode
    init(taskToEdit: StudyTask? = nil, preSelectedSubject: Subject? = nil) {
        self.taskToEdit = taskToEdit
        self.preSelectedSubject = preSelectedSubject
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                    
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
                }
                
                Section("Due Date") {
                    Toggle("Has Due Date", isOn: $hasDueDate)
                        .tint(themeManager.selectedTheme.primaryColor)
                    
                    if hasDueDate {
                        DatePicker("Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
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
            .onAppear {
                setupInitialValues()
            }
        }
    }
    
    private func setupInitialValues() {
        // If editing an existing task
        if let task = taskToEdit {
            title = task.title
            priority = task.priority
            selectedSubject = task.subject
            // ✅ Fix: notes is non-optional String
            notes = task.notes
            
            if let due = task.dueDate {
                dueDate = due
                hasDueDate = true
            } else {
                hasDueDate = false
            }
        }
        // If creating new with pre-selected subject
        else if let subject = preSelectedSubject {
            selectedSubject = subject
        }
    }
    
    private func save() {
        if let task = taskToEdit {
            // Update Existing
            task.title = title
            task.priority = priority
            task.subject = selectedSubject
            // ✅ Fix: Assign String directly (no nil)
            task.notes = notes
            task.dueDate = hasDueDate ? dueDate : nil
        } else {
            // Create New
            // ✅ Fix: Correct Argument Order & Non-optional notes
            let newTask = StudyTask(
                title: title,
                isCompleted: false, // Must come before dueDate
                dueDate: hasDueDate ? dueDate : nil,
                priority: priority,
                notes: notes // Must be String
            )
            newTask.subject = selectedSubject
            modelContext.insert(newTask)
        }
        
        dismiss()
    }
}
