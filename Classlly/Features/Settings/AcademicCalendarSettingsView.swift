import SwiftUI

struct AcademicCalendarSettingsView: View {
    @EnvironmentObject var themeManager: AppTheme
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .rainbow:
                RainbowCalendarSettingsView()
            case .standard:
                RainbowCalendarSettingsView()
            }
        }
    }
}

// MARK: - 🌟 THE "BETTER" CALENDAR EDITOR
struct RainbowCalendarSettingsView: View {
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @EnvironmentObject var themeManager: AppTheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSemester: AcademicCalendarManager.SemesterType = .semester1
    @State private var showingAddEvent = false
    @State private var showingTemplateSheet = false
    
    var body: some View {
        let accent = themeManager.selectedTheme.primaryColor
        let isRainbow = themeManager.selectedGameMode == .rainbow
        let isDark = themeManager.selectedGameMode != .standard
        
        ZStack {
            // Background
            if isDark {
                Color.black.ignoresSafeArea()
                if isRainbow {
                    RadialGradient(colors: [accent.opacity(0.2), .black], center: .topLeading, startRadius: 0, endRadius: 600).ignoresSafeArea()
                }
            } else {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                // 1. CUSTOM NAV BAR
                HStack {
                    // ✅ MODIFIED: Removed "Back" text, kept only the arrow
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(isDark ? .white : .primary)
                            .padding(8) // Better touch target
                    }
                    
                    Spacer()
                    
                    Text("ACADEMIC CALENDAR")
                        .font(.headline)
                        .fontWeight(.black)
                        .foregroundColor(isDark ? .white : .primary)
                        // Removed offset for better natural centering
                    
                    Spacer()
                    
                    // Invisible placeholder to balance the layout for perfect centering (Optional, but looks cleaner)
                    Image(systemName: "chevron.left").font(.system(size: 24)).opacity(0).padding(8)
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
                .background(isDark ? Color.black.opacity(0.8) : Color.white.opacity(0.8))
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 2. Switcher Card
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.title)
                                    .foregroundColor(accent)
                                Spacer()
                                
                                // Calendar Switcher Menu
                                Menu {
                                    Text("Switch Calendar")
                                    ForEach(calendarManager.availableCalendars) { cal in
                                        Button(action: {
                                            calendarManager.setCurrentCalendar(cal)
                                        }) {
                                            HStack {
                                                Text(cal.customName ?? cal.universityName ?? "Calendar")
                                                if calendarManager.currentAcademicYear?.id == cal.id {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    Button(action: { showingTemplateSheet = true }) {
                                        Label("Add New Calendar", systemImage: "plus")
                                    }
                                    
                                    if let current = calendarManager.currentAcademicYear, calendarManager.availableCalendars.count > 1 {
                                        Button(role: .destructive, action: {
                                            calendarManager.deleteCalendar(current)
                                        }) {
                                            Label("Delete Current", systemImage: "trash")
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(calendarManager.currentAcademicYear?.universityName ?? "Select Calendar")
                                            .font(.headline)
                                            .foregroundColor(isDark ? .white : .primary)
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(Color.gray.opacity(0.15))
                                    .cornerRadius(8)
                                }
                            }
                            
                            Divider().background(Color.gray)
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("CURRENT STATUS")
                                        .font(.caption).fontWeight(.bold).foregroundColor(.gray)
                                    if let week = calendarManager.currentTeachingWeek {
                                        Text("Teaching Week \(week)")
                                            .font(.title2).fontWeight(.black).foregroundColor(accent)
                                    } else {
                                        Text("Break / Exam Session")
                                            .font(.title2).fontWeight(.black).foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                            }
                        }
                        .padding()
                        .background(isDark ? Color(white: 0.1) : Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // 3. Semester Picker
                        Picker("Semester", selection: $selectedSemester) {
                            Text("Semester 1").tag(AcademicCalendarManager.SemesterType.semester1)
                            Text("Semester 2").tag(AcademicCalendarManager.SemesterType.semester2)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .colorScheme(isDark ? .dark : .light)
                        
                        // 4. Timeline Editor
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("TIMELINE")
                                    .font(.caption).fontWeight(.black).foregroundColor(.gray)
                                Spacer()
                                Button(action: { showingAddEvent = true }) {
                                    Label("Add Event", systemImage: "plus")
                                        .font(.caption).fontWeight(.bold)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 12)
                                        .background(accent.opacity(0.2))
                                        .foregroundColor(accent)
                                        .cornerRadius(20)
                                }
                            }
                            .padding(.horizontal)
                            
                            let events = calendarManager.getSemesterEvents(selectedSemester)
                            
                            if events.isEmpty {
                                ContentUnavailableView("No Events", systemImage: "calendar.badge.exclamationmark")
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                                        TimelineEventRow(event: event, isLast: index == events.count - 1)
                                            .contextMenu {
                                                Button(role: .destructive) {
                                                    calendarManager.removeEvent(from: selectedSemester, eventId: event.id)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                    }
                                }
                                .background(isDark ? Color(white: 0.1) : Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(16)
                                .padding(.horizontal)
                            }
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.top)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddEvent) {
            AddAcademicEventSheet(semester: selectedSemester)
        }
        .sheet(isPresented: $showingTemplateSheet) {
            TemplateSelectionSheet()
        }
    }
}

// MARK: - 🧩 TIMELINE ROW COMPONENT
struct TimelineEventRow: View {
    let event: AcademicEventData
    let isLast: Bool
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        let isDark = themeManager.selectedGameMode != .standard
        
        HStack(spacing: 16) {
            // Left Track
            VStack(spacing: 0) {
                Rectangle()
                    .fill(isLast ? Color.clear : Color.gray.opacity(0.3))
                    .frame(width: 2)
            }
            .overlay(
                Circle()
                    .fill(event.type.color)
                    .frame(width: 12, height: 12)
                    .background(Circle().stroke(isDark ? Color.black : Color.white, lineWidth: 2))
            )
            .frame(width: 20)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.customName ?? event.type.displayName)
                        .font(.headline)
                        .foregroundColor(isDark ? .white : .primary)
                    
                    Spacer()
                    
                    Text("\(event.weeks) wks")
                        .font(.caption).fontWeight(.bold)
                        .padding(4)
                        .background(event.type.color.opacity(0.2))
                        .foregroundColor(event.type.color)
                        .cornerRadius(4)
                }
                
                HStack {
                    Text(formatDate(event.start))
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                    Text(formatDate(event.end))
                }
                .font(.subheadline)
                .foregroundColor(.gray)
            }
            .padding(.vertical, 16)
        }
        .padding(.horizontal, 16)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        return date.formatted(.dateTime.day().month(.abbreviated))
    }
}

