import SwiftUI
import SwiftData

// MARK: - MAIN SWITCHER
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
            case .retro:
                RetroAddTaskView(preSelectedSubject: preSelectedSubject)
            case .none:
                StandardAddTaskView(preSelectedSubject: preSelectedSubject)
            }
        }
    }
}

// MARK: - 🌈 RAINBOW ADD TASK (Custom Dark Form)
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
                                
                                TextField("Enter task title", text: $title)
                                    .padding()
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                                
                                // Subject Picker Replacement
                                Menu {
                                    Button("No Subject") { selectedSubject = nil }
                                    ForEach(subjects) { subject in
                                        Button(subject.title) { selectedSubject = subject }
                                    }
                                } label: {
                                    HStack {
                                        Text("Subject")
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text(selectedSubject?.title ?? "None")
                                            .foregroundColor(RainbowColors.blue)
                                    }
                                    .padding()
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(10)
                                }
                                
                                Toggle(isOn: $isFlagged) {
                                    HStack {
                                        Image(systemName: "flag.fill")
                                            .foregroundColor(RainbowColors.orange)
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
                        
                        // 3. Priority
                        RainbowContainer {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Priority").font(.headline).foregroundColor(.white)
                                Picker("Priority", selection: $priority) {
                                    ForEach(TaskPriority.allCases, id: \.self) { p in
                                        Text(p.rawValue).tag(p)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .colorScheme(.dark) // Keeps picker looking good
                            }
                        }
                        
                        // 4. Deadlines
                        RainbowContainer {
                            VStack(alignment: .leading, spacing: 16) {
                                Toggle(isOn: $hasDueDate) {
                                    Text("Set Due Date").font(.headline).foregroundColor(.white)
                                }
                                .tint(RainbowColors.blue)
                                
                                if hasDueDate {
                                    DatePicker("Select Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                                        .colorScheme(.dark)
                                    
                                    Picker("Reminder", selection: $reminderTime) {
                                        ForEach(TaskReminderTime.allCases, id: \.self) { time in
                                            Text(time.rawValue).tag(time)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .accentColor(RainbowColors.blue)
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.red)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let newTask = StudyTask(
                            title: title,
                            dueDate: hasDueDate ? dueDate : nil,
                            priority: priority,
                            subject: selectedSubject,
                            reminderTime: hasDueDate ? reminderTime : .none,
                            isFlagged: isFlagged,
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

// ... (Rest of Standard/Arcade/Retro views unchanged)
// [Preserving existing code structure below]

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
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
                
                Section(header: Text("Priority")) {
                    StandardPriorityPicker(selectedPriority: $priority)
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
                        let newTask = StudyTask(
                            title: title,
                            dueDate: hasDueDate ? dueDate : nil,
                            priority: priority,
                            subject: selectedSubject,
                            reminderTime: hasDueDate ? reminderTime : .none,
                            isFlagged: isFlagged,
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
    
    init(preSelectedSubject: Subject? = nil) {
        _selectedSubject = State(initialValue: preSelectedSubject)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MISSION TITLE")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.cyan)
                            
                            TextField("Enter objective...", text: $title)
                                .padding()
                                .background(Color(white: 0.1))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cyan.opacity(0.5), lineWidth: 1))
                                .foregroundColor(.white)
                        }
                        
                        // Notes Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("INTEL / NOTES")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                            
                            TextEditor(text: $notes)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color(white: 0.1))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.5), lineWidth: 1))
                                .foregroundColor(.white)
                        }
                        
                        // Subject & Flag
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("SKILL TREE")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(.purple)
                                
                                Menu {
                                    Button("None") { selectedSubject = nil }
                                    ForEach(subjects) { subject in
                                        Button(subject.title) { selectedSubject = subject }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedSubject?.title ?? "Select...")
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "chevron.down").foregroundColor(.purple)
                                    }
                                    .padding()
                                    .background(Color(white: 0.1))
                                    .cornerRadius(12)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("PRIORITY")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(.yellow)
                                
                                Button(action: { isFlagged.toggle() }) {
                                    HStack {
                                        Image(systemName: isFlagged ? "flag.fill" : "flag")
                                        Text(isFlagged ? "Flagged" : "Normal")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isFlagged ? Color.yellow.opacity(0.2) : Color(white: 0.1))
                                    .foregroundColor(isFlagged ? .yellow : .gray)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(isFlagged ? Color.yellow : Color.clear, lineWidth: 1))
                                }
                            }
                        }
                        
                        // Priority Selector
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DIFFICULTY LEVEL")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 12) {
                                ForEach(TaskPriority.allCases, id: \.self) { p in
                                    Button(action: { priority = p }) {
                                        Text(p.rawValue.uppercased())
                                            .font(.system(.caption, design: .rounded))
                                            .fontWeight(.bold)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(priority == p ? p.color : Color(white: 0.1))
                                            .foregroundColor(priority == p ? .white : .gray)
                                            .cornerRadius(8)
                                            .shadow(color: priority == p ? p.color.opacity(0.5) : .clear, radius: 8)
                                    }
                                }
                            }
                        }
                        
                        // Date Picker
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $hasDueDate) {
                                Text("TIME LIMIT")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .tint(.pink)
                            
                            if hasDueDate {
                                DatePicker("", selection: $dueDate)
                                    .datePickerStyle(.graphical)
                                    .preferredColorScheme(.dark)
                                    .background(Color(white: 0.05))
                                    .cornerRadius(12)
                            }
                        }
                        .padding()
                        .background(Color(white: 0.1))
                        .cornerRadius(16)
                    }
                    .padding()
                }
            }
            .navigationTitle("New Mission")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abort") { dismiss() }.foregroundColor(.red)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Initialize") {
                        let newTask = StudyTask(
                            title: title,
                            dueDate: hasDueDate ? dueDate : nil,
                            priority: priority,
                            subject: selectedSubject,
                            isFlagged: isFlagged,
                            notes: notes
                        )
                        modelContext.insert(newTask)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.black)
                    .foregroundColor(.cyan)
                }
            }
        }
    }
}

