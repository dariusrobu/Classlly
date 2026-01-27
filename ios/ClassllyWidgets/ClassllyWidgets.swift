import WidgetKit
import SwiftUI

// MARK: - Up Next & Lock Screen Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> UpNextEntry {
        UpNextEntry(date: Date(), nextClassTitle: "Physics 101", nextClassTime: "10:00 AM", nextClassLocation: "Room 304", nextTaskTitle: "Read Chapter 4", nextTaskDate: "Tomorrow", todayTaskCount: 3)
    }

    func getSnapshot(in context: Context, completion: @escaping (UpNextEntry) -> ()) {
        let entry = getData()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = getData()
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }

    private func getData() -> UpNextEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.robudarius.classlly")
        let title = userDefaults?.string(forKey: "next_class_title") ?? "No upcoming classes"
        let time = userDefaults?.string(forKey: "next_class_time") ?? ""
        let location = userDefaults?.string(forKey: "next_class_location") ?? ""
        
        let taskTitle = userDefaults?.string(forKey: "next_task_title") ?? "No pending tasks"
        let taskDate = userDefaults?.string(forKey: "next_task_date") ?? ""
        let todayTaskCount = userDefaults?.integer(forKey: "today_task_count") ?? 0
        
        return UpNextEntry(date: Date(), nextClassTitle: title, nextClassTime: time, nextClassLocation: location, nextTaskTitle: taskTitle, nextTaskDate: taskDate, todayTaskCount: todayTaskCount)
    }
}

struct UpNextEntry: TimelineEntry {
    let date: Date
    let nextClassTitle: String
    let nextClassTime: String
    let nextClassLocation: String
    let nextTaskTitle: String
    let nextTaskDate: String
    let todayTaskCount: Int
}

// MARK: - Views

struct ClassllyWidgetsEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallView(entry: entry)
        case .accessoryCircular:
            CircularLockScreenView(entry: entry)
        case .accessoryRectangular:
            RectangularLockScreenView(entry: entry)
        default:
            MediumView(entry: entry)
        }
    }
}

struct CircularLockScreenView: View {
    var entry: Provider.Entry
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text("\(entry.todayTaskCount)")
                    .font(.headline)
                Text("TASKS")
                    .font(.system(size: 8))
                    .fontWeight(.bold)
            }
        }
    }
}

struct RectangularLockScreenView: View {
    var entry: Provider.Entry
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.nextClassTitle)
                .font(.headline)
                .lineLimit(1)
            Text(entry.nextClassTime)
                .font(.subheadline)
            Text(entry.nextClassLocation)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct SmallView: View {
    var entry: Provider.Entry
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("UP NEXT")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            Spacer()
            if !entry.nextClassTime.isEmpty {
                Text(entry.nextClassTitle).font(.headline).lineLimit(2)
                Text(entry.nextClassTime).font(.subheadline).foregroundColor(.blue)
            } else {
                Text("Free!").font(.title).foregroundColor(.gray)
            }
            Spacer()
        }
        .padding()
    }
}

struct MediumView: View {
    var entry: Provider.Entry
    var body: some View {
        HStack {
            SmallView(entry: entry)
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("TASK").font(.caption).fontWeight(.bold).foregroundColor(.secondary)
                Spacer()
                Text(entry.nextTaskTitle)
                    .font(.headline)
                    .lineLimit(2)
                Text(entry.nextTaskDate)
                    .font(.caption)
                    .foregroundColor(.red)
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Widget Definition

struct UpNextWidget: Widget {
    let kind: String = "ClassllyWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ClassllyWidgetsEntryView(entry: entry)
        }
        .configurationDisplayName("Up Next")
        .description("Your next class and task.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}