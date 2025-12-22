import SwiftUI
import SwiftData

struct AddSubjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Basic Info
    @State private var title = ""
    @State private var ectsCredits = 0
    @State private var colorHex = "007AFF"
    
    // Course Info
    @State private var courseTeacher = ""
    @State private var courseClassroom = ""
    @State private var courseFrequency: ClassFrequency = .weekly
    @State private var courseStartTime = Date()
    @State private var courseEndTime = Date().addingTimeInterval(3600)
    @State private var courseDays: Set<Int> = [] // Using Set for UI selection
    
    // Seminar Info
    @State private var hasSeminar = false
    @State private var seminarTeacher = ""
    @State private var seminarClassroom = ""
    @State private var seminarFrequency: ClassFrequency = .weekly
    @State private var seminarStartTime = Date()
    @State private var seminarEndTime = Date().addingTimeInterval(3600)
    @State private var seminarDays: Set<Int> = []

    let colors = ["007AFF", "FF3B30", "34C759", "FF9500", "AF52DE", "FF2D55", "5856D6", "5AC8FA"]
    let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    // Explicit initializer to resolve 'Argument passed to call that takes no arguments' error
    public init() {}

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Subject Name", text: $title)
                    Stepper("ECTS Credits: \(ectsCredits)", value: $ectsCredits, in: 0...30)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(colors, id: \.self) { hex in
                                Circle()
                                    // Fix: Removed '?? .gray' because Color(hex:) returns a non-optional Color
                                    .fill(Color(hex: hex))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: colorHex == hex ? 2 : 0)
                                    )
                                    .onTapGesture {
                                        colorHex = hex
                                    }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
                
                Section("Course Details") {
                    TextField("Teacher", text: $courseTeacher)
                    TextField("Room", text: $courseClassroom)
                    
                    DatePicker("Start Time", selection: $courseStartTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $courseEndTime, displayedComponents: .hourAndMinute)
                    
                    Picker("Frequency", selection: $courseFrequency) {
                        ForEach(ClassFrequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                    
                    // Day Selector
                    VStack(alignment: .leading) {
                        Text("Days")
                        HStack {
                            ForEach(0..<7) { index in
                                let dayNum = index + 1
                                Text(daysOfWeek[index])
                                    .font(.caption)
                                    .padding(8)
                                    .background(courseDays.contains(dayNum) ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundStyle(courseDays.contains(dayNum) ? .white : .primary)
                                    .clipShape(Circle())
                                    .onTapGesture {
                                        if courseDays.contains(dayNum) {
                                            courseDays.remove(dayNum)
                                        } else {
                                            courseDays.insert(dayNum)
                                        }
                                    }
                            }
                        }
                    }
                }
                
                Section {
                    Toggle("Add Seminar?", isOn: $hasSeminar)
                }
                
                if hasSeminar {
                    Section("Seminar Details") {
                        TextField("Teacher", text: $seminarTeacher)
                        TextField("Room", text: $seminarClassroom)
                        
                        DatePicker("Start Time", selection: $seminarStartTime, displayedComponents: .hourAndMinute)
                        DatePicker("End Time", selection: $seminarEndTime, displayedComponents: .hourAndMinute)
                        
                        // Seminar Day Selector
                        VStack(alignment: .leading) {
                            Text("Days")
                            HStack {
                                ForEach(0..<7) { index in
                                    let dayNum = index + 1
                                    Text(daysOfWeek[index])
                                        .font(.caption)
                                        .padding(8)
                                        .background(seminarDays.contains(dayNum) ? Color.blue : Color.gray.opacity(0.2))
                                        .foregroundStyle(seminarDays.contains(dayNum) ? .white : .primary)
                                        .clipShape(Circle())
                                        .onTapGesture {
                                            if seminarDays.contains(dayNum) {
                                                seminarDays.remove(dayNum)
                                            } else {
                                                seminarDays.insert(dayNum)
                                            }
                                        }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Subject")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSubject()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveSubject() {
        let newSubject = Subject(
            title: title,
            code: "", // No field in UI, default empty
            colorHex: colorHex,
            icon: "book.fill", // No icon picker, default
            credits: ectsCredits, // Correct label
            courseTeacher: courseTeacher,
            courseClassroom: courseClassroom,
            courseDays: Array(courseDays),
            courseFrequency: courseFrequency,
            courseStartTime: courseStartTime,
            courseEndTime: courseEndTime,
            hasSeminar: hasSeminar,
            seminarTeacher: seminarTeacher,
            seminarClassroom: seminarClassroom,
            seminarDays: Array(seminarDays),
            seminarFrequency: seminarFrequency,
            seminarStartTime: seminarStartTime,
            seminarEndTime: seminarEndTime
        )
        
        modelContext.insert(newSubject)
        dismiss()
    }
}
