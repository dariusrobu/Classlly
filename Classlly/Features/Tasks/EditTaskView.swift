import SwiftUI
import SwiftData

struct EditTaskView: View {
    @EnvironmentObject var themeManager: AppTheme
    @Bindable var task: StudyTask

    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .arcade:
                ArcadeEditTaskView(task: task)
            case .rainbow:
                RainbowEditTaskView(task: task)
            case .none:
                StandardEditTaskView(task: task)
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
    @State private var isExam: Bool
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
        _isExam = State(initialValue: task.isExam)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        RainbowContainer {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Task Details").font(.headline).foregroundColor(.white)
                                TextField("Title", text: $title).padding().background(Color.black.opacity(0.3)).cornerRadius(10).foregroundColor(.white)
                                
                                Menu {
                                    Button("No Subject") { selectedSubject = nil }
                                    ForEach(subjects) { sub in Button(sub.title) { selectedSubject = sub } }
                                } label: {
                                    HStack { Text("Subject").foregroundColor(.gray); Spacer(); Text(selectedSubject?.title ?? "None").foregroundColor(RainbowColors.blue) }
                                    .padding().background(Color.black.opacity(0.3)).cornerRadius(10)
                                }
                                
                                Toggle(isOn: $isExam) { HStack { Image(systemName: "graduationcap.fill").foregroundColor(.red); Text("Is Exam").foregroundColor(.white) } }.tint(.red)
                                Toggle(isOn: $isFlagged) { HStack { Image(systemName: "flag.fill").foregroundColor(RainbowColors.orange); Text("Flagged").foregroundColor(.white) } }.tint(RainbowColors.orange)
                            }
                        }
                        
                        RainbowContainer {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Notes").font(.headline).foregroundColor(.white)
                                TextEditor(text: $notes).frame(minHeight: 100).scrollContentBackground(.hidden).background(Color.black.opacity(0.3)).cornerRadius(10).foregroundColor(.white)
                            }
                        }
                        
                        RainbowContainer {
                            VStack(alignment: .leading, spacing: 16) {
                                Picker("Priority", selection: $priority) { ForEach(TaskPriority.allCases, id: \.self) { p in Text(p.rawValue).tag(p) } }.pickerStyle(.segmented).colorScheme(.dark)
                                Toggle(isOn: $hasDueDate) { Text("Set Due Date").font(.headline).foregroundColor(.white) }.tint(RainbowColors.blue)
                                if hasDueDate {
                                    DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute]).colorScheme(.dark)
                                    Picker("Reminder", selection: $reminderTime) { ForEach(TaskReminderTime.allCases, id: \.self) { t in Text(t.rawValue).tag(t) } }.pickerStyle(.menu).accentColor(RainbowColors.blue)
                                }
                            }
                        }
                        
                        Button(action: { showingDeleteAlert = true }) {
                            Text("Delete Task").font(.headline).foregroundColor(.red).frame(maxWidth: .infinity).padding().background(RainbowColors.darkCard).cornerRadius(12)
                        }
                    }.padding()
                }
            }
            .navigationTitle("Edit Task").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() }.foregroundColor(.gray) }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        task.title = title; task.notes = notes; task.subject = selectedSubject; task.priority = priority
                        task.dueDate = hasDueDate ? dueDate : nil; task.reminderTime = hasDueDate ? reminderTime : .none
                        task.isFlagged = isFlagged; task.isExam = isExam
                        dismiss()
                    }.fontWeight(.bold).foregroundColor(RainbowColors.blue)
                }
            }
            .alert("Delete Task", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) { modelContext.delete(task); dismiss() }
                Button("Cancel", role: .cancel) { }
            }
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
    @State private var isExam: Bool
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
        _isExam = State(initialValue: task.isExam)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $title)
                    Picker("Subject", selection: $selectedSubject) {
                        Text("No Subject").tag(nil as Subject?)
                        ForEach(subjects) { s in Text(s.title).tag(s as Subject?) }
                    }
                    Toggle(isOn: $isExam) { HStack { Image(systemName: "graduationcap.fill").foregroundColor(.red); Text("Is Exam") } }
                    Toggle(isOn: $isFlagged) { HStack { Image(systemName: "flag.fill").foregroundColor(.themeWarning); Text("Flagged") } }
                }
                Section(header: Text("Notes")) { TextEditor(text: $notes).frame(minHeight: 80) }
                Section(header: Text("Settings")) {
                    Picker("Priority", selection: $priority) { ForEach(TaskPriority.allCases, id: \.self) { p in Text(p.rawValue).tag(p) } }.pickerStyle(.segmented)
                    Toggle("Due Date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                        Picker("Reminder", selection: $reminderTime) { ForEach(TaskReminderTime.allCases, id: \.self) { t in Text(t.rawValue).tag(t) } }
                    }
                }
                Section { Button("Delete Task", role: .destructive) { showingDeleteAlert = true } }
            }
            .navigationTitle("Edit Task").toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        task.title = title; task.notes = notes; task.subject = selectedSubject; task.priority = priority
                        task.dueDate = hasDueDate ? dueDate : nil; task.reminderTime = hasDueDate ? reminderTime : .none
                        task.isFlagged = isFlagged; task.isExam = isExam
                        dismiss()
                    }
                }
            }
            .alert("Delete", isPresented: $showingDeleteAlert) { Button("Delete", role: .destructive) { modelContext.delete(task); dismiss() } }
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
    @State private var isExam: Bool
    
    init(task: StudyTask) {
        self.task = task
        _title = State(initialValue: task.title)
        _notes = State(initialValue: task.notes)
        _selectedSubject = State(initialValue: task.subject)
        _priority = State(initialValue: task.priority)
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _hasDueDate = State(initialValue: task.dueDate != nil)
        _isFlagged = State(initialValue: task.isFlagged)
        _isExam = State(initialValue: task.isExam)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("UPDATE OBJECTIVE").font(.caption).fontWeight(.black).foregroundColor(.cyan)
                            TextField("...", text: $title).padding().background(Color(white: 0.1)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cyan, lineWidth: 1)).foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("INTEL").font(.caption).fontWeight(.black).foregroundColor(.green)
                            TextEditor(text: $notes).scrollContentBackground(.hidden).frame(minHeight: 100).padding(8).background(Color(white: 0.1)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green, lineWidth: 1)).foregroundColor(.white)
                        }
                        
                        VStack(spacing: 12) {
                            Menu {
                                Button("None") { selectedSubject = nil }
                                ForEach(subjects) { s in Button(s.title) { selectedSubject = s } }
                            } label: {
                                HStack { Text("SKILL: \(selectedSubject?.title ?? "NONE")").fontWeight(.bold); Spacer(); Image(systemName: "chevron.down") }
                                .padding().background(Color(white: 0.1)).cornerRadius(12).foregroundColor(.purple)
                            }
                            
                            Button(action: { isExam.toggle() }) {
                                HStack { Image(systemName: isExam ? "flame.fill" : "flame"); Text(isExam ? "BOSS BATTLE (EXAM)" : "NORMAL QUEST") }
                                .fontWeight(.black).frame(maxWidth: .infinity).padding().background(isExam ? Color.red.opacity(0.3) : Color(white: 0.1)).foregroundColor(isExam ? .red : .gray).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(isExam ? Color.red : Color.clear, lineWidth: 1))
                            }
                            
                            Button(action: { isFlagged.toggle() }) {
                                HStack { Image(systemName: isFlagged ? "flag.fill" : "flag"); Text(isFlagged ? "FLAGGED" : "NORMAL") }
                                .fontWeight(.bold).frame(maxWidth: .infinity).padding().background(isFlagged ? Color.yellow.opacity(0.2) : Color(white: 0.1)).foregroundColor(isFlagged ? .yellow : .gray).cornerRadius(12)
                            }
                        }
                        
                        Toggle("TIME LIMIT", isOn: $hasDueDate).tint(.pink).font(.headline).foregroundColor(.white).padding().background(Color(white: 0.1)).cornerRadius(12)
                        if hasDueDate { DatePicker("", selection: $dueDate).datePickerStyle(.graphical).colorScheme(.dark).background(Color(white: 0.05)).cornerRadius(12) }
                        
                        Button(action: { modelContext.delete(task); dismiss() }) {
                            Text("ABORT MISSION (DELETE)").fontWeight(.black).foregroundColor(.red).padding().frame(maxWidth: .infinity).background(Color.red.opacity(0.1)).cornerRadius(12)
                        }
                    }.padding()
                }
            }
            .navigationTitle("Mission Control").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() }.foregroundColor(.gray) }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        task.title = title; task.notes = notes; task.subject = selectedSubject; task.priority = priority
                        task.dueDate = hasDueDate ? dueDate : nil; task.isFlagged = isFlagged; task.isExam = isExam
                        dismiss()
                    }.fontWeight(.bold).foregroundColor(.cyan)
                }
            }
        }
    }
}
