import SwiftUI

// MARK: - MAIN SWITCHER
struct AcademicCalendarView: View {
    @EnvironmentObject var themeManager: AppTheme
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .arcade:
                ArcadeSemesterListView()
            case .rainbow:
                StandardSemesterListView()
                    .preferredColorScheme(.dark)
            case .none:
                StandardSemesterListView()
            }
        }
    }
}

// MARK: - 👔 STANDARD VIEW
struct StandardSemesterListView: View {
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingCalendarManagement = false
    @State private var showingEditCalendar = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if let calendar = calendarManager.currentAcademicYear {
                            Text(calendar.customName ?? calendar.academicYear)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            if let university = calendar.universityName {
                                Text(university)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(calendar.academicYear)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("No Calendar Selected")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Button("Switch") { showingCalendarManagement = true }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .padding()
                // Fallback colors used if .themeSurface not defined
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                // Current Status
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Academic Week").font(.headline).foregroundColor(.secondary)
                            if let currentWeek = calendarManager.currentTeachingWeek {
                                Text("Week \(currentWeek)").font(.system(size: 32, weight: .bold)).foregroundColor(.blue)
                            } else {
                                Text("Break Period").font(.system(size: 24, weight: .semibold)).foregroundColor(.orange)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(calendarManager.currentAcademicYear?.academicYear ?? "").font(.subheadline).foregroundColor(.secondary)
                            Text(calendarManager.currentSemester.displayName).font(.headline).foregroundColor(.primary)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                
                // Semesters
                SemesterSectionView(title: "Semester 1", events: calendarManager.getSemesterEvents(.semester1), calendarManager: calendarManager)
                SemesterSectionView(title: "Semester 2", events: calendarManager.getSemesterEvents(.semester2), calendarManager: calendarManager)
            }
            .padding()
        }
        .background(Color(UIColor.systemBackground))
        .navigationTitle("Academic Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingCalendarManagement = true }) { Label("Manage Calendars", systemImage: "folder") }
                    Button(action: { showingEditCalendar = true }) { Label("Edit Current Calendar", systemImage: "pencil") }
                    if calendarManager.currentAcademicYear != nil {
                        Button(action: { createNewCalendar() }) { Label("Create New Calendar", systemImage: "plus") }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle").font(.system(size: 20))
                }
            }
        }
        .sheet(isPresented: $showingCalendarManagement) { CalendarManagementView(calendarManager: calendarManager) }
        .sheet(isPresented: $showingEditCalendar) {
            if let calendar = calendarManager.currentAcademicYear { EditAcademicCalendarView(calendar: calendar, calendarManager: calendarManager) }
        }
    }
    
    private func createNewCalendar() {
        let newCalendar = calendarManager.createNewCalendar(year: "2025-2026", universityName: "My University", customName: "Custom Calendar")
        calendarManager.addCustomCalendar(newCalendar); calendarManager.setCurrentCalendar(newCalendar); showingEditCalendar = true
    }
}

// MARK: - 🕹️ ARCADE VIEW
struct ArcadeSemesterListView: View {
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @State private var showingCalendarManagement = false
    @State private var showingEditCalendar = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    ZStack {
                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing).mask(RoundedRectangle(cornerRadius: 20)).opacity(0.2)
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ACTIVE TIMELINE").font(.caption).fontWeight(.black).foregroundColor(.cyan)
                                if let calendar = calendarManager.currentAcademicYear {
                                    Text(calendar.customName?.uppercased() ?? calendar.academicYear).font(.system(.title3, design: .rounded)).fontWeight(.black).foregroundColor(.white)
                                    Text(calendar.universityName?.uppercased() ?? "").font(.caption).fontWeight(.bold).foregroundColor(.white.opacity(0.7))
                                } else { Text("NO DATA").font(.headline).foregroundColor(.gray) }
                            }
                            Spacer()
                            Button(action: { showingCalendarManagement = true }) { Text("SWITCH").font(.system(size: 10, weight: .black)).padding(8).background(Color.cyan).foregroundColor(.black).cornerRadius(8) }
                        }.padding()
                    }.overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.cyan.opacity(0.5), lineWidth: 1)).padding(.horizontal)
                    
                    // Status
                    VStack(spacing: 10) {
                        Text("CURRENT STATUS").font(.system(size: 10, weight: .black)).foregroundColor(.gray)
                        HStack {
                            if let week = calendarManager.currentTeachingWeek {
                                Text("WEEK").font(.system(size: 14, weight: .bold)).foregroundColor(.gray); Text("\(week)").font(.system(size: 40, weight: .black)).foregroundColor(.yellow).shadow(color: .yellow, radius: 10)
                            } else { Text("BREAK MODE").font(.system(.title, design: .rounded)).fontWeight(.black).foregroundColor(.green).shadow(color: .green, radius: 10) }
                        }
                        Text(calendarManager.currentSemester.displayName.uppercased()).font(.caption).fontWeight(.bold).foregroundColor(.white).padding(4).background(Color.white.opacity(0.1)).cornerRadius(4)
                    }.frame(maxWidth: .infinity).padding().background(Color(white: 0.05)).cornerRadius(20).padding(.horizontal)
                    
                    // Actions
                    HStack {
                        ArcadeActionButton(icon: "pencil", label: "EDIT CONFIG", color: .orange) { showingEditCalendar = true }
                        ArcadeActionButton(icon: "plus", label: "NEW TIMELINE", color: .green) { createNewCalendar() }
                    }.padding(.horizontal)
                    
                    // Semesters
                    VStack(spacing: 24) {
                        ArcadeSection(title: "PHASE 1 (SEM 1)", color: .purple) { ArcadeSemesterEvents(events: calendarManager.getSemesterEvents(.semester1), calendarManager: calendarManager) }
                        ArcadeSection(title: "PHASE 2 (SEM 2)", color: .pink) { ArcadeSemesterEvents(events: calendarManager.getSemesterEvents(.semester2), calendarManager: calendarManager) }
                    }.padding(.horizontal)
                }.padding(.top)
            }
            .navigationTitle("Timeline").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingCalendarManagement) { CalendarManagementView(calendarManager: calendarManager) }
            .sheet(isPresented: $showingEditCalendar) { if let calendar = calendarManager.currentAcademicYear { EditAcademicCalendarView(calendar: calendar, calendarManager: calendarManager) } }
        }.preferredColorScheme(.dark)
    }
    private func createNewCalendar() {
        let newCalendar = calendarManager.createNewCalendar(year: "2025-2026", universityName: "My University", customName: "Custom Calendar")
        calendarManager.addCustomCalendar(newCalendar); calendarManager.setCurrentCalendar(newCalendar); showingEditCalendar = true
    }
}

struct ArcadeSemesterEvents: View {
    let events: [AcademicEventData]
    let calendarManager: AcademicCalendarManager
    var body: some View {
        VStack(spacing: 8) {
            ForEach(events) { event in
                HStack {
                    Image(systemName: event.type.iconName).foregroundColor(event.type.color)
                    VStack(alignment: .leading) {
                        Text(event.customName ?? event.type.displayName).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(.white)
                        Text("\(formatDate(event.start)) - \(formatDate(event.end))").font(.system(size: 10)).foregroundColor(.gray)
                    }
                    Spacer()
                    if calendarManager.getCurrentEvent(for: Date())?.id == event.id { Text("ACTIVE").font(.system(size: 8, weight: .black)).foregroundColor(.black).padding(4).background(Color.green).cornerRadius(4) }
                    Text("\(event.weeks) WKS").font(.caption2).foregroundColor(.gray)
                }.padding(8).background(Color.black.opacity(0.5)).cornerRadius(8)
            }
        }
    }
    private func formatDate(_ dateString: String) -> String { let i = DateFormatter(); i.dateFormat = "yyyy-MM-dd"; guard let d = i.date(from: dateString) else { return dateString }; let o = DateFormatter(); o.dateFormat = "MMM d"; return o.string(from: d) }
}

