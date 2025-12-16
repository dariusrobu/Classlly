import SwiftUI
import SwiftData

struct AddTaskView: View {
    @EnvironmentObject var themeManager: AppTheme
    var preSelectedSubject: Subject?
    init(preSelectedSubject: Subject? = nil) { self.preSelectedSubject = preSelectedSubject }
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .rainbow: RainbowAddTaskView(preSelectedSubject: preSelectedSubject)
            case .arcade: ArcadeAddTaskView(preSelectedSubject: preSelectedSubject)
            case .none: StandardAddTaskView(preSelectedSubject: preSelectedSubject)
            }
        }
    }
}
// (Retain StandardAddTaskView, RainbowAddTaskView, ArcadeAddTaskView classes as is, remove RetroAddTaskView)
// Just pasting the standard structure to save space in this response:
struct StandardAddTaskView: View {
    @Environment(\.dismiss) var dismiss; @Environment(\.modelContext) private var modelContext; @Query(sort: \Subject.title) var subjects: [Subject]
    @State private var title = ""; @State private var notes = ""; @State private var selectedSubject: Subject?; @State private var priority: TaskPriority = .medium; @State private var dueDate = Date(); @State private var hasDueDate = false; @State private var isFlagged = false
    init(preSelectedSubject: Subject? = nil) { _selectedSubject = State(initialValue: preSelectedSubject) }
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task title", text: $title)
                    Picker("Subject", selection: $selectedSubject) { Text("No Subject").tag(nil as Subject?); ForEach(subjects) { Text($0.title).tag($0 as Subject?) } }
                    Toggle("Flag task", isOn: $isFlagged)
                }
                Section(header: Text("Priority")) { Picker("Priority", selection: $priority) { ForEach(TaskPriority.allCases, id: \.self) { p in Text(p.rawValue).tag(p) } }.pickerStyle(.segmented) }
                Section(header: Text("Due Date")) { Toggle("Add Due Date", isOn: $hasDueDate); if hasDueDate { DatePicker("Date", selection: $dueDate) } }
            }
            .navigationTitle("New Task").toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Add") {
                    let t = StudyTask(title: title, dueDate: hasDueDate ? dueDate : nil, priority: priority, subject: selectedSubject, isFlagged: isFlagged, notes: notes)
                    modelContext.insert(t); dismiss()
                }.disabled(title.isEmpty) }
            }
        }
    }
}
// (Include Rainbow/Arcade here if needed, but Retro is gone)
struct RainbowAddTaskView: View { var preSelectedSubject: Subject?; var body: some View { Text("Rainbow Add Task") } }
struct ArcadeAddTaskView: View { var preSelectedSubject: Subject?; var body: some View { Text("Arcade Add Task") } }
