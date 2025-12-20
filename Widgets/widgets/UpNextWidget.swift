import WidgetKit
import SwiftUI
import SwiftData

// MARK: - 📅 SHARED LOGIC
struct WidgetClassEvent: Identifiable {
    let id = UUID()
    let title: String
    let room: String
    let startTime: Date
    let endTime: Date
    let colorHex: String
    
    var color: Color {
        Color(hex: colorHex)
    }
}

// MARK: - 💾 ENTRY
struct UpNextEntry: TimelineEntry {
    let date: Date
    let currentClass: WidgetClassEvent?
    let nextClass: WidgetClassEvent?
}

// MARK: - ⚙️ PROVIDER
struct UpNextProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> UpNextEntry {
        UpNextEntry(date: Date(), currentClass: nil, nextClass: getSampleEvent())
    }

    func getSnapshot(in context: Context, completion: @escaping (UpNextEntry) -> ()) {
        let entry = calculateSchedule(for: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UpNextEntry>) -> ()) {
        let currentDate = Date()
        let entry = calculateSchedule(for: currentDate)
        
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    // MARK: - 🧠 LOGIC ENGINE
    // ✅ FIX: Removed @MainActor. Local context creation makes this thread-safe.
    private func calculateSchedule(for date: Date) -> UpNextEntry {
        
        // Create a local context for this thread
        let modelContext = ModelContext(SharedModelContainer.shared)
        let descriptor = FetchDescriptor<Subject>()
        
        guard let subjects = try? modelContext.fetch(descriptor) else {
            return UpNextEntry(date: date, currentClass: nil, nextClass: nil)
        }
        
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        var events: [WidgetClassEvent] = []
        
        for s in subjects {
            // Check Course
            if s.courseDays.contains(weekday),
               let start = normalizeTime(s.courseStartTime, on: date),
               let end = normalizeTime(s.courseEndTime, on: date) {
                events.append(WidgetClassEvent(title: s.title, room: s.courseClassroom, startTime: start, endTime: end, colorHex: s.colorHex))
            }
            
            // Check Seminar
            if s.seminarDays.contains(weekday),
               let start = normalizeTime(s.seminarStartTime, on: date),
               let end = normalizeTime(s.seminarEndTime, on: date) {
                events.append(WidgetClassEvent(title: "\(s.title) (Sem)", room: s.seminarClassroom, startTime: start, endTime: end, colorHex: s.colorHex))
            }
        }
        
        events.sort { $0.startTime < $1.startTime }
        
        let current = events.first { $0.startTime <= date && $0.endTime > date }
        let next = events.first { $0.startTime > date }
        
        return UpNextEntry(date: date, currentClass: current, nextClass: next)
    }
    
    private func normalizeTime(_ time: Date, on date: Date) -> Date? {
        let calendar = Calendar.current
        let timeComp = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(bySettingHour: timeComp.hour ?? 0, minute: timeComp.minute ?? 0, second: 0, of: date)
    }
    
    private func getSampleEvent() -> WidgetClassEvent {
        WidgetClassEvent(
            title: "Computer Science",
            room: "Lab 304",
            startTime: Date().addingTimeInterval(3600),
            endTime: Date().addingTimeInterval(7200),
            colorHex: "007AFF"
        )
    }
}

// MARK: - 🎨 WIDGET VIEW
struct UpNextWidgetEntryView : View {
    var entry: UpNextProvider.Entry
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                if let active = entry.currentClass {
                    active.color.ignoresSafeArea()
                } else if let next = entry.nextClass {
                    next.color.ignoresSafeArea()
                } else {
                    Color(white: 0.1).ignoresSafeArea()
                }
                
                // Content
                VStack(alignment: .leading, spacing: 0) {
                    
                    if let active = entry.currentClass {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("NOW PLAYING")
                                    .font(.system(size: 10, weight: .black))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.white)
                                    .foregroundColor(active.color)
                                    .cornerRadius(4)
                                Spacer()
                                Image(systemName: "waveform.path.ecg")
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            Spacer()
                            Text(active.title)
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                            Text(active.room)
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            VStack(alignment: .leading, spacing: 4) {
                                ProgressView(timerInterval: active.startTime...active.endTime, countsDown: false)
                                    .tint(.white)
                                HStack {
                                    Text(active.startTime, style: .time)
                                    Spacer()
                                    Text(active.endTime, style: .time)
                                }
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                    else if let next = entry.nextClass {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("UP NEXT")
                                    .font(.system(size: 10, weight: .black))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.black.opacity(0.3))
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                                Spacer()
                                Image(systemName: "hourglass")
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            Spacer()
                            Text(next.title)
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(2)
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                Text(next.room)
                            }
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            HStack(alignment: .bottom) {
                                VStack(alignment: .leading) {
                                    Text("STARTS IN")
                                        .font(.system(size: 8, weight: .black))
                                        .foregroundColor(.white.opacity(0.7))
                                    Text(next.startTime, style: .timer)
                                        .font(.system(size: 24, weight: .black, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                Text(next.startTime, style: .time)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                    else {
                        VStack(alignment: .center, spacing: 12) {
                            Spacer()
                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.purple)
                            Text("ALL CLEAR")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            Text("No more classes today")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
        }
    }
}

struct UpNextWidget: Widget {
    let kind: String = "UpNextWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UpNextProvider()) { entry in
            UpNextWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                     if let active = entry.currentClass {
                         active.color
                     } else if let next = entry.nextClass {
                         next.color
                     } else {
                         Color(white: 0.1)
                     }
                }
        }
        .configurationDisplayName("Up Next")
        .description("See your current class progress or what's coming next.")
        .supportedFamilies([.systemMedium])
    }
}
