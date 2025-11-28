//
//  NextTaskEntry.swift
//  Classlly
//
//  Created by Robu Darius on 28.11.2025.
//


import WidgetKit
import SwiftUI
import SwiftData

// MARK: - 1. Timeline Entry
struct NextTaskEntry: TimelineEntry {
    let date: Date
    let task: StudyTask?
    
    // Calculated Properties for the View
    var timeRemaining: TimeInterval {
        guard let dueDate = task?.dueDate else { return 0 }
        return dueDate.timeIntervalSince(date)
    }
    
    var ringColor: Color {
        let hoursLeft = timeRemaining / 3600
        if hoursLeft < 2 {
            return .themeError // Red (< 2h)
        } else if hoursLeft < 24 {
            return .themeWarning // Orange (< 24h)
        } else {
            return .themePrimary // Blue (> 24h)
        }
    }
    
    var progress: Double {
        // Since StudyTask lacks a 'creationDate', we simulate progress based on urgency windows.
        // If > 24h, we show a full or static ring.
        // If < 24h, we count down the last 24 hours (Linear fill from 0 to 1 as it gets closer? Or emptying?)
        // Let's implement: "Fill represents urgency".
        // 24h+ left: 25% filled (Low urgency)
        // 24h-2h left: Scales from 25% to 75%
        // <2h left: Scales from 75% to 100%
        
        let hoursLeft = timeRemaining / 3600
        
        if hoursLeft > 24 {
            return 0.2 // Base fill
        } else if hoursLeft <= 0 {
            return 1.0 // Overdue/Due
        } else {
            // Map 24h...0h to 0.2...1.0
            // Formula: 1.0 - (hoursLeft / 30) roughly, but let's be precise:
            // Let's simply fill the ring as we get closer to 0.
            return 1.0 - (hoursLeft / 24.0)
        }
    }
}

// MARK: - 2. Provider
struct NextTaskProvider: TimelineProvider {
    
    @MainActor
    func getNextTask() -> StudyTask? {
        // IMPORTANT: Use the shared ModelContainer so Widget sees App data
        // If you haven't set up App Groups yet, this will be empty.
        // Replace 'SharedModelContainer' with standard 'ModelContainer' if strictly local.
        let modelContainer = try? ModelContainer(for: StudyTask.self, Subject.self)
        let context = modelContainer?.mainContext
        
        // Predicate: Not completed, has a due date
        let now = Date()
        let descriptor = FetchDescriptor<StudyTask>(
            predicate: #Predicate<StudyTask> { !$0.isCompleted && $0.dueDate != nil },
            sortBy: [SortDescriptor(\.dueDate, order: .forward)]
        )
        
        do {
            let tasks = try context?.fetch(descriptor)
            // Filter in memory to be safe about "future" tasks or just take the very first one
            // We take the first one even if it's overdue (high urgency)
            return tasks?.first
        } catch {
            print("Widget Fetch Error: \(error)")
            return nil
        }
    }

    func placeholder(in context: Context) -> NextTaskEntry {
        // Mock data
        let mockTask = StudyTask(title: "History Essay", dueDate: Date().addingTimeInterval(3600 * 3), priority: .high)
        return NextTaskEntry(date: Date(), task: mockTask)
    }

    func getSnapshot(in context: Context, completion: @escaping (NextTaskEntry) -> Void) {
        Task { @MainActor in
            let task = getNextTask()
            let entry = NextTaskEntry(date: Date(), task: task)
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextTaskEntry>) -> Void) {
        Task { @MainActor in
            let task = getNextTask()
            let currentDate = Date()
            
            // Generate the immediate entry
            let entry = NextTaskEntry(date: currentDate, task: task)
            
            // Logic to refresh:
            // 1. If no task, check back in 1 hour.
            // 2. If task exists, we want to refresh when colors change (24h mark, 2h mark).
            
            var refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)! // Default 15 min refresh
            
            if let dueDate = task?.dueDate {
                let timeUntilDue = dueDate.timeIntervalSince(currentDate)
                let timeUntil24h = timeUntilDue - (24 * 3600)
                let timeUntil2h = timeUntilDue - (2 * 3600)
                
                // If we are approaching a color threshold, schedule update exactly then
                if timeUntil24h > 0 {
                    refreshDate = currentDate.addingTimeInterval(timeUntil24h)
                } else if timeUntil2h > 0 {
                    refreshDate = currentDate.addingTimeInterval(timeUntil2h)
                }
            }
            
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
    }
}

// MARK: - 3. Widget View
struct NextTaskWidgetView: View {
    var entry: NextTaskProvider.Entry
    
    var body: some View {
        ZStack {
            // Deep Dark Background
            Color.themeBackground.ignoresSafeArea()
            
            if let task = entry.task, let dueDate = task.dueDate {
                VStack(spacing: 8) {
                    // CENTER: Progress Ring
                    ZStack {
                        // Background Track
                        Circle()
                            .stroke(Color.themeSurface.opacity(0.3), lineWidth: 8)
                        
                        // Progress Fill
                        Circle()
                            .trim(from: 0, to: entry.progress)
                            .stroke(
                                entry.ringColor,
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            // Neon Glow Effect
                            .shadow(color: entry.ringColor.opacity(0.6), radius: 8, x: 0, y: 0)
                        
                        // Center Text: Time Remaining
                        VStack(spacing: 0) {
                            Text(dueDate, style: .relative)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            Text("left")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
                    
                    // BOTTOM: Task Title
                    Text(task.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.themeTextPrimary)
                        .lineLimit(1)
                        .padding(.horizontal, 4)
                }
                .padding()
            } else {
                // Empty State
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.themeSuccess)
                    Text("All Caught Up!")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.themeTextSecondary)
                }
            }
        }
        .containerBackground(for: .widget) {
            Color.themeBackground
        }
    }
}

// MARK: - 4. Widget Configuration
struct NextTaskWidget: Widget {
    let kind: String = "NextTaskWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextTaskProvider()) { entry in
            NextTaskWidgetView(entry: entry)
        }
        .configurationDisplayName("Up Next")
        .description("Keep track of your most urgent task.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    NextTaskWidget()
} timeline: {
    // 1. Far away task (Blue)
    NextTaskEntry(date: Date(), task: StudyTask(title: "Thesis Draft", dueDate: Date().addingTimeInterval(86400 * 2), priority: .medium))
    
    // 2. Urgent task (Orange)
    NextTaskEntry(date: Date(), task: StudyTask(title: "Math Homework", dueDate: Date().addingTimeInterval(3600 * 5), priority: .high))
    
    // 3. Critical task (Red)
    NextTaskEntry(date: Date(), task: StudyTask(title: "Physics Exam", dueDate: Date().addingTimeInterval(3600 * 1), priority: .high))
}