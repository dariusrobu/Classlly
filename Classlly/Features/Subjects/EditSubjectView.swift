import SwiftUI
import SwiftData

struct EditSubjectView: View {
    @Environment(\.dismiss) private var dismiss
    
    // DIRECT BINDING: This allows us to write directly to the SwiftData object
    @Bindable var subject: Subject
    
    let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    var body: some View {
        Form {
            Section("Basic Info") {
                TextField("Subject Name", text: $subject.title)
                Stepper("ECTS Credits: \(subject.ectsCredits)", value: $subject.ectsCredits, in: 0...30)
            }
            
            Section("Course Details") {
                TextField("Teacher", text: $subject.courseTeacher)
                TextField("Room", text: $subject.courseClassroom)
                
                DatePicker("Start Time", selection: $subject.courseStartTime, displayedComponents: .hourAndMinute)
                DatePicker("End Time", selection: $subject.courseEndTime, displayedComponents: .hourAndMinute)
                
                Picker("Frequency", selection: $subject.courseFrequency) {
                    ForEach(ClassFrequency.allCases, id: \.self) { freq in
                        Text(freq.rawValue).tag(freq)
                    }
                }
                
                // Custom Day Selector for Edit View
                VStack(alignment: .leading) {
                    Text("Days")
                    HStack {
                        ForEach(0..<7) { index in
                            let dayNum = index + 1
                            Text(daysOfWeek[index])
                                .font(.caption)
                                .padding(8)
                                .background(subject.courseDays.contains(dayNum) ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundStyle(subject.courseDays.contains(dayNum) ? .white : .primary)
                                .clipShape(Circle())
                                .onTapGesture {
                                    toggleCourseDay(dayNum)
                                }
                        }
                    }
                }
            }
            
            Section {
                Toggle("Has Seminar?", isOn: $subject.hasSeminar)
            }
            
            if subject.hasSeminar {
                Section("Seminar Details") {
                    TextField("Teacher", text: $subject.seminarTeacher)
                    TextField("Room", text: $subject.seminarClassroom)
                    
                    DatePicker("Start Time", selection: $subject.seminarStartTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $subject.seminarEndTime, displayedComponents: .hourAndMinute)
                    
                    VStack(alignment: .leading) {
                        Text("Days")
                        HStack {
                            ForEach(0..<7) { index in
                                let dayNum = index + 1
                                Text(daysOfWeek[index])
                                    .font(.caption)
                                    .padding(8)
                                    .background(subject.seminarDays.contains(dayNum) ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundStyle(subject.seminarDays.contains(dayNum) ? .white : .primary)
                                    .clipShape(Circle())
                                    .onTapGesture {
                                        toggleSeminarDay(dayNum)
                                    }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Edit Subject")
        .toolbar {
            Button("Done") {
                dismiss()
            }
        }
    }
    
    // Helpers to manage the [Int] arrays since SwiftUI Bindings don't like arrays directly in this specific way
    private func toggleCourseDay(_ day: Int) {
        if let idx = subject.courseDays.firstIndex(of: day) {
            subject.courseDays.remove(at: idx)
        } else {
            subject.courseDays.append(day)
        }
    }
    
    private func toggleSeminarDay(_ day: Int) {
        if let idx = subject.seminarDays.firstIndex(of: day) {
            subject.seminarDays.remove(at: idx)
        } else {
            subject.seminarDays.append(day)
        }
    }
}