// MARK: - SHARED SUPPORTING VIEWS

struct SemesterSectionView: View {
    let title: String
    let events: [AcademicEventData]
    let calendarManager: AcademicCalendarManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            // Using AcademicEventRow for consistency with Edit view and cleaner UI
            ForEach(events) { event in
                AcademicEventRow(event: event, calendarManager: calendarManager)
            }
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
                    .foregroundColor(.primary)
                
                Text("\(formatDate(event.start)) - \(formatDate(event.end))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if event.type == .teaching, let start = event.teachingWeekIndexStart, let end = event.teachingWeekIndexEnd {
                    Text("Weeks \(start)-\(end)")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
            
            if isCurrentEvent && !isEditing {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
        .background(isCurrentEvent && !isEditing ? Color.blue.opacity(0.05) : Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentEvent && !isEditing ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
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

// MARK: - MANAGEMENT SHEETS

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
                            onSelect: { calendarManager.setCurrentCalendar(calendar); dismiss() },
                            onEdit: { },
                            onDelete: { calendarManager.deleteCalendar(calendar) }
                        )
                        .listRowBackground(Color(UIColor.secondarySystemBackground))
                    }
                }
                Section {
                    Button(action: { showingCreateCalendar = true }) {
                        HStack { Image(systemName: "plus.circle.fill").foregroundColor(.green); Text("Create New Calendar").foregroundColor(.primary) }
                    }
                    .listRowBackground(Color(UIColor.secondarySystemBackground))
                }
            }
            .scrollContentBackground(.hidden).background(Color(UIColor.systemBackground))
            .navigationTitle("Manage Calendars").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
            .sheet(isPresented: $showingCreateCalendar) { CreateCalendarView(calendarManager: calendarManager) }
        }.preferredColorScheme(colorScheme)
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
                Text(calendar.customName ?? calendar.academicYear).font(.headline).foregroundColor(.primary)
                if let university = calendar.universityName { Text(university).font(.subheadline).foregroundColor(.secondary) }
                Text(calendar.academicYear).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            if isCurrent { Image(systemName: "checkmark.circle.fill").foregroundColor(.green) }
            Menu {
                Button("Select", action: onSelect)
                Button("Delete", role: .destructive, action: onDelete)
            } label: { Image(systemName: "ellipsis.circle").foregroundColor(.gray) }
        }.padding(.vertical, 4)
    }
}

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
                }.listRowBackground(Color(UIColor.secondarySystemBackground))
                
                Section(footer: Text("You can add events after creation.")) {
                    Button("Create Calendar") {
                        let newCalendar = calendarManager.createNewCalendar(
                            year: academicYear,
                            universityName: universityName,
                            customName: customName.isEmpty ? "\(universityName) \(academicYear)" : customName
                        )
                        calendarManager.addCustomCalendar(newCalendar)
                        calendarManager.setCurrentCalendar(newCalendar)
                        dismiss()
                    }.disabled(academicYear.isEmpty || universityName.isEmpty)
                }.listRowBackground(Color(UIColor.secondarySystemBackground))
            }
            .scrollContentBackground(.hidden).background(Color(UIColor.systemBackground))
            .navigationTitle("Create New Calendar").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } } }
        }.preferredColorScheme(colorScheme)
    }
}

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
                    TextField("University Name", text: Binding(get: { calendar.universityName ?? "" }, set: { calendar.universityName = $0 }))
                    TextField("Custom Name", text: Binding(get: { calendar.customName ?? "" }, set: { calendar.customName = $0 }))
                }.listRowBackground(Color(UIColor.secondarySystemBackground))
                
                Section(header: Text("Semester 1")) {
                    ForEach($calendar.semester1.events) { $event in
                        AcademicEventRow(event: event, calendarManager: calendarManager, isEditing: true).onTapGesture { editingEvent = event }
                    }.onDelete { calendar.semester1.events.remove(atOffsets: $0) }
                    Button("Add Event to Semester 1") {
                        let newEvent = AcademicEventData(start: "2025-09-01", end: "2025-09-07", type: .teaching, weeks: 1, customName: "New Event")
                        calendar.semester1.events.append(newEvent); editingEvent = newEvent
                    }
                }.listRowBackground(Color(UIColor.secondarySystemBackground))
                
                Section(header: Text("Semester 2")) {
                    ForEach($calendar.semester2.events) { $event in
                        AcademicEventRow(event: event, calendarManager: calendarManager, isEditing: true).onTapGesture { editingEvent = event }
                    }.onDelete { calendar.semester2.events.remove(atOffsets: $0) }
                    Button("Add Event to Semester 2") {
                        let newEvent = AcademicEventData(start: "2026-02-01", end: "2026-02-07", type: .teaching, weeks: 1, customName: "New Event")
                        calendar.semester2.events.append(newEvent); editingEvent = newEvent
                    }
                }.listRowBackground(Color(UIColor.secondarySystemBackground))
            }
            .scrollContentBackground(.hidden).background(Color(UIColor.systemBackground))
            .navigationTitle("Edit Calendar").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) { Button("Save") { calendarManager.updateCalendar(calendar); dismiss() } }
            }
            .sheet(item: $editingEvent) { event in
                EditEventView(event: event) { updated in
                    if let idx = calendar.semester1.events.firstIndex(where: { $0.id == event.id }) { calendar.semester1.events[idx] = updated }
                    else if let idx = calendar.semester2.events.firstIndex(where: { $0.id == event.id }) { calendar.semester2.events[idx] = updated }
                }
            }
        }.preferredColorScheme(colorScheme)
    }
}

