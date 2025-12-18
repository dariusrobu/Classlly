import SwiftUI
import SwiftData

struct EditTaskView: View {
    @EnvironmentObject var themeManager: AppTheme
    @Bindable var task: StudyTask

    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .arcade:
                AnyView(ArcadeEditTaskView(task: task))
            case .rainbow:
                AnyView(RainbowEditTaskView(task: task))
            case .none:
                AnyView(StandardEditTaskView(task: task))
            }
        }
    }
}

// MARK: - 🌈 RAINBOW EDIT TASK
struct RainbowEditTaskView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var task: StudyTask
    @Query(sort: \Subject.title) var subjects: [Subject]

    @State private var title: String
    @State private var notes: String
    @State private var selectedSubject: Subject?
    @State private var priority: TaskPriority
    @State private var dueDate: Date
    @State private var hasDueDate: Bool
    @State private var reminderTime: TaskReminderTime
    @State private var isFlagged: Bool
    @State private var showingDeleteAlert = false
    
    init(task: StudyTask) {
        self.task = task
        _title = State(initialValue: task.title)
        _notes = State(initialValue: task.notes)
        _selectedSubject = State(initialValue: task.subject)
        _priority = State(initialValue: task.priority)
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _hasDueDate = State(initialValue: task.dueDate != nil)
        _reminderTime = State(initialValue: task.reminderTime)
        _isFlagged = State(initialValue: task.isFlagged)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Task Info
                        RainbowContainer {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Task Details").font(.headline).foregroundColor(.white)
                                
                                TextField("Enter task title", text: $title)
                                    .padding().background(Color.black.opacity(0.3)).cornerRadius(10).foregroundColor(.white)
                                
                                TextField("Notes", text: $notes, axis: .vertical)
                                    .padding().background(Color.black.opacity(0.3)).cornerRadius(10).foregroundColor(.white).lineLimit(3...6)
                                
                                Menu {
                                    Button("No Subject") { selectedSubject = nil }
                                    ForEach(subjects) { subject in Button(subject.title) { selectedSubject = subject } }
                                } label: {
                                    HStack { Text("Subject").foregroundColor(.gray); Spacer(); Text(selectedSubject?.title ?? "None").foregroundColor(RainbowColors.blue) }
                                    .padding().background(Color.black.opacity(0.3)).cornerRadius(10)
                                }
                                
                                Toggle(isOn: $isFlagged) { HStack { Image(systemName: "flag.fill").foregroundColor(RainbowColors.orange); Text("Flag Task").foregroundColor(.white) } }.tint(RainbowColors.orange)
                            }
                        }
                        
                        // 2. Deadlines & Priority
                        RainbowContainer {
                            VStack(alignment: .leading, spacing: 16) {
                                Picker("Priority", selection: $priority) { ForEach(TaskPriority.allCases, id: \.self) { p in Text(p.rawValue).tag(p) } }.pickerStyle(.segmented).colorScheme(.dark)
                                
                                Toggle(isOn: $hasDueDate) { Text("Set Due Date").font(.headline).foregroundColor(.white) }.tint(RainbowColors.blue)
                                if hasDueDate {
                                    DatePicker("Select Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute]).colorScheme(.dark)
                                    Picker("Reminder", selection: $reminderTime) { ForEach(TaskReminderTime.allCases, id: \.self) { time in Text(time.rawValue).tag(time) } }.pickerStyle(.menu).accentColor(RainbowColors.blue)
                                }
                            }
                        }
                        
                        // 3. Delete
                        Button(action: { showingDeleteAlert = true }) {
                            Text("Delete Task").font(.headline).foregroundColor(.red).frame(maxWidth: .infinity).padding().background(RainbowColors.darkCard).cornerRadius(12)
                        }
                    }.padding()
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() }.foregroundColor(.gray) }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        task.title = title; task.notes = notes; task.subject = selectedSubject; task.priority = priority
                        task.dueDate = hasDueDate ? dueDate : nil; task.reminderTime = hasDueDate ? reminderTime : .none; task.isFlagged = isFlagged
                        dismiss()
                    }.disabled(title.isEmpty).fontWeight(.bold).foregroundColor(RainbowColors.blue)
                }
            }
            .alert("Delete Task", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) { modelContext.delete(task); dismiss() }; Button("Cancel", role: .cancel) { }
            } message: { Text("Are you sure? This cannot be undone.") }
        }
    }
}