struct RetroAddTaskView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.title) var subjects: [Subject]

    @State private var title = ""
    @State private var notes = ""
    @State private var selectedSubject: Subject?
    @State private var priority: TaskPriority = .medium
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var isFlagged = false
    
    init(preSelectedSubject: Subject? = nil) {
        _selectedSubject = State(initialValue: preSelectedSubject)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.05).ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("> INITIALIZE_NEW_TASK")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(.green)
                        
                        // Title
                        VStack(alignment: .leading, spacing: 4) {
                            Text("INPUT_TITLE:")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.gray)
                            HStack {
                                Text(">")
                                    .foregroundColor(.green)
                                TextField("...", text: $title)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.green)
                            }
                            .padding(8)
                            .border(Color.green.opacity(0.5), width: 1)
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 4) {
                            Text("INPUT_DATA_STREAM (NOTES):")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.gray)
                            
                            TextEditor(text: $notes)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 100)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.green)
                                .padding(8)
                                .background(Color.black)
                                .border(Color.green.opacity(0.5), width: 1)
                        }
                        
                        // Subject
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SELECT_SUBJECT:")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.gray)
                            
                            Menu {
                                Button("NULL") { selectedSubject = nil }
                                ForEach(subjects) { sub in
                                    Button(sub.title) { selectedSubject = sub }
                                }
                            } label: {
                                Text("[ \(selectedSubject?.title.uppercased() ?? "NULL") ]")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.green)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(8)
                                    .border(Color.green.opacity(0.5), width: 1)
                            }
                        }
                        
                        // Priority
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SET_PRIORITY:")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.gray)
                            
                            HStack {
                                ForEach(TaskPriority.allCases, id: \.self) { p in
                                    Button(action: { priority = p }) {
                                        Text(priority == p ? "[\(p.rawValue.uppercased())]" : " \(p.rawValue.uppercased()) ")
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(priority == p ? .green : .gray)
                                            .padding(4)
                                    }
                                }
                            }
                        }
                        
                        // Flag
                        Toggle(isOn: $isFlagged) {
                            Text("FLAG_PROCESS:")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.green)
                        }
                        .tint(.green)
                        
                        // Date
                        Toggle(isOn: $hasDueDate) {
                            Text("ENABLE_DEADLINE:")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.green)
                        }
                        .tint(.green)
                        
                        if hasDueDate {
                            DatePicker("", selection: $dueDate)
                                .datePickerStyle(.compact)
                                .colorScheme(.dark)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("< EXIT")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.red)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        let newTask = StudyTask(
                            title: title,
                            dueDate: hasDueDate ? dueDate : nil,
                            priority: priority,
                            subject: selectedSubject,
                            isFlagged: isFlagged,
                            notes: notes
                        )
                        modelContext.insert(newTask)
                        dismiss()
                    }) {
                        Text("[ EXECUTE ]")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

fileprivate struct StandardPriorityPicker: View {
    @Binding var selectedPriority: TaskPriority
    var body: some View {
        Picker("Priority", selection: $selectedPriority) {
            ForEach(TaskPriority.allCases, id: \.self) { priority in
                Text(priority.rawValue).tag(priority)
            }
        }
        .pickerStyle(.segmented)
    }
}