struct EditEventView: View {
    @State var event: AcademicEventData
    let onSave: (AcademicEventData) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var startDate = Date()
    @State private var endDate = Date()
    @Environment(\.colorScheme) private var colorScheme
    
    init(event: AcademicEventData, onSave: @escaping (AcademicEventData) -> Void) {
        self._event = State(initialValue: event); self.onSave = onSave
        if let s = dateFormatter.date(from: event.start) { _startDate = State(initialValue: s) }
        if let e = dateFormatter.date(from: event.end) { _endDate = State(initialValue: e) }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Event Name", text: Binding(get: { event.customName ?? event.type.displayName }, set: { event.customName = $0 }))
                    Picker("Event Type", selection: $event.type) {
                        ForEach(EventType.allCases, id: \.self) { type in HStack { Image(systemName: type.iconName).foregroundColor(type.color); Text(type.displayName) }.tag(type) }
                    }
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }.listRowBackground(Color(UIColor.secondarySystemBackground))
                
                if event.type == .teaching {
                    Section(header: Text("Teaching Weeks")) {
                        Stepper("Start Week: \(event.teachingWeekIndexStart ?? 1)", value: Binding(get: { event.teachingWeekIndexStart ?? 1 }, set: { event.teachingWeekIndexStart = $0 }), in: 1...52)
                        Stepper("End Week: \(event.teachingWeekIndexEnd ?? 1)", value: Binding(get: { event.teachingWeekIndexEnd ?? 1 }, set: { event.teachingWeekIndexEnd = $0 }), in: 1...52)
                    }.listRowBackground(Color(UIColor.secondarySystemBackground))
                }
            }
            .scrollContentBackground(.hidden).background(Color(UIColor.systemBackground))
            .navigationTitle("Edit Event").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) { Button("Save") {
                    event.start = dateFormatter.string(from: startDate)
                    event.end = dateFormatter.string(from: endDate)
                    event.weeks = (Calendar.current.dateComponents([.weekOfYear], from: startDate, to: endDate).weekOfYear ?? 0) + 1
                    onSave(event); dismiss()
                } }
            }
        }.preferredColorScheme(colorScheme)
    }
}

private let dateFormatter: DateFormatter = { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f }()