// MARK: - 👔 STANDARD EDIT TASK
struct StandardEditTaskView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var task: StudyTask
    @Query(sort: \Subject.title) var subjects: [Subject]

    @State private var title: String
    @State private var notes: String
    @State private var selectedSubject: Subject?
    @State private var priority: TaskPriority
    @State private var dueDate: Date
    @State private var hasDueDate: Bool
    @State private var reminderTime: TaskReminderTime
    @State private var isFlagged: Bool
    @State private var showingDeleteAlert = false
    
    init(task: StudyTask) {
        self.task = task
        _title = State(initialValue: task.title)
        _notes = State(initialValue: task.notes)
        _selectedSubject = State(initialValue: task.subject)
        _priority = State(initialValue: task.priority)
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _hasDueDate = State(initialValue: task.dueDate != nil)
        _reminderTime = State(initialValue: task.reminderTime)
        _isFlagged = State(initialValue: task.isFlagged)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Apple-style: Title & Notes grouped
                Section {
                    TextField("Title", text: $title)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .foregroundStyle(.secondary)
                        .lineLimit(3...6)
                }
                
                Section {
                    Picker("Subject", selection: $selectedSubject) {
                        Text("No Subject").tag(nil as Subject?)
                        ForEach(subjects) { subject in Text(subject.title).tag(subject as Subject?) }
                    }
                    Toggle(isOn: $isFlagged) { HStack { Image(systemName: "flag.fill").foregroundColor(.themeWarning); Text("Flag task") } }
                }
                
                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $priority) { ForEach(TaskPriority.allCases, id: \.self) { p in Text(p.rawValue).tag(p) } }.pickerStyle(.segmented)
                }
                
                Section(header: Text("Due Date")) {
                    Toggle("Add Due Date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, in: Date()..., displayedComponents: [.date, .hourAndMinute]).datePickerStyle(.compact)
                        Picker("Reminder", selection: $reminderTime) { ForEach(TaskReminderTime.allCases, id: \.self) { time in Text(time.rawValue).tag(time) } }
                    }
                }
                
                Section { Button("Delete Task", role: .destructive) { showingDeleteAlert = true } }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        task.title = title; task.notes = notes; task.subject = selectedSubject; task.priority = priority
                        task.dueDate = hasDueDate ? dueDate : nil; task.reminderTime = hasDueDate ? reminderTime : .none; task.isFlagged = isFlagged
                        dismiss()
                    }.disabled(title.isEmpty)
                }
            }
            .alert("Delete Task", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) { modelContext.delete(task); dismiss() }; Button("Cancel", role: .cancel) { }
            } message: { Text("Are you sure?") }
        }
    }
}

// MARK: - 🕹️ ARCADE EDIT TASK
struct ArcadeEditTaskView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var task: StudyTask
    @Query(sort: \Subject.title) var subjects: [Subject]

    @State private var title: String
    @State private var notes: String
    @State private var selectedSubject: Subject?
    @State private var priority: TaskPriority
    @State private var dueDate: Date
    @State private var hasDueDate: Bool
    @State private var isFlagged: Bool
    
    init(task: StudyTask) {
        self.task = task
        _title = State(initialValue: task.title)
        _notes = State(initialValue: task.notes)
        _selectedSubject = State(initialValue: task.subject)
        _priority = State(initialValue: task.priority)
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _hasDueDate = State(initialValue: task.dueDate != nil)
        _isFlagged = State(initialValue: task.isFlagged)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("UPDATE MISSION PARAMETERS").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundColor(.cyan)
                            TextField("Objective...", text: $title).padding().background(Color(white: 0.1)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cyan.opacity(0.5), lineWidth: 1)).foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MISSION INTEL").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundColor(.green)
                            TextField("Notes...", text: $notes, axis: .vertical).padding().background(Color(white: 0.1)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.5), lineWidth: 1)).foregroundColor(.white).lineLimit(3...6)
                        }
                        
                        // Controls...
                        HStack(spacing: 16) {
                            Menu {
                                Button("None") { selectedSubject = nil }
                                ForEach(subjects) { subject in Button(subject.title) { selectedSubject = subject } }
                            } label: {
                                VStack(alignment: .leading) { Text("SKILL TREE").font(.caption).fontWeight(.bold).foregroundColor(.purple); Text(selectedSubject?.title ?? "Select...").foregroundColor(.white) }.padding().frame(maxWidth: .infinity, alignment: .leading).background(Color(white: 0.1)).cornerRadius(12)
                            }
                            Button(action: { isFlagged.toggle() }) {
                                VStack { Text("FLAG").font(.caption).fontWeight(.bold).foregroundColor(.yellow); Image(systemName: isFlagged ? "flag.fill" : "flag").foregroundColor(isFlagged ? .yellow : .gray) }.padding().frame(maxWidth: .infinity).background(Color(white: 0.1)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(isFlagged ? Color.yellow : Color.clear, lineWidth: 1))
                            }
                        }
                        // Priority & Date...
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DIFFICULTY").font(.caption).fontWeight(.bold).foregroundColor(.gray)
                            HStack(spacing: 12) { ForEach(TaskPriority.allCases, id: \.self) { p in Button(action: { priority = p }) { Text(p.rawValue.uppercased()).font(.system(.caption, design: .rounded)).fontWeight(.bold).frame(maxWidth: .infinity).padding(.vertical, 12).background(priority == p ? p.color : Color(white: 0.1)).foregroundColor(priority == p ? .white : .gray).cornerRadius(8) } } }
                        }
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("TIME LIMIT", isOn: $hasDueDate).tint(.pink).font(.headline).foregroundColor(.white)
                            if hasDueDate { DatePicker("", selection: $dueDate).datePickerStyle(.graphical).colorScheme(.dark) }
                        }.padding().background(Color(white: 0.1)).cornerRadius(16)
                        
                        Button(action: { modelContext.delete(task); dismiss() }) { Text("ABORT MISSION (DELETE)").font(.system(.caption, design: .rounded)).fontWeight(.black).foregroundColor(.red).padding().frame(maxWidth: .infinity).background(Color.red.opacity(0.1)).cornerRadius(12) }
                    }.padding()
                }
            }
            .navigationTitle("Mission Control").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() }.foregroundColor(.gray) }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save Changes") {
                        task.title = title; task.notes = notes; task.subject = selectedSubject; task.priority = priority
                        task.dueDate = hasDueDate ? dueDate : nil; task.isFlagged = isFlagged; dismiss()
                    }.fontWeight(.bold).foregroundColor(.cyan)
                }
            }
        }
    }
}
