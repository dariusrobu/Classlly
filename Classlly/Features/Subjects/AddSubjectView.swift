import SwiftUI
import SwiftData

struct AddSubjectView: View {
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .arcade:
                ArcadeAddSubjectView()
            case .retro:
                RetroAddSubjectView()
            case .rainbow:
                StandardAddSubjectView()
                    .preferredColorScheme(.dark)
            case .none:
                StandardAddSubjectView()
            }
        }
    }
}

// MARK: - 👔 STANDARD ADD VIEW
struct StandardAddSubjectView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var courseTeacher = ""
    @State private var courseClassroom = ""
    @State private var courseDate = Date()
    @State private var courseStartTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var courseEndTime = Calendar.current.date(bySettingHour: 10, minute: 30, second: 0, of: Date()) ?? Date()
    @State private var selectedCourseDays: Set<Int> = [2, 4]
    @State private var courseFrequency: ClassFrequency = .weekly
    
    @State private var seminarTeacher = ""
    @State private var seminarClassroom = ""
    @State private var seminarDate = Date()
    @State private var seminarStartTime = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var seminarEndTime = Calendar.current.date(bySettingHour: 15, minute: 30, second: 0, of: Date()) ?? Date()
    @State private var selectedSeminarDays: Set<Int> = [5]
    @State private var seminarFrequency: ClassFrequency = .weekly
    
    private let daysOfWeek = [(1, "Sun"), (2, "Mon"), (3, "Tue"), (4, "Wed"), (5, "Thu"), (6, "Fri"), (7, "Sat")]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Subject Details")) {
                    TextField("Subject Title", text: $title).textInputAutocapitalization(.words)
                }
                
                Section(header: Text("Course Information")) {
                    TextField("Course Teacher", text: $courseTeacher).textInputAutocapitalization(.words)
                    TextField("Course Classroom", text: $courseClassroom)
                    Picker("Frequency", selection: $courseFrequency) {
                        ForEach(ClassFrequency.allCases, id: \.self) { f in Text(f.rawValue).tag(f) }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Course Days").font(.caption).foregroundColor(.secondary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                            ForEach(daysOfWeek, id: \.0) { day in
                                StandardDayChip(day: day.1, isSelected: selectedCourseDays.contains(day.0)) {
                                    if selectedCourseDays.contains(day.0) { selectedCourseDays.remove(day.0) } else { selectedCourseDays.insert(day.0) }
                                }
                            }
                        }
                    }
                    DatePicker("Start Time", selection: $courseStartTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $courseEndTime, displayedComponents: .hourAndMinute)
                }
                
                Section(header: Text("Seminar Information")) {
                    TextField("Seminar Teacher", text: $seminarTeacher).textInputAutocapitalization(.words)
                    TextField("Seminar Classroom", text: $seminarClassroom)
                    Picker("Frequency", selection: $seminarFrequency) {
                        ForEach(ClassFrequency.allCases, id: \.self) { f in Text(f.rawValue).tag(f) }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Seminar Days").font(.caption).foregroundColor(.secondary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                            ForEach(daysOfWeek, id: \.0) { day in
                                StandardDayChip(day: day.1, isSelected: selectedSeminarDays.contains(day.0)) {
                                    if selectedSeminarDays.contains(day.0) { selectedSeminarDays.remove(day.0) } else { selectedSeminarDays.insert(day.0) }
                                }
                            }
                        }
                    }
                    DatePicker("Start Time", selection: $seminarStartTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $seminarEndTime, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("Add Subject")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() }.foregroundColor(.themeError) }
                ToolbarItem(placement: .navigationBarTrailing) { Button("Save") { saveSubject() }.disabled(title.isEmpty).fontWeight(.semibold) }
            }
        }
    }
    
    private func saveSubject() {
        let newSubject = Subject(
            title: title,
            courseTeacher: courseTeacher, courseClassroom: courseClassroom, courseDate: courseDate,
            courseStartTime: courseStartTime, courseEndTime: courseEndTime, courseDays: Array(selectedCourseDays).sorted(), courseFrequency: courseFrequency,
            seminarTeacher: seminarTeacher, seminarClassroom: seminarClassroom, seminarDate: seminarDate,
            seminarStartTime: seminarStartTime, seminarEndTime: seminarEndTime, seminarDays: Array(selectedSeminarDays).sorted(), seminarFrequency: seminarFrequency
        )
        modelContext.insert(newSubject)
        dismiss()
    }
}

