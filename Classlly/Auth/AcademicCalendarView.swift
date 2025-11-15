//
//  AcademicCalendarView.swift
//  Classlly
//
//  Created by Robu Darius on 14.11.2025.
//


// File: Classlly/Auth/AcademicCalendar.swift
// Note: This is the main view for displaying the academic calendar.
// It is part of the "Settings" tab but is closely related to the
// auth/onboarding flow, so it's included here.

import SwiftUI

struct AcademicCalendarView: View {
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingCalendarManagement = false
    @State private var showingEditCalendar = false
    
    public init() {}
    
    var body: some View {
        // --- 1. REMOVED NavigationView WRAPPER ---
        ScrollView {
            VStack(spacing: 20) {
                // Calendar Header with Management
                calendarHeader
                
                // Current Week Card
                currentWeekCard
                
                // Semester Views
                SemesterView(
                    title: "Semester 1",
                    semester: .semester1,
                    calendarManager: calendarManager
                )
                
                SemesterView(
                    title: "Semester 2",
                    semester: .semester2,
                    calendarManager: calendarManager
                )
            }
            .padding()
        }
        // --- 2. MOVED MODIFIERS TO THE ScrollView ---
        .background(Color.themeBackground) // Use theme color
        .navigationTitle("Academic Calendar")
        .navigationBarTitleDisplayMode(.inline) // Use inline title
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingCalendarManagement = true }) {
                        Label("Manage Calendars", systemImage: "folder")
                    }
                    
                    Button(action: { showingEditCalendar = true }) {
                        Label("Edit Current Calendar", systemImage: "pencil")
                    }
                    
                    if calendarManager.currentAcademicYear != nil {
                        Button(action: {
                            let newCalendar = calendarManager.createNewCalendar(
                                year: "\(Calendar.current.component(.year, from: Date()))-\(Calendar.current.component(.year, from: Date()) + 1)",
                                universityName: "My University",
                                customName: "Custom Calendar"
                            )
                            calendarManager.addCustomCalendar(newCalendar)
                            calendarManager.setCurrentCalendar(newCalendar)
                            showingEditCalendar = true
                        }) {
                            Label("Create New Calendar", systemImage: "plus")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                }
            }
        }
        .sheet(isPresented: $showingCalendarManagement) {
            CalendarManagementView(calendarManager: calendarManager)
        }
        .sheet(isPresented: $showingEditCalendar) {
            if let calendar = calendarManager.currentAcademicYear {
                EditAcademicCalendarView(
                    calendar: calendar,
                    calendarManager: calendarManager
                )
            }
        }
    }
    
    private var calendarHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let calendar = calendarManager.currentAcademicYear {
                    Text(calendar.customName ?? calendar.academicYear)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.themeTextPrimary) // FIXED
                    
                    if let university = calendar.universityName {
                        Text(university)
                            .font(.subheadline)
                            .foregroundColor(.themeTextSecondary) // FIXED
                    }
                    
                    Text(calendar.academicYear)
                        .font(.caption)
                        .foregroundColor(.themeTextSecondary) // FIXED
                }
            }
            
            Spacer()
            
            Button("Switch Calendar") {
                showingCalendarManagement = true
            }
            .font(.subheadline)
            .foregroundColor(.themePrimary) // FIXED
        }
        .padding()
        .background(Color.themeSurface) // FIXED
        .cornerRadius(12)
    }
    
    private var currentWeekCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Academic Week")
                        .font(.headline)
                        .foregroundColor(.themeTextSecondary) // FIXED
                    
                    if let currentWeek = calendarManager.currentTeachingWeek {
                        Text("Week \(currentWeek)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.themePrimary) // FIXED
                    } else {
                        Text("Break Period")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.themeWarning) // FIXED
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(calendarManager.currentAcademicYear?.academicYear ?? "2025-2026")
                        .font(.subheadline)
                        .foregroundColor(.themeTextSecondary) // FIXED
                    
                    Text(calendarManager.currentSemester.displayName)
                        .font(.headline)
                        .foregroundColor(.themeTextPrimary) // FIXED
                }
            }
            
            if let currentEvent = calendarManager.getCurrentEvent(for: Date()) {
                HStack {
                    Image(systemName: currentEvent.type.iconName)
                        .foregroundColor(currentEvent.type.color)
                    
                    Text(currentEvent.customName ?? currentEvent.type.displayName)
                        .font(.subheadline)
                        .foregroundColor(.themeTextSecondary) // FIXED
                    
                    Spacer()
                    
                    Text("\(formatDate(currentEvent.start)) - \(formatDate(currentEvent.end))")
                        .font(.caption)
                        .foregroundColor(.themeTextSecondary) // FIXED
                }
            }
        }
        .padding()
        .background(Color.themeSurface) // FIXED
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM d"
        return outputFormatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct SemesterView: View {
    let title: String
    let semester: AcademicCalendarManager.SemesterType
    let calendarManager: AcademicCalendarManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.themeTextPrimary) // FIXED
            
            LazyVStack(spacing: 1) {
                ForEach(calendarManager.getSemesterEvents(semester)) { event in
                    AcademicEventRow(event: event, calendarManager: calendarManager)
                }
            }
            .background(Color.themeSurface) // FIXED
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator), lineWidth: 1)
            )
        }
    }
}

