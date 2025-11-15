// File: Classlly/Task/AddTaskView.swift
// Note: This file is corrected to create an empty StudyTask()
// and set its properties. The 'fileprivate' keyword is
// removed from PriorityPicker to fix the redeclaration error.

import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Subject.title) var subjects: [Subject]

    @State private var title = ""
    @State private var selectedSubject: Subject?
    @State private var priority: TaskPriority = .medium
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var reminderTime: TaskReminderTime = .hourBefore1
    @State private var isFlagged: Bool = false

    init(preSelectedSubject: Subject? = nil) {
        _selectedSubject = State(initialValue: preSelectedSubject)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task title", text: $title)
                        .textInputAutocapitalization(.sentences)
                    
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
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.themeError)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        // --- THIS IS THE FIX ---
                        // 1. Create an empty task
                        let newTask = StudyTask()
                        
                        // 2. Set all properties
                        newTask.title = title
                        newTask.dueDate = hasDueDate ? dueDate : nil
                        newTask.priority = priority
                        newTask.reminderTime = hasDueDate ? reminderTime : .none
                        newTask.isFlagged = isFlagged
                        newTask.subject = selectedSubject
                        
                        // 3. Insert into the context
                        modelContext.insert(newTask)
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

// --- HELPER STRUCT (with updated theme colors) ---
// --- FIX: Removed 'fileprivate' to fix redeclaration error ---
struct PriorityPicker: View {
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
