import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

// MARK: - 1. App Intent (Interactivity)
struct CheckInIntent: AppIntent {
    static var title: LocalizedStringResource = "Check In to Class"
    static var description: IntentDescription = "Marks attendance for the active class."

    @Parameter(title: "Subject ID")
    var subjectID: String?

    init() {}

    init(subjectID: String) {
        self.subjectID = subjectID
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let idString = subjectID, let uuid = UUID(uuidString: idString) else {
            return .result()
        }

        // Use the SharedModelContainer to access the shared database
        let modelContainer = SharedModelContainer.create()
        let context = modelContainer.mainContext
        
        let descriptor = FetchDescriptor<Subject>(
            predicate: #Predicate<Subject> { $0.id == uuid }
        )

        do {
            // 1. Find the active subject
            if let subject = try context.fetch(descriptor).first {
                
                // 2. Create new Attendance Entry
                let newEntry = AttendanceEntry(
                    date: Date(),
                    attended: true,
                    notes: "Checked in via Widget"
                )
                
                // 3. Insert into Context & Set Relationship
                context.insert(newEntry)
                newEntry.subject = subject
                
                // 4. Save
                try context.save()
                
                // Refresh the widget to show updated state if needed
                WidgetCenter.shared.reloadTimelines(ofKind: "AttendanceCheckInWidget")
            }
        } catch {
            print("Failed to perform CheckInIntent: \(error)")
        }

        return .result()
    }
}

// MARK: - 2. Timeline Entry
struct AttendanceEntryModel: TimelineEntry {
    let date: Date
    let activeSubject: Subject?
    let isClassActive: Bool
}

// MARK: - 3. Timeline Provider
struct AttendanceCheckInProvider: TimelineProvider {
    
    @MainActor
    func getActiveSubject() -> Subject? {
        // Access shared data
        let modelContainer = SharedModelContainer.create()
        let context = modelContainer.mainContext
        
        let descriptor = FetchDescriptor<Subject>()
        guard let subjects = try? context.fetch(descriptor) else { return nil }
        
        let now = Date()
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: now)
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        // Convert current time to "minutes from midnight" for easier comparison
        let currentMinutesFromMidnight = (currentHour * 60) + currentMinute
        
        return subjects.first { subject in
            // 1. Check Course Days
            guard subject.courseDays.contains(currentWeekday) else { return false }
            
            // 2. Check Time Range
            // Extract HH:mm components from the subject's dates
            let startHour = calendar.component(.hour, from: subject.courseStartTime)
            let startMinute = calendar.component(.minute, from: subject.courseStartTime)
            let startTotalMinutes = (startHour * 60) + startMinute
            
            let endHour = calendar.component(.hour, from: subject.courseEndTime)
            let endMinute = calendar.component(.minute, from: subject.courseEndTime)
            let endTotalMinutes = (endHour * 60) + endMinute
            
            return currentMinutesFromMidnight >= startTotalMinutes && currentMinutesFromMidnight <= endTotalMinutes
        }
    }

    func placeholder(in context: Context) -> AttendanceEntryModel {
        AttendanceEntryModel(date: Date(), activeSubject: nil, isClassActive: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (AttendanceEntryModel) -> Void) {
        Task { @MainActor in
            let activeSubject = getActiveSubject()
            let entry = AttendanceEntryModel(
                date: Date(),
                activeSubject: activeSubject,
                isClassActive: activeSubject != nil
            )
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AttendanceEntryModel>) -> Void) {
        Task { @MainActor in
            let activeSubject = getActiveSubject()
            let currentDate = Date()
            
            let entry = AttendanceEntryModel(
                date: currentDate,
                activeSubject: activeSubject,
                isClassActive: activeSubject != nil
            )
            
            // Refresh every 15 minutes to check for new classes starting
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate
            
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

// MARK: - 4. Widget View
struct AttendanceCheckInWidgetEntryView: View {
    var entry: AttendanceCheckInProvider.Entry
    
    // Using your theme colors for the gradient
    // Note: Ensure Color+Theme.swift is included in the Widget Target Membership
    let activeGradient = LinearGradient(
        colors: [.themePrimary, .themeSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        Group {
            if entry.isClassActive, let subject = entry.activeSubject {
                // --- ACTIVE CLASS STATE ---
                VStack(alignment: .leading) {
                    Text("Happening Now")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white.opacity(0.8))
                        .textCase(.uppercase)
                    
                    Text(subject.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    // Interactive Check-In Button
                    Button(intent: CheckInIntent(subjectID: subject.id.uuidString)) {
                        HStack {
                            Image(systemName: "checkmark")
                                .font(.system(size: 18, weight: .bold))
                            Text("Check In")
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.themeSuccess)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle()) // Necessary for Widget interaction
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            } else {
                // --- NO CLASS STATE ---
                VStack(spacing: 6) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                    
                    Text("No Class Now")
                        .font(.headline)
                        .foregroundStyle(Color.themeTextPrimary)
                    
                    Text("Relax & Prepare")
                        .font(.caption)
                        .foregroundStyle(Color.themeTextSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .containerBackground(for: .widget) {
            if entry.isClassActive {
                activeGradient
            } else {
                Color.themeSurface
            }
        }
    }
}

// MARK: - 5. Widget Configuration
struct AttendanceCheckInWidget: Widget {
    let kind: String = "AttendanceCheckInWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AttendanceCheckInProvider()) { entry in
            AttendanceCheckInWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Quick Attendance")
        .description("Instantly mark attendance for your current class.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}
