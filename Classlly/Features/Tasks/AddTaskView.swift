import SwiftUI
import SwiftData

struct AddTaskView: View {
    @EnvironmentObject var themeManager: AppTheme
    var preSelectedSubject: Subject?

    init(preSelectedSubject: Subject? = nil) {
        self.preSelectedSubject = preSelectedSubject
    }

    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .rainbow:
                RainbowAddTaskView(preSelectedSubject: preSelectedSubject)
            case .arcade:
                ArcadeAddTaskView(preSelectedSubject: preSelectedSubject)
            case .none:
                StandardAddTaskView(preSelectedSubject: preSelectedSubject)
            }
        }
    }
}

// MARK: - 🌈 RAINBOW ADD TASK
struct RainbowAddTaskView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.title) var subjects: [Subject]

    @State private var title = ""
    @State private var notes = ""
    @State private var selectedSubject: Subject?
    @State private var priority: TaskPriority = .medium
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var reminderTime: TaskReminderTime = .hourBefore1
    @State private var isFlagged: Bool = false
    @State private var isExam: Bool = false // New State
    
    init(preSelectedSubject: Subject? = nil) {
        _selectedSubject = State(initialValue: preSelectedSubject)
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
                                
                                TextField("Enter title", text: $title)
                                    .padding()
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                                
                                Menu {
                                    Button("No Subject") { selectedSubject = nil }
                                    ForEach(subjects) { subject in
                                        Button(subject.title) { selectedSubject = subject }
                                    }
                                } label: {
                                    HStack {
                                        Text("Subject").foregroundColor(.gray)
                                        Spacer()
                                        Text(selectedSubject?.title ?? "None").foregroundColor(RainbowColors.blue)
                                    }
                                    .padding()
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(10)
                                }
                                
                                // Exam Toggle
                                Toggle(isOn: $isExam) {
                                    HStack {
                                        Image(systemName: "graduationcap.fill")
                                            .foregroundColor(.red)
                                        Text("Mark as Exam").foregroundColor(.white)
                                    }
                                }
                                .tint(.red)
                                
                                Toggle(isOn: $isFlagged) {
                                    HStack {
                                        Image(systemName: "flag.fill").foregroundColor(RainbowColors.orange)
                                        Text("Flag Task").foregroundColor(.white)
                                    }
                                }
                                .tint(RainbowColors.orange)
                            }
                        }
                        
                        // 2. Notes
                        RainbowContainer {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Notes").font(.headline).foregroundColor(.white)
                                TextEditor(text: $notes)
                                    .frame(minHeight: 100)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // 3. Priority & Dates
                        RainbowContainer {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Settings").font(.headline).foregroundColor(.white)
                                
                                Picker("Priority", selection: $priority) {
                                    ForEach(TaskPriority.allCases, id: \.self) { p in Text(p.rawValue).tag(p) }
                                }
                                .pickerStyle(.segmented).colorScheme(.dark)
                                
                                Toggle(isOn: $hasDueDate) {
                                    Text("Set Due Date").font(.headline).foregroundColor(.white)
                                }
                                .tint(RainbowColors.blue)
                                
                                if hasDueDate {
                                    DatePicker("Select Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                                        .colorScheme(.dark)
                                    
                                    Picker("Reminder", selection: $reminderTime) {
                                        ForEach(TaskReminderTime.allCases, id: \.self) { time in Text(time.rawValue).tag(time) }
                                    }
                                    .pickerStyle(.menu).accentColor(RainbowColors.blue)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() }.foregroundColor(.red) }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let newTask = StudyTask(
                            title: title,
                            dueDate: hasDueDate ? dueDate : nil,
                            priority: priority,
                            subject: selectedSubject,
                            reminderTime: hasDueDate ? reminderTime : .none,
                            isFlagged: isFlagged,
                            isExam: isExam, // Save exam status
                            notes: notes
                        )
                        modelContext.insert(newTask)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                    .fontWeight(.bold)
                    .foregroundColor(RainbowColors.blue)
                }
            }
        }
    }
}

