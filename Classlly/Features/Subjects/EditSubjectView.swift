import SwiftUI
import SwiftData

struct EditSubjectView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: AppTheme
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

    // --- Reordered to start on Monday ---
    private let daysOfWeek = [
        (2, "Mon"), (3, "Tue"), (4, "Wed"), (5, "Thu"),
        (6, "Fri"), (7, "Sat"), (1, "Sun")
    ]

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
                    TextField("Subject Title", text: $title)
                        .textInputAutocapitalization(.words)
                }

                Section(header: Text("Course Information")) {
                    TextField("Course Teacher", text: $courseTeacher)
                        .textInputAutocapitalization(.words)
                    TextField("Course Classroom", text: $courseClassroom)
                    
                    Picker("Frequency", selection: $courseFrequency) {
                        ForEach(ClassFrequency.allCases, id: \.self) { frequency in
                            HStack {
                                Image(systemName: frequency.iconName)
                                    .foregroundColor(themeManager.selectedTheme.accentColor)
                                Text(frequency.rawValue)
                            }
                            .tag(frequency)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Course Days")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                            ForEach(daysOfWeek, id: \.0) { day in
                                DayChip(
                                    day: day.1,
                                    isSelected: selectedCourseDays.contains(day.0),
                                    color: themeManager.selectedTheme.accentColor,
                                    action: {
                                        if selectedCourseDays.contains(day.0) {
                                            selectedCourseDays.remove(day.0)
                                        } else {
                                            selectedCourseDays.insert(day.0)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    DatePicker("Start Time", selection: $courseStartTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $courseEndTime, displayedComponents: .hourAndMinute)
                }

                Section(header: Text("Seminar Information")) {
                    TextField("Seminar Teacher", text: $seminarTeacher)
                        .textInputAutocapitalization(.words)
                    TextField("Seminar Classroom", text: $seminarClassroom)

                    Picker("Frequency", selection: $seminarFrequency) {
                        ForEach(ClassFrequency.allCases, id: \.self) { frequency in
                            HStack {
                                Image(systemName: frequency.iconName)
                                    .foregroundColor(.themeSuccess)
                                Text(frequency.rawValue)
                            }
                            .tag(frequency)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Seminar Days")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                            ForEach(daysOfWeek, id: \.0) { day in
                                DayChip(
                                    day: day.1,
                                    isSelected: selectedSeminarDays.contains(day.0),
                                    color: themeManager.selectedTheme.accentColor,
                                    action: {
                                        if selectedSeminarDays.contains(day.0) {
                                            selectedSeminarDays.remove(day.0)
                                        } else {
                                            selectedSeminarDays.insert(day.0)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    DatePicker("Start Time", selection: $seminarStartTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $seminarEndTime, displayedComponents: .hourAndMinute)
                }
                
                Section(header: Text("Frequency Help")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How frequencies work:")
                            .font(.headline)
                        
                        FrequencyHelpRow(
                            frequency: .weekly,
                            description: "Class occurs every week during teaching periods",
                            color: themeManager.selectedTheme.accentColor
                        )
                        
                        FrequencyHelpRow(
                            frequency: .biweeklyOdd,
                            description: "Class occurs only in odd academic weeks (Week 1, 3, 5...)",
                            color: themeManager.selectedTheme.accentColor
                        )
                        
                        FrequencyHelpRow(
                            frequency: .biweeklyEven,
                            description: "Class occurs only in even academic weeks (Week 2, 4, 6...)",
                            color: themeManager.selectedTheme.accentColor
                        )
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Edit Subject")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.themeError)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSubject()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.selectedTheme.accentColor)
                }
            }
        }
    }

    private var isFormValid: Bool {
        !title.isEmpty &&
        !courseTeacher.isEmpty &&
        !courseClassroom.isEmpty &&
        !selectedCourseDays.isEmpty
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

// --- HELPER STRUCTS ---

fileprivate struct DayChip: View {
    let day: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(day)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(height: 32)
                .frame(maxWidth: .infinity)
                .background(isSelected ? color : Color(.systemGray6))
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

fileprivate struct FrequencyHelpRow: View {
    let frequency: ClassFrequency
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: frequency.iconName)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(frequency.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}