// MARK: - ➕ ADD EVENT SHEET
struct AddAcademicEventSheet: View {
    let semester: AcademicCalendarManager.SemesterType
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var type: EventType = .teaching
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 7 * 2) // +2 weeks
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Event Name (e.g. Exam Session)", text: $name)
                    Picker("Type", selection: $type) {
                        ForEach(EventType.allCases) { type in
                            Label(type.displayName, systemImage: type.iconName).tag(type)
                        }
                    }
                }
                
                Section("Duration") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Add to \(semester.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveEvent()
                    }
                }
            }
        }
    }
    
    private func saveEvent() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let diffComponents = Calendar.current.dateComponents([.weekOfYear], from: startDate, to: endDate)
        let weeks = max(1, diffComponents.weekOfYear ?? 1)
        
        let newEvent = AcademicEventData(
            start: formatter.string(from: startDate),
            end: formatter.string(from: endDate),
            type: type,
            weeks: weeks,
            customName: name.isEmpty ? type.displayName : name
        )
        
        calendarManager.addEvent(to: semester, event: newEvent)
        dismiss()
    }
}

// MARK: - 📄 TEMPLATE SELECTION SHEET
struct TemplateSelectionSheet: View {
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List(calendarManager.availableTemplates) { template in
                Button(action: {
                    calendarManager.generateAndSaveCalendar(from: template)
                    dismiss()
                }) {
                    VStack(alignment: .leading) {
                        Text(template.universityName)
                            .font(.headline)
                        Text(template.academicYear)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Choose Template")
            .toolbar {
                Button("Cancel") { dismiss() }
            }
        }
    }
}