// MARK: - 🕹️ ARCADE ADD VIEW
struct ArcadeAddSubjectView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    // Course
    @State private var courseTeacher = ""
    @State private var courseClassroom = ""
    @State private var courseStartTime = Date()
    @State private var courseEndTime = Date().addingTimeInterval(3600)
    @State private var selectedCourseDays: Set<Int> = []
    // Seminar
    @State private var seminarTeacher = ""
    @State private var seminarClassroom = ""
    @State private var seminarStartTime = Date()
    @State private var seminarEndTime = Date().addingTimeInterval(3600)
    @State private var selectedSeminarDays: Set<Int> = []
    
    private let daysOfWeek = [(1, "S"), (2, "M"), (3, "T"), (4, "W"), (5, "T"), (6, "F"), (7, "S")]

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title
                        VStack(alignment: .leading) {
                            Text("SKILL TREE NAME").font(.caption).fontWeight(.black).foregroundColor(.cyan)
                            TextField("Enter Subject...", text: $title)
                                .padding()
                                .background(Color(white: 0.1))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cyan, lineWidth: 1))
                                .foregroundColor(.white)
                        }
                        
                        // Course Section
                        ArcadeSection(title: "MAIN QUEST (COURSE)", color: .purple) {
                            ArcadeInput(icon: "person.fill", placeholder: "Instructor", text: $courseTeacher)
                            ArcadeInput(icon: "mappin.and.ellipse", placeholder: "Location", text: $courseClassroom)
                            
                            // Days
                            HStack {
                                ForEach(daysOfWeek, id: \.0) { day in
                                    ArcadeDayChip(label: day.1, isSelected: selectedCourseDays.contains(day.0), color: .purple) {
                                        if selectedCourseDays.contains(day.0) { selectedCourseDays.remove(day.0) } else { selectedCourseDays.insert(day.0) }
                                    }
                                }
                            }
                            // Times
                            HStack {
                                DatePicker("", selection: $courseStartTime, displayedComponents: .hourAndMinute).labelsHidden().colorScheme(.dark)
                                Text("TO").font(.caption).fontWeight(.bold).foregroundColor(.gray)
                                DatePicker("", selection: $courseEndTime, displayedComponents: .hourAndMinute).labelsHidden().colorScheme(.dark)
                            }
                        }
                        
                        // Seminar Section
                        ArcadeSection(title: "SIDE QUEST (SEMINAR)", color: .orange) {
                            ArcadeInput(icon: "person.fill", placeholder: "Instructor", text: $seminarTeacher)
                            ArcadeInput(icon: "mappin.and.ellipse", placeholder: "Location", text: $seminarClassroom)
                            
                            // Days
                            HStack {
                                ForEach(daysOfWeek, id: \.0) { day in
                                    ArcadeDayChip(label: day.1, isSelected: selectedSeminarDays.contains(day.0), color: .orange) {
                                        if selectedSeminarDays.contains(day.0) { selectedSeminarDays.remove(day.0) } else { selectedSeminarDays.insert(day.0) }
                                    }
                                }
                            }
                            // Times
                            HStack {
                                DatePicker("", selection: $seminarStartTime, displayedComponents: .hourAndMinute).labelsHidden().colorScheme(.dark)
                                Text("TO").font(.caption).fontWeight(.bold).foregroundColor(.gray)
                                DatePicker("", selection: $seminarEndTime, displayedComponents: .hourAndMinute).labelsHidden().colorScheme(.dark)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("New Skill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Abort") { dismiss() }.foregroundColor(.red) }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Initialize") { saveSubject() }
                        .fontWeight(.black).foregroundColor(.cyan).disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveSubject() {
        let newSubject = Subject(
            title: title,
            courseTeacher: courseTeacher, courseClassroom: courseClassroom,
            courseStartTime: courseStartTime, courseEndTime: courseEndTime, courseDays: Array(selectedCourseDays).sorted(),
            seminarTeacher: seminarTeacher, seminarClassroom: seminarClassroom,
            seminarStartTime: seminarStartTime, seminarEndTime: seminarEndTime, seminarDays: Array(selectedSeminarDays).sorted()
        )
        modelContext.insert(newSubject)
        dismiss()
    }
}

// MARK: - 👾 RETRO ADD VIEW
struct RetroAddSubjectView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var courseTeacher = ""
    @State private var courseClassroom = ""
    @State private var selectedCourseDays: Set<Int> = []
    // Retro needs simplified fields for aesthetic, but we must pass all required fields to model
    @State private var seminarTeacher = ""
    @State private var seminarClassroom = ""
    
    private let daysOfWeek = [(1, "SUN"), (2, "MON"), (3, "TUE"), (4, "WED"), (5, "THU"), (6, "FRI"), (7, "SAT")]

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.05).ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("> INITIALIZE_NEW_SUBJECT").font(.system(.headline, design: .monospaced)).foregroundColor(.green)
                        
                        // Title
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TITLE_STRING:").font(.caption).foregroundColor(.gray).fontDesign(.monospaced)
                            TextField("...", text: $title)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.green)
                                .padding(8)
                                .border(Color.green.opacity(0.5), width: 1)
                        }
                        
                        // Course
                        VStack(alignment: .leading, spacing: 4) {
                            Text("INSTRUCTOR_ID:").font(.caption).foregroundColor(.gray).fontDesign(.monospaced)
                            TextField("...", text: $courseTeacher)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.green)
                                .padding(8)
                                .border(Color.green.opacity(0.5), width: 1)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("COORDINATES:").font(.caption).foregroundColor(.gray).fontDesign(.monospaced)
                            TextField("...", text: $courseClassroom)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.green)
                                .padding(8)
                                .border(Color.green.opacity(0.5), width: 1)
                        }
                        
                        // Days
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ACTIVE_CYCLE:").font(.caption).foregroundColor(.gray).fontDesign(.monospaced)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                                ForEach(daysOfWeek, id: \.0) { day in
                                    RetroDayCheck(label: day.1, isSelected: selectedCourseDays.contains(day.0)) {
                                        if selectedCourseDays.contains(day.0) { selectedCourseDays.remove(day.0) } else { selectedCourseDays.insert(day.0) }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("< EXIT") { dismiss() }.fontDesign(.monospaced).foregroundColor(.red) }
                ToolbarItem(placement: .navigationBarTrailing) { Button("[ EXECUTE ]") { saveSubject() }.fontDesign(.monospaced).foregroundColor(.green).disabled(title.isEmpty) }
            }
        }
    }
    
    private func saveSubject() {
        let newSubject = Subject(
            title: title,
            courseTeacher: courseTeacher,
            courseClassroom: courseClassroom,
            courseDays: Array(selectedCourseDays).sorted(),
            // Providing required empty strings for un-entered data in retro mode
            seminarTeacher: seminarTeacher,
            seminarClassroom: seminarClassroom
        )
        modelContext.insert(newSubject)
        dismiss()
    }
}
