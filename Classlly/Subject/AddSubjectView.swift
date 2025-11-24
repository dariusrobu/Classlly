import SwiftUI
import SwiftData

struct AddSubjectView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: AppTheme

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
    
    // Mon start
    private let daysOfWeek = [
        (2, "Mon"), (3, "Tue"), (4, "Wed"), (5, "Thu"),
        (6, "Fri"), (7, "Sat"), (1, "Sun")
    ]
    
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
            }
            .navigationTitle("Add Subject")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.themeError)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveSubject() }
                        .disabled(!isFormValid)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.selectedTheme.accentColor)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && !courseTeacher.isEmpty && !courseClassroom.isEmpty && !selectedCourseDays.isEmpty
    }
    
    private func saveSubject() {
        // FIX: Removed 'gradeHistory' and 'attendanceHistory' args (they are now handled by defaults)
        let newSubject = Subject(
            title: title,
            courseTeacher: courseTeacher,
            courseClassroom: courseClassroom,
            courseDate: courseDate,
            courseStartTime: courseStartTime,
            courseEndTime: courseEndTime,
            courseDays: Array(selectedCourseDays).sorted(),
            courseFrequency: courseFrequency,
            seminarTeacher: seminarTeacher,
            seminarClassroom: seminarClassroom,
            seminarDate: seminarDate,
            seminarStartTime: seminarStartTime,
            seminarEndTime: seminarEndTime,
            seminarDays: Array(selectedSeminarDays).sorted(),
            seminarFrequency: seminarFrequency
        )
        modelContext.insert(newSubject)
        dismiss()
    }
}

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
