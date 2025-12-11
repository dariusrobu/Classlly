import SwiftUI
import SwiftData

struct EditSubjectView: View {
    @EnvironmentObject var themeManager: AppTheme
    @Bindable var subject: Subject
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .arcade:
                ArcadeEditSubjectView(subject: subject)
            case .rainbow:
                StandardEditSubjectView(subject: subject).preferredColorScheme(.dark)
            case .none:
                StandardEditSubjectView(subject: subject)
            }
        }
    }
}

// MARK: - 👔 STANDARD VIEW
struct StandardEditSubjectView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var subject: Subject

    @State private var title: String
    @State private var courseTeacher: String
    @State private var courseClassroom: String
    @State private var courseStartTime: Date
    @State private var courseEndTime: Date
    @State private var selectedCourseDays: Set<Int>
    @State private var courseFrequency: ClassFrequency

    @State private var seminarTeacher: String
    @State private var seminarClassroom: String
    @State private var seminarStartTime: Date
    @State private var seminarEndTime: Date
    @State private var selectedSeminarDays: Set<Int>
    @State private var seminarFrequency: ClassFrequency

    private let daysOfWeek = [(1, "Sun"), (2, "Mon"), (3, "Tue"), (4, "Wed"), (5, "Thu"), (6, "Fri"), (7, "Sat")]

    init(subject: Subject) {
        self.subject = subject
        _title = State(initialValue: subject.title)
        _courseTeacher = State(initialValue: subject.courseTeacher)
        _courseClassroom = State(initialValue: subject.courseClassroom)
        _courseStartTime = State(initialValue: subject.courseStartTime)
        _courseEndTime = State(initialValue: subject.courseEndTime)
        _selectedCourseDays = State(initialValue: Set(subject.courseDays))
        _courseFrequency = State(initialValue: subject.courseFrequency)

        _seminarTeacher = State(initialValue: subject.seminarTeacher)
        _seminarClassroom = State(initialValue: subject.seminarClassroom)
        _seminarStartTime = State(initialValue: subject.seminarStartTime)
        _seminarEndTime = State(initialValue: subject.seminarEndTime)
        _selectedSeminarDays = State(initialValue: Set(subject.seminarDays))
        _seminarFrequency = State(initialValue: subject.seminarFrequency)
    }

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
            .navigationTitle("Edit Subject")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() }.foregroundColor(.themeError) }
                ToolbarItem(placement: .navigationBarTrailing) { Button("Save") { saveSubject() }.disabled(title.isEmpty).fontWeight(.semibold) }
            }
        }
    }

    private func saveSubject() {
        subject.title = title
        subject.courseTeacher = courseTeacher
        subject.courseClassroom = courseClassroom
        subject.courseStartTime = courseStartTime
        subject.courseEndTime = courseEndTime
        subject.courseDays = Array(selectedCourseDays).sorted()
        subject.courseFrequency = courseFrequency
        subject.seminarTeacher = seminarTeacher
        subject.seminarClassroom = seminarClassroom
        subject.seminarStartTime = seminarStartTime
        subject.seminarEndTime = seminarEndTime
        subject.seminarDays = Array(selectedSeminarDays).sorted()
        subject.seminarFrequency = seminarFrequency
        dismiss()
    }
}

// MARK: - 🕹️ ARCADE VIEW
struct ArcadeEditSubjectView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var subject: Subject

    @State private var title: String
    @State private var courseTeacher: String
    @State private var courseClassroom: String
    @State private var selectedCourseDays: Set<Int>
    
    private let daysOfWeek = [(1, "S"), (2, "M"), (3, "T"), (4, "W"), (5, "T"), (6, "F"), (7, "S")]
    
    init(subject: Subject) {
        self.subject = subject
        _title = State(initialValue: subject.title)
        _courseTeacher = State(initialValue: subject.courseTeacher)
        _courseClassroom = State(initialValue: subject.courseClassroom)
        _selectedCourseDays = State(initialValue: Set(subject.courseDays))
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading) {
                            Text("RENAME SKILL").font(.caption).fontWeight(.black).foregroundColor(.cyan)
                            TextField("...", text: $title)
                                .padding().background(Color(white: 0.1)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cyan, lineWidth: 1)).foregroundColor(.white)
                        }
                        
                        ArcadeSection(title: "MAIN QUEST CONFIG", color: .purple) {
                            ArcadeInput(icon: "person.fill", placeholder: "Instructor", text: $courseTeacher)
                            ArcadeInput(icon: "mappin.and.ellipse", placeholder: "Location", text: $courseClassroom)
                            HStack {
                                ForEach(daysOfWeek, id: \.0) { day in
                                    ArcadeDayChip(label: day.1, isSelected: selectedCourseDays.contains(day.0), color: .purple) {
                                        if selectedCourseDays.contains(day.0) { selectedCourseDays.remove(day.0) } else { selectedCourseDays.insert(day.0) }
                                    }
                                }
                            }
                        }
                    }.padding()
                }
            }
            .navigationTitle("Configure Skill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() }.foregroundColor(.gray) }
                ToolbarItem(placement: .navigationBarTrailing) { Button("Update") { saveSubject() }.fontWeight(.black).foregroundColor(.cyan) }
            }
        }
    }
    
    private func saveSubject() {
        subject.title = title
        subject.courseTeacher = courseTeacher
        subject.courseClassroom = courseClassroom
        subject.courseDays = Array(selectedCourseDays).sorted()
        dismiss()
    }
}

// MARK: - 👾 RETRO VIEW
struct RetroEditSubjectView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var subject: Subject

    @State private var title: String
    @State private var courseTeacher: String
    @State private var courseClassroom: String
    
    init(subject: Subject) {
        self.subject = subject
        _title = State(initialValue: subject.title)
        _courseTeacher = State(initialValue: subject.courseTeacher)
        _courseClassroom = State(initialValue: subject.courseClassroom)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.05).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("> MODIFY_FILE_HEADER").font(.system(.headline, design: .monospaced)).foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TITLE_STRING:").font(.caption).foregroundColor(.gray).fontDesign(.monospaced)
                            TextField("...", text: $title)
                                .font(.system(.body, design: .monospaced)).foregroundColor(.green).padding(8).border(Color.green.opacity(0.5), width: 1)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("INSTRUCTOR_ID:").font(.caption).foregroundColor(.gray).fontDesign(.monospaced)
                            TextField("...", text: $courseTeacher)
                                .font(.system(.body, design: .monospaced)).foregroundColor(.green).padding(8).border(Color.green.opacity(0.5), width: 1)
                        }
                    }.padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("< BACK") { dismiss() }.fontDesign(.monospaced).foregroundColor(.gray) }
                ToolbarItem(placement: .navigationBarTrailing) { Button("[ OVERWRITE ]") { saveSubject() }.fontDesign(.monospaced).foregroundColor(.green) }
            }
        }
    }
    
    private func saveSubject() {
        subject.title = title
        subject.courseTeacher = courseTeacher
        dismiss()
    }
}