struct AcademicEventRow: View {
    let event: AcademicEventData
    let calendarManager: AcademicCalendarManager
    let isEditing: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    init(event: AcademicEventData, calendarManager: AcademicCalendarManager, isEditing: Bool = false) {
        self.event = event
        self.calendarManager = calendarManager
        self.isEditing = isEditing
    }
    
    private var isCurrentEvent: Bool {
        calendarManager.getCurrentEvent(for: Date())?.id == event.id
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(event.type.color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: event.type.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(event.type.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.customName ?? event.type.displayName)
                    .font(.headline)
                    .foregroundColor(.themeTextPrimary) // FIXED
                
                Text("\(formatDate(event.start)) - \(formatDate(event.end))")
                    .font(.subheadline)
                    .foregroundColor(.themeTextSecondary) // FIXED
                
                if event.type == .teaching, let start = event.teachingWeekIndexStart, let end = event.teachingWeekIndexEnd {
                    Text("Weeks \(start)-\(end)")
                        .font(.caption)
                        .foregroundColor(.themePrimary) // FIXED
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
            
            if isCurrentEvent && !isEditing {
                Circle()
                    .fill(Color.themeSuccess) // FIXED
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
        .background(isCurrentEvent && !isEditing ? Color.themePrimary.opacity(0.05) : Color.themeSurface) // FIXED
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentEvent && !isEditing ? Color.themePrimary.opacity(0.3) : Color.clear, lineWidth: 2) // FIXED
        )
    }
    
    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM d"
        return outputFormatter.string(from: date)
    }
}

// MARK: - Calendar Management View
struct CalendarManagementView: View {
    @ObservedObject var calendarManager: AcademicCalendarManager
    @Environment(\.dismiss) var dismiss
    @State private var showingCreateCalendar = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Available Calendars")) {
                    ForEach(calendarManager.availableCalendars, id: \.academicYear) { calendar in
                        CalendarRow(
                            calendar: calendar,
                            isCurrent: calendarManager.currentAcademicYear?.academicYear == calendar.academicYear,
                            onSelect: {
                                calendarManager.setCurrentCalendar(calendar)
                                dismiss()
                            },
                            onEdit: {
                                // Edit this calendar
                            },
                            onDelete: {
                                calendarManager.deleteCalendar(calendar)
                            }
                        )
                        .listRowBackground(Color.themeSurface) // FIXED
                    }
                }
                
                Section {
                    Button(action: { showingCreateCalendar = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.themeSuccess) // FIXED
                            Text("Create New Calendar")
                                .foregroundColor(.themeTextPrimary) // FIXED
                        }
                    }
                    .listRowBackground(Color.themeSurface) // FIXED
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.themeBackground) // FIXED
            .navigationTitle("Manage Calendars")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCreateCalendar) {
                CreateCalendarView(calendarManager: calendarManager)
            }
        }
        .preferredColorScheme(colorScheme)
    }
}

