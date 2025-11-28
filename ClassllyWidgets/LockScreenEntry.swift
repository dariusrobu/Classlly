import WidgetKit
import SwiftUI
import SwiftData

// MARK: - 1. Timeline Entry
struct LockScreenEntry: TimelineEntry {
    let date: Date
    let nextSubject: Subject?
    let totalTasksToday: Int
    let completedTasksToday: Int
    
    var progress: Double {
        guard totalTasksToday > 0 else { return 0 }
        return Double(completedTasksToday) / Double(totalTasksToday)
    }
}

// MARK: - 2. Provider
struct LockScreenProvider: TimelineProvider {
    
    @MainActor
    func fetchData() -> (Subject?, Int, Int) {
        let modelContainer = SharedModelContainer.create()
        let context = modelContainer.mainContext
        
        // 1. Fetch Subjects
        let subjectDescriptor = FetchDescriptor<Subject>()
        let subjects = (try? context.fetch(subjectDescriptor)) ?? []
        
        // Logic: Find next upcoming subject for TODAY
        let now = Date()
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: now)
        let currentMinutes = (calendar.component(.hour, from: now) * 60) + calendar.component(.minute, from: now)
        
        let todaySubjects = subjects.filter { $0.courseDays.contains(currentWeekday) }
        
        // Sort by time and find the first one starting after right now
        let nextSubject = todaySubjects
            .filter { subject in
                let startHour = calendar.component(.hour, from: subject.courseStartTime)
                let startMinute = calendar.component(.minute, from: subject.courseStartTime)
                let startTotalMinutes = (startHour * 60) + startMinute
                return startTotalMinutes > currentMinutes
            }
            .sorted { s1, s2 in
                let t1 = calendar.dateComponents([.hour, .minute], from: s1.courseStartTime)
                let t2 = calendar.dateComponents([.hour, .minute], from: s2.courseStartTime)
                let m1 = (t1.hour ?? 0) * 60 + (t1.minute ?? 0)
                let m2 = (t2.hour ?? 0) * 60 + (t2.minute ?? 0)
                return m1 < m2
            }
            .first
        
        // 2. Fetch Tasks
        let taskDescriptor = FetchDescriptor<StudyTask>()
        let tasks = (try? context.fetch(taskDescriptor)) ?? []
        
        let todayTasks = tasks.filter { task in
            guard let due = task.dueDate else { return false }
            return calendar.isDateInToday(due)
        }
        
        let total = todayTasks.count
        let completed = todayTasks.filter { $0.isCompleted }.count
        
        return (nextSubject, total, completed)
    }

    func placeholder(in context: Context) -> LockScreenEntry {
        LockScreenEntry(date: Date(), nextSubject: nil, totalTasksToday: 5, completedTasksToday: 3)
    }

    func getSnapshot(in context: Context, completion: @escaping (LockScreenEntry) -> Void) {
        Task { @MainActor in
            let data = fetchData()
            let entry = LockScreenEntry(
                date: Date(),
                nextSubject: data.0,
                totalTasksToday: data.1,
                completedTasksToday: data.2
            )
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LockScreenEntry>) -> Void) {
        Task { @MainActor in
            let data = fetchData()
            let entry = LockScreenEntry(
                date: Date(),
                nextSubject: data.0,
                totalTasksToday: data.1,
                completedTasksToday: data.2
            )
            
            // Refresh every 15 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

// MARK: - 3. Widget View
struct LockScreenWidgetEntryView: View {
    var entry: LockScreenProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular:
                // "Up Next" - Rectangular
                if let subject = entry.nextSubject {
                    HStack(spacing: 8) {
                        // Vertical Bar
                        Capsule()
                            .fill(Color.accentColor) // Or .themePrimary if available
                            .frame(width: 4)
                            .padding(.vertical, 2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(subject.title)
                                .font(.headline)
                                .widgetAccentable() // Allows user to tint it on Lock Screen
                            
                            Text("\(subject.courseClassroom) • \(formatTime(subject.courseStartTime))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                } else {
                    // Fallback state
                    VStack(alignment: .leading) {
                        Text("No Classes")
                            .font(.headline)
                        Text("Rest of the day")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
            case .accessoryCircular:
                // "Task Progress" - Circular
                Gauge(value: entry.progress) {
                    Text("Tasks")
                } currentValueLabel: {
                    Text("\(entry.completedTasksToday)/\(entry.totalTasksToday)")
                        .font(.system(size: 10, weight: .bold)) // Adjust for small circle
                }
                .gaugeStyle(.accessoryCircularCapacity)
                
            default:
                EmptyView()
            }
        }
        // ✅ FIX: Required for iOS 17+ Widgets (even transparent ones)
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - 4. Widget Configuration
struct LockScreenWidget: Widget {
    let kind: String = "LockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockScreenProvider()) { entry in
            LockScreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Classlly Glance")
        .description("See your next class or task progress.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular])
        .contentMarginsDisabled()
    }
}