// MARK: - 👔 STANDARD ADD TASK
struct StandardAddTaskView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.title) var subjects: [Subject]

    @State private var title = ""
    @State private var notes = ""
    @State private var selectedSubject: Subject?
    @State private var priority: TaskPriority = .medium
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var reminderTime: TaskReminderTime = .hourBefore1
    @State private var isFlagged: Bool = false
    @State private var isExam: Bool = false

    init(preSelectedSubject: Subject? = nil) {
        _selectedSubject = State(initialValue: preSelectedSubject)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task title", text: $title).textInputAutocapitalization(.sentences)
                    Picker("Subject", selection: $selectedSubject) {
                        Text("No Subject").tag(nil as Subject?)
                        ForEach(subjects) { subject in Text(subject.title).tag(subject as Subject?) }
                    }
                    Toggle(isOn: $isExam) {
                        HStack {
                            Image(systemName: "graduationcap.fill").foregroundColor(.red)
                            Text("Mark as Exam").fontWeight(.semibold)
                        }
                    }
                    Toggle(isOn: $isFlagged) {
                        HStack {
                            Image(systemName: "flag.fill").foregroundColor(.themeWarning)
                            Text("Flag task")
                        }
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes).frame(minHeight: 80)
                }
                
                Section(header: Text("Settings")) {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { p in Text(p.rawValue).tag(p) }
                    }.pickerStyle(.segmented)
                    
                    Toggle("Add Due Date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        Picker("Reminder", selection: $reminderTime) {
                            ForEach(TaskReminderTime.allCases, id: \.self) { time in Text(time.rawValue).tag(time) }
                        }
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() }.foregroundColor(.themeError) }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let newTask = StudyTask(
                            title: title,
                            dueDate: hasDueDate ? dueDate : nil,
                            priority: priority,
                            subject: selectedSubject,
                            reminderTime: hasDueDate ? reminderTime : .none,
                            isFlagged: isFlagged,
                            isExam: isExam,
                            notes: notes
                        )
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

// MARK: - 🕹️ ARCADE ADD TASK
struct ArcadeAddTaskView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.title) var subjects: [Subject]

    @State private var title = ""
    @State private var notes = ""
    @State private var selectedSubject: Subject?
    @State private var priority: TaskPriority = .medium
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var isFlagged: Bool = false
    @State private var isExam: Bool = false
    
    init(preSelectedSubject: Subject? = nil) {
        _selectedSubject = State(initialValue: preSelectedSubject)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MISSION TITLE").font(.caption).fontWeight(.black).foregroundColor(.cyan)
                            TextField("Enter objective...", text: $title)
                                .padding().background(Color(white: 0.1)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cyan, lineWidth: 1)).foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("INTEL").font(.caption).fontWeight(.black).foregroundColor(.green)
                            TextEditor(text: $notes).scrollContentBackground(.hidden).frame(minHeight: 100).padding(8).background(Color(white: 0.1)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green, lineWidth: 1)).foregroundColor(.white)
                        }
                        
                        // Modifiers
                        VStack(spacing: 12) {
                            // Subject
                            Menu {
                                Button("None") { selectedSubject = nil }
                                ForEach(subjects) { subject in Button(subject.title) { selectedSubject = subject } }
                            } label: {
                                HStack { Text(selectedSubject?.title ?? "SELECT SKILL TREE").fontWeight(.bold); Spacer(); Image(systemName: "chevron.down") }
                                .padding().background(Color(white: 0.1)).cornerRadius(12).foregroundColor(.purple)
                            }
                            
                            // Exam Toggle
                            Button(action: { isExam.toggle() }) {
                                HStack {
                                    Image(systemName: isExam ? "flame.fill" : "flame")
                                    Text(isExam ? "BOSS BATTLE (EXAM)" : "NORMAL QUEST")
                                }.fontWeight(.black).frame(maxWidth: .infinity).padding().background(isExam ? Color.red.opacity(0.3) : Color(white: 0.1)).foregroundColor(isExam ? .red : .gray).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(isExam ? Color.red : Color.clear, lineWidth: 1))
                            }
                            
                            // Flag Toggle
                            Button(action: { isFlagged.toggle() }) {
                                HStack { Image(systemName: isFlagged ? "flag.fill" : "flag"); Text(isFlagged ? "FLAGGED" : "NORMAL") }.fontWeight(.bold).frame(maxWidth: .infinity).padding().background(isFlagged ? Color.yellow.opacity(0.2) : Color(white: 0.1)).foregroundColor(isFlagged ? .yellow : .gray).cornerRadius(12)
                            }
                        }
                        
                        // Time
                        Toggle("TIME LIMIT", isOn: $hasDueDate).tint(.pink).font(.headline).foregroundColor(.white).padding().background(Color(white: 0.1)).cornerRadius(12)
                        if hasDueDate { DatePicker("", selection: $dueDate).datePickerStyle(.graphical).colorScheme(.dark).background(Color(white: 0.05)).cornerRadius(12) }
                    }.padding()
                }
            }
            .navigationTitle("New Mission").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Abort") { dismiss() }.foregroundColor(.red) }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Initialize") {
                        let newTask = StudyTask(
                            title: title, dueDate: hasDueDate ? dueDate : nil, priority: priority,
                            subject: selectedSubject, isFlagged: isFlagged, isExam: isExam, notes: notes
                        )
                        modelContext.insert(newTask)
                        dismiss()
                    }.disabled(title.isEmpty).fontWeight(.black).foregroundColor(.cyan)
                }
            }
        }
    }
}