struct CalendarRow: View {
    let calendar: AcademicCalendarData
    let isCurrent: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(calendar.customName ?? calendar.academicYear)
                    .font(.headline)
                    .foregroundColor(.themeTextPrimary) // FIXED
                
                if let university = calendar.universityName {
                    Text(university)
                        .font(.subheadline)
                        .foregroundColor(.themeTextSecondary) // FIXED
                }
                
                Text(calendar.academicYear)
                    .font(.caption)
                    .foregroundColor(.themeTextSecondary) // FIXED
            }
            
            Spacer()
            
            if isCurrent {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.themeSuccess) // FIXED
            }
            
            Menu {
                Button("Select", action: onSelect)
                Button("Edit", action: onEdit)
                Button("Delete", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Create Calendar View
struct CreateCalendarView: View {
    @ObservedObject var calendarManager: AcademicCalendarManager
    @Environment(\.dismiss) var dismiss
    @State private var academicYear = ""
    @State private var universityName = ""
    @State private var customName = ""
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Calendar Details")) {
                    TextField("Academic Year (e.g., 2025-2026)", text: $academicYear)
                    TextField("University Name", text: $universityName)
                    TextField("Custom Calendar Name", text: $customName)
                }
                .listRowBackground(Color.themeSurface) // FIXED
                
                Section(footer: Text("You can add events and customize the calendar after creation.")) {
                    Button("Create Calendar") {
                        let newCalendar = calendarManager.createNewCalendar(
                            year: academicYear,
                            universityName: universityName,
                            customName: customName.isEmpty ? "\(universityName) \(academicYear)" : customName
                        )
                        calendarManager.addCustomCalendar(newCalendar)
                        calendarManager.setCurrentCalendar(newCalendar)
                        dismiss()
                    }
                    .disabled(academicYear.isEmpty || universityName.isEmpty)
                }
                .listRowBackground(Color.themeSurface) // FIXED
            }
            .scrollContentBackground(.hidden)
            .background(Color.themeBackground) // FIXED
            .navigationTitle("Create New Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(colorScheme)
    }
}

