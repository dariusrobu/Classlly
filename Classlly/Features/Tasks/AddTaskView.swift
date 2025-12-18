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
    @State private var isFlagged = false
    
    init(preSelectedSubject: Subject? = nil) {
        _selectedSubject = State(initialValue: preSelectedSubject)
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
                        ForEach(subjects) { subject in
                            Text(subject.title).tag(subject as Subject?)
                        }
                    }
                    
                    Toggle("Flag", isOn: $isFlagged)
                        .tint(.orange)
                }
                
                Section {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    Toggle("Date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, in: Date()...)
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let t = StudyTask(
                            title: title,
                            isCompleted: false,
                            dueDate: hasDueDate ? dueDate : nil,
                            priority: priority,
                            subject: selectedSubject,
                            isFlagged: isFlagged,
                            notes: notes
                        )
                        modelContext.insert(t)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
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
    @State private var isFlagged = false
    
    init(preSelectedSubject: Subject? = nil) {
        _selectedSubject = State(initialValue: preSelectedSubject)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Details
                        RainbowContainer {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("New Task").font(.headline).foregroundColor(.white)
                                
                                TextField("Title...", text: $title)
                                    .padding()
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                                
                                TextField("Notes...", text: $notes, axis: .vertical)
                                    .padding()
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                                    .lineLimit(3...6)
                                
                                Menu {
                                    Button("No Subject") { selectedSubject = nil }
                                    ForEach(subjects) { subject in
                                        Button(subject.title) { selectedSubject = subject }
                                    }
                                } label: {
                                    HStack {
                                        Text("Subject").foregroundColor(.gray)
                                        Spacer()
                                        Text(selectedSubject?.title ?? "Select...").foregroundColor(RainbowColors.blue)
                                    }
                                    .padding()
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        
                        // 2. Options
                        RainbowContainer {
                            VStack(spacing: 16) {
                                Picker("Priority", selection: $priority) {
                                    ForEach(TaskPriority.allCases, id: \.self) { p in
                                        Text(p.rawValue).tag(p)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .colorScheme(.dark)
                                
                                Toggle("Flag", isOn: $isFlagged)
                                    .tint(RainbowColors.orange)
                                    .foregroundColor(.white)
                                
                                Toggle("Due Date", isOn: $hasDueDate)
                                    .tint(RainbowColors.blue)
                                    .foregroundColor(.white)
                                
                                if hasDueDate {
                                    DatePicker("", selection: $dueDate)
                                        .colorScheme(.dark)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Create")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.foregroundColor(.gray) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let t = StudyTask(
                            title: title,
                            isCompleted: false,
                            dueDate: hasDueDate ? dueDate : nil,
                            priority: priority,
                            subject: selectedSubject,
                            isFlagged: isFlagged,
                            notes: notes
                        )
                        modelContext.insert(t)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                    .fontWeight(.bold)
                    .foregroundColor(RainbowColors.green)
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
    @State private var isFlagged = false
    
    init(preSelectedSubject: Subject? = nil) {
        _selectedSubject = State(initialValue: preSelectedSubject)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NEW QUEST")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundColor(.green)
                            
                            TextField("Enter Objective...", text: $title)
                                .padding()
                                .background(Color(white: 0.1))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.5), lineWidth: 1))
                                .foregroundColor(.white)
                            
                            TextField("Intel (Notes)...", text: $notes, axis: .vertical)
                                .padding()
                                .background(Color(white: 0.1))
                                .cornerRadius(12)
                                .foregroundColor(.gray)
                                .lineLimit(3...6)
                        }
                        
                        // Selectors
                        HStack(spacing: 12) {
                            Menu {
                                Button("None") { selectedSubject = nil }
                                ForEach(subjects) { subject in
                                    Button(subject.title) { selectedSubject = subject }
                                }
                            } label: {
                                VStack(alignment: .leading) {
                                    Text("SKILL TREE")
                                        .font(.caption).fontWeight(.black).foregroundColor(.cyan)
                                    Text(selectedSubject?.title ?? "None")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(white: 0.1))
                                .cornerRadius(12)
                            }
                            
                            Button(action: { isFlagged.toggle() }) {
                                VStack {
                                    Image(systemName: isFlagged ? "flag.fill" : "flag")
                                        .font(.title2)
                                        .foregroundColor(isFlagged ? .yellow : .gray)
                                    Text("FLAG")
                                        .font(.caption).fontWeight(.black).foregroundColor(.gray)
                                }
                                .padding()
                                .frame(width: 80, height: 80)
                                .background(Color(white: 0.1))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(isFlagged ? Color.yellow : Color.clear, lineWidth: 2))
                            }
                        }
                        
                        // Priority
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DIFFICULTY")
                                .font(.caption).fontWeight(.black).foregroundColor(.purple)
                            
                            HStack {
                                ForEach(TaskPriority.allCases, id: \.self) { p in
                                    Button(action: { priority = p }) {
                                        Text(p.rawValue.uppercased())
                                            .font(.system(size: 10, weight: .bold))
                                            .padding(.vertical, 10)
                                            .frame(maxWidth: .infinity)
                                            .background(priority == p ? p.color : Color(white: 0.1))
                                            .foregroundColor(priority == p ? .white : .gray)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        
                        // Date
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("TIME LIMIT", isOn: $hasDueDate)
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .tint(.pink)
                                .foregroundColor(.white)
                            
                            if hasDueDate {
                                DatePicker("", selection: $dueDate)
                                    .datePickerStyle(.graphical)
                                    .colorScheme(.dark)
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
            .navigationTitle("Initialize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abort") { dismiss() }.foregroundColor(.red) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        let t = StudyTask(
                            title: title,
                            isCompleted: false,
                            dueDate: hasDueDate ? dueDate : nil,
                            priority: priority,
                            subject: selectedSubject,
                            isFlagged: isFlagged,
                            notes: notes
                        )
                        modelContext.insert(t)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                    .fontWeight(.black)
                    .foregroundColor(.green)
                }
            }
        }
    }
}
