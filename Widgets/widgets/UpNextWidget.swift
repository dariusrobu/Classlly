import WidgetKit
import SwiftUI
import SwiftData

// MARK: - 📅 SHARED DATA MODEL
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
    
    // ✨ Dynamic gradient based on the class color
    var bgGradient: LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.8), color.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
        
        // Refresh every 15 minutes to keep "Next" relevant
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    // MARK: - 🧠 LOGIC ENGINE
    private func calculateSchedule(for date: Date) -> UpNextEntry {
        // Create a local context for thread safety
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
        // ✅ CLEAN LAYOUT: No ZStack, no GeometryReader, no manual background.
        // The containerBackground modifier handles the edges perfectly.
        VStack(alignment: .leading, spacing: 0) {
            if let active = entry.currentClass {
                CurrentClassView(event: active)
            } else if let next = entry.nextClass {
                NextClassView(event: next)
            } else {
                EmptyStateView()
            }
        }
    }
}

// MARK: - 🧩 SUBVIEWS

struct CurrentClassView: View {
    let event: WidgetClassEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header Badge
            HStack {
                HStack(spacing: 4) {
                    Circle().fill(Color.green).frame(width: 6, height: 6)
                        .shadow(color: .green.opacity(0.8), radius: 4)
                    Text("NOW PLAYING")
                }
                .font(.system(size: 10, weight: .black, design: .rounded))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                
                Spacer()
                Image(systemName: "waveform.path.ecg")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Main Title
            Text(event.title)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(2)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                Text(event.room)
            }
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            // Progress Footer
            VStack(alignment: .leading, spacing: 6) {
                ProgressView(timerInterval: event.startTime...event.endTime, countsDown: false)
                    .tint(.white)
                    .scaleEffect(x: 1, y: 0.8, anchor: .center)
                
                HStack {
                    Text(event.startTime, style: .time)
                    Spacer()
                    Text(event.endTime, style: .time)
                }
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
            }
            .padding(10)
            .background(.black.opacity(0.2))
            .cornerRadius(12)
        }
    }
}

struct NextClassView: View {
    let event: WidgetClassEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("UP NEXT")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(event.color)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                
                Spacer()
                
                Text(event.startTime, style: .timer)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(event.color)
            }
            
            Spacer()
            
            // Title
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(event.color)
                    .frame(width: 4, height: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(event.room)
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Info Bar
            HStack {
                Label(
                    title: { Text(event.startTime, style: .time).foregroundColor(.white) },
                    icon: { Image(systemName: "clock.fill").foregroundColor(event.color) }
                )
                .font(.system(size: 12, weight: .bold))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(white: 0.15))
                .cornerRadius(8)
                
                Spacer()
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.purple.opacity(0.5), .blue.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 80, height: 80)
                    .blur(radius: 10)
                
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, .yellow.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: .purple.opacity(0.5), radius: 10, x: 0, y: 0)
            }
            .padding(.bottom, 10)
            
            Text("All Clear")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(.white)
            
            Text("No more classes today.\nTime to recharge.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 🚀 WIDGET CONFIG
struct UpNextWidget: Widget {
    let kind: String = "UpNextWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UpNextProvider()) { entry in
            UpNextWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                     // ✅ This is the ONLY place background is defined
                     if let active = entry.currentClass {
                         active.bgGradient
                     } else if entry.nextClass != nil {
                         Color(hex: "1c1c1e")
                     } else {
                         Color(hex: "000000")
                     }
                }
        }
        .configurationDisplayName("Up Next")
        .description("See your current class progress or what's coming next.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