// MARK: - Edit Calendar View
struct EditAcademicCalendarView: View {
    @State var calendar: AcademicCalendarData
    @ObservedObject var calendarManager: AcademicCalendarManager
    @Environment(\.dismiss) var dismiss
    @State private var editingEvent: AcademicEventData?
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Calendar Information")) {
                    TextField("Academic Year", text: $calendar.academicYear)
                    TextField("University Name", text: Binding(
                        get: { calendar.universityName ?? "" },
                        set: { calendar.universityName = $0 }
                    ))
                    TextField("Custom Name", text: Binding(
                        get: { calendar.customName ?? "" },
                        set: { calendar.customName = $0 }
                    ))
                }
                .listRowBackground(Color.themeSurface) // FIXED
                
                Section(header: Text("Semester 1")) {
                    ForEach($calendar.semester1.events) { $event in
                        AcademicEventRow(event: event, calendarManager: calendarManager, isEditing: true)
                            .onTapGesture {
                                editingEvent = event
                            }
                    }
                    .onDelete { indices in
                        calendar.semester1.events.remove(atOffsets: indices)
                    }
                    
                    Button("Add Event to Semester 1") {
                        let newEvent = AcademicEventData(
                            start: "2025-09-01",
                            end: "2025-09-07",
                            type: .teaching,
                            weeks: 1,
                            teachingWeekIndexStart: nil,
                            teachingWeekIndexEnd: nil,
                            customName: "New Event"
                        )
                        calendar.semester1.events.append(newEvent)
                        editingEvent = newEvent
                    }
                }
                .listRowBackground(Color.themeSurface) // FIXED
                
                Section(header: Text("Semester 2")) {
                    ForEach($calendar.semester2.events) { $event in
                        AcademicEventRow(event: event, calendarManager: calendarManager, isEditing: true)
                            .onTapGesture {
                                editingEvent = event
                            }
                    }
                    .onDelete { indices in
                        calendar.semester2.events.remove(atOffsets: indices)
                    }
                    
                    Button("Add Event to Semester 2") {
                        let newEvent = AcademicEventData(
                            start: "2026-02-01",
                            end: "2026-02-07",
                            type: .teaching,
                            weeks: 1,
                            teachingWeekIndexStart: nil,
                            teachingWeekIndexEnd: nil,
                            customName: "New Event"
                        )
                        calendar.semester2.events.append(newEvent)
                        editingEvent = newEvent
                    }
                }
                .listRowBackground(Color.themeSurface) // FIXED
            }
            .scrollContentBackground(.hidden)
            .background(Color.themeBackground) // FIXED
            .navigationTitle("Edit Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        calendarManager.updateCalendar(calendar)
                        dismiss()
                    }
                }
            }
            .sheet(item: $editingEvent) { event in
                EditEventView(event: event) { updatedEvent in
                    if let index = calendar.semester1.events.firstIndex(where: { $0.id == event.id }) {
                        calendar.semester1.events[index] = updatedEvent
                    } else if let index = calendar.semester2.events.firstIndex(where: { $0.id == event.id }) {
                        calendar.semester2.events[index] = updatedEvent
                    }
                }
            }
        }
        .preferredColorScheme(colorScheme)
    }
}

// MARK: - Edit Event View
struct EditEventView: View {
    @State var event: AcademicEventData
    let onSave: (AcademicEventData) -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    
    init(event: AcademicEventData, onSave: @escaping (AcademicEventData) -> Void) {
        self._event = State(initialValue: event)
        self.onSave = onSave
        
        if let start = dateFormatter.date(from: event.start) {
            self._startDate = State(initialValue: start)
        }
        if let end = dateFormatter.date(from: event.end) {
            self._endDate = State(initialValue: end)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Event Name", text: Binding(
                        get: { event.customName ?? event.type.displayName },
                        set: { event.customName = $0 }
                    ))
                    
                    Picker("Event Type", selection: $event.type) {
                        ForEach(EventType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.iconName)
                                    .foregroundColor(type.color)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                .listRowBackground(Color.themeSurface) // FIXED
                
                if event.type == .teaching {
                    Section(header: Text("Teaching Weeks")) {
                        Stepper("Start Week: \(event.teachingWeekIndexStart ?? 0)", value: Binding(
                            get: { event.teachingWeekIndexStart ?? 1 },
                            set: { event.teachingWeekIndexStart = $0 }
                        ), in: 1...52)
                        
                        Stepper("End Week: \(event.teachingWeekIndexEnd ?? 0)", value: Binding(
                            get: { event.teachingWeekIndexEnd ?? 1 },
                            set: { event.teachingWeekIndexEnd = $0 }
                        ), in: 1...52)
                    }
                    .listRowBackground(Color.themeSurface) // FIXED
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.themeBackground) // FIXED
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        event.start = dateFormatter.string(from: startDate)
                        event.end = dateFormatter.string(from: endDate)
                        
                        // Calculate weeks
                        let calendar = Calendar.current
                        let components = calendar.dateComponents([.weekOfYear], from: startDate, to: endDate)
                        event.weeks = (components.weekOfYear ?? 0) + 1
                        
                        onSave(event)
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(colorScheme)
    }
}