import SwiftUI
import SwiftData

struct AddSubjectView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var courseTeacher = ""
    @State private var courseClassroom = ""
    @State private var courseStartTime = Date()
    @State private var courseEndTime = Date().addingTimeInterval(3600)
    @State private var selectedCourseDays: Set<Int> = []
    @State private var courseFrequency: ClassFrequency = .weekly
    
    @State private var seminarTeacher = ""
    @State private var seminarClassroom = ""
    @State private var seminarStartTime = Date()
    @State private var seminarEndTime = Date().addingTimeInterval(3600)
    @State private var selectedSeminarDays: Set<Int> = []
    @State private var seminarFrequency: ClassFrequency = .weekly
    
    private let daysOfWeek = [
        (1, "Sun"), (2, "Mon"), (3, "Tue"), (4, "Wed"),
        (5, "Thu"), (6, "Fri"), (7, "Sat")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Subject Details")) {
                    TextField("Subject Title", text: $title)
                }
                
                Section(header: Text("Course Information")) {
                    TextField("Teacher", text: $courseTeacher)
                    TextField("Classroom", text: $courseClassroom)
                    
                    VStack(alignment: .leading) {
                        Text("Days").font(.caption).foregroundColor(.secondary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                            ForEach(daysOfWeek, id: \.0) { day in
                                DayToggle(
                                    day: day.1,
                                    isSelected: selectedCourseDays.contains(day.0)
                                ) {
                                    if selectedCourseDays.contains(day.0) {
                                        selectedCourseDays.remove(day.0)
                                    } else {
                                        selectedCourseDays.insert(day.0)
                                    }
                                }
                            }
                        }
                    }
                    
                    DatePicker("Start", selection: $courseStartTime, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: $courseEndTime, displayedComponents: .hourAndMinute)
                }
                
                Section(header: Text("Seminar Information (Optional)")) {
                    TextField("Teacher", text: $seminarTeacher)
                    TextField("Classroom", text: $seminarClassroom)
                    
                    VStack(alignment: .leading) {
                        Text("Days").font(.caption).foregroundColor(.secondary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                            ForEach(daysOfWeek, id: \.0) { day in
                                DayToggle(
                                    day: day.1,
                                    isSelected: selectedSeminarDays.contains(day.0)
                                ) {
                                    if selectedSeminarDays.contains(day.0) {
                                        selectedSeminarDays.remove(day.0)
                                    } else {
                                        selectedSeminarDays.insert(day.0)
                                    }
                                }
                            }
                        }
                    }
                    
                    DatePicker("Start", selection: $seminarStartTime, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: $seminarEndTime, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("New Subject")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveSubject() }
                        .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveSubject() {
        let newSubject = Subject(
            title: title,
            courseTeacher: courseTeacher,
            courseClassroom: courseClassroom,
            courseStartTime: courseStartTime,
            courseEndTime: courseEndTime,
            courseDays: Array(selectedCourseDays).sorted(),
            courseFrequency: courseFrequency,
            seminarTeacher: seminarTeacher,
            seminarClassroom: seminarClassroom,
            seminarStartTime: seminarStartTime,
            seminarEndTime: seminarEndTime,
            seminarDays: Array(selectedSeminarDays).sorted(),
            seminarFrequency: seminarFrequency
        )
        modelContext.insert(newSubject)
        dismiss()
    }
}

// Helper for Day Toggles
struct DayToggle: View {
    let day: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(day)
                .font(.caption2)
                .fontWeight(.bold)
                .frame(width: 32, height: 32)
                .background(isSelected ? Color.themePrimary : Color.themeSurface)
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
