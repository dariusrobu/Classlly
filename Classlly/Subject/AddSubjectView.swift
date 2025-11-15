// File: Classlly/Subject/AddSubjectView.swift
// Note: This file is corrected to create an empty Subject()
// and set its properties individually.

import SwiftUI
import SwiftData

struct AddSubjectView: View {
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
    
    private let daysOfWeek = [
        (1, "Sun"), (2, "Mon"), (3, "Tue"), (4, "Wed"),
        (5, "Thu"), (6, "Fri"), (7, "Sat")
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
                                    .foregroundColor(.themePrimary)
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
                            description: "Class occurs every week during teaching periods"
                        )
                        
                        FrequencyHelpRow(
                            frequency: .biweeklyOdd,
                            description: "Class occurs only in odd academic weeks (Week 1, 3, 5...)"
                        )
                        
                        FrequencyHelpRow(
                            frequency: .biweeklyEven,
                            description: "Class occurs only in even academic weeks (Week 2, 4, 6...)"
                        )
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Add Subject")
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
        // --- THIS IS THE FIX ---
        // 1. Create an empty Subject
        let newSubject = Subject()
        
        // 2. Set all properties
        newSubject.title = title
        newSubject.courseTeacher = courseTeacher
        newSubject.courseClassroom = courseClassroom
        newSubject.courseDate = courseDate
        newSubject.courseStartTime = courseStartTime
        newSubject.courseEndTime = courseEndTime
        newSubject.courseDays = Array(selectedCourseDays).sorted()
        newSubject.courseFrequency = courseFrequency
        newSubject.seminarTeacher = seminarTeacher
        newSubject.seminarClassroom = seminarClassroom
        newSubject.seminarDate = seminarDate
        newSubject.seminarStartTime = seminarStartTime
        newSubject.seminarEndTime = seminarEndTime
        newSubject.seminarDays = Array(selectedSeminarDays).sorted()
        newSubject.seminarFrequency = seminarFrequency
        
        // 3. Insert into the context
        modelContext.insert(newSubject)
        dismiss()
    }
}

// (Helper structs DayChip and FrequencyHelpRow are unchanged)

fileprivate struct DayChip: View {
    let day: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(day)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(height: 32)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.themePrimary : Color(.systemGray6))
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

fileprivate struct FrequencyHelpRow: View {
    let frequency: ClassFrequency
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: frequency.iconName)
                .foregroundColor(.themePrimary)
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
