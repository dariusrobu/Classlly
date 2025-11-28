import WidgetKit
import SwiftUI
import SwiftData
import Charts

// MARK: - 1. Timeline Entry
struct GradeVelocityEntry: TimelineEntry {
    let date: Date
    let overallAverage: Double
    let gradeHistory: [(date: Date, value: Double)]
    let isUptrend: Bool
}

// MARK: - 2. Provider
struct GradeVelocityProvider: TimelineProvider {
    
    // Helper to fetch data from SwiftData
    @MainActor
    private func fetchStats() -> (average: Double, history: [(Date, Double)], isUptrend: Bool) {
        // Use SharedModelContainer
        let modelContainer = SharedModelContainer.create()
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Subject>()
        
        do {
            let subjects: [Subject] = try context.fetch(descriptor)
            
            // FIX: Force unwrap the optional relationship with '?? []'
            let allGrades: [GradeEntry] = subjects.reduce(into: [GradeEntry]()) { result, subject in
                result.append(contentsOf: subject.gradeHistory ?? [])
            }
            
            if allGrades.isEmpty { return (0.0, [], true) }
            
            // Sort by date
            let sortedGrades = allGrades.sorted { (a: GradeEntry, b: GradeEntry) -> Bool in
                return a.date < b.date
            }
            
            // Map to tuples for the chart
            let historyPoints = sortedGrades.map { ($0.date, $0.grade) }
            
            // Calculate Sum
            let totalSum: Double = sortedGrades.reduce(0.0) { partialResult, entry in
                return partialResult + entry.grade
            }
            let count: Double = Double(sortedGrades.count)
            
            // Calculate Overall Average
            let average: Double = count > 0 ? (totalSum / count) : 0.0
            
            // Determine Trend
            let first = sortedGrades.first?.grade ?? 0
            let last = sortedGrades.last?.grade ?? 0
            let isUptrend = last >= first
            
            return (average, historyPoints, isUptrend)
            
        } catch {
            print("Widget Fetch Failed: \(error)")
            return (0.0, [], true)
        }
    }

    func placeholder(in context: Context) -> GradeVelocityEntry {
        let now = Date()
        let mockHistory = [
            (now.addingTimeInterval(-86400 * 5), 7.0),
            (now.addingTimeInterval(-86400 * 4), 7.5),
            (now.addingTimeInterval(-86400 * 3), 6.8),
            (now.addingTimeInterval(-86400 * 2), 8.2),
            (now.addingTimeInterval(-86400 * 1), 9.0)
        ]
        return GradeVelocityEntry(date: Date(), overallAverage: 8.5, gradeHistory: mockHistory, isUptrend: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (GradeVelocityEntry) -> Void) {
        Task { @MainActor in
            let stats = fetchStats()
            let entry = GradeVelocityEntry(
                date: Date(),
                overallAverage: stats.average,
                gradeHistory: stats.history,
                isUptrend: stats.isUptrend
            )
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GradeVelocityEntry>) -> Void) {
        Task { @MainActor in
            let stats = fetchStats()
            let entry = GradeVelocityEntry(
                date: Date(),
                overallAverage: stats.average,
                gradeHistory: stats.history,
                isUptrend: stats.isUptrend
            )
            
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

// MARK: - 3. Widget View
struct GradeVelocityWidgetEntryView: View {
    var entry: GradeVelocityProvider.Entry
    
    let bgColor = Color(uiColor: .systemGroupedBackground)
    let successColor = Color.green
    let errorColor = Color.red
    
    var lineColor: Color {
        entry.isUptrend ? successColor : errorColor
    }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            HStack(spacing: 20) {
                // LEFT SIDE: Big Average Number
                VStack(alignment: .leading, spacing: 4) {
                    Text("Avg Grade")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    Text(String(format: "%.1f", entry.overallAverage))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.8)
                    
                    HStack(spacing: 4) {
                        Image(systemName: entry.isUptrend ? "arrow.up.right" : "arrow.down.right")
                        Text(entry.isUptrend ? "Trending Up" : "Trending Down")
                    }
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(lineColor)
                }
                .layoutPriority(1)
                
                // RIGHT SIDE: Chart
                if !entry.gradeHistory.isEmpty {
                    Chart {
                        ForEach(entry.gradeHistory, id: \.date) { item in
                            LineMark(
                                x: .value("Date", item.date),
                                y: .value("Grade", item.value)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(lineColor)
                            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                        }
                        
                        ForEach(entry.gradeHistory, id: \.date) { item in
                            AreaMark(
                                x: .value("Date", item.date),
                                y: .value("Grade", item.value)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [lineColor.opacity(0.3), lineColor.opacity(0.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .padding(.vertical, 12)
                    .padding(.trailing, 4)
                } else {
                    VStack {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.largeTitle)
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No Data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - 4. Widget Configuration
struct GradeVelocityWidget: Widget {
    let kind: String = "GradeVelocityWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GradeVelocityProvider()) { entry in
            GradeVelocityWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(uiColor: .systemGroupedBackground)
                }
        }
        .configurationDisplayName("Grade Velocity")
        .description("Track your overall grade trend at a glance.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}
