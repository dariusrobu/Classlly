import SwiftUI
import SwiftData

struct NotificationDebugView: View {
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        List {
            // MARK: - Setup
            Section(header: Text("Data Setup")) {
                Button(action: {
                     DemoDataManager.shared.createPerfectGapScenario(modelContext: modelContext)
                }) {
                    Label("Inject Perfect Gap Data", systemImage: "flask.fill")
                        .foregroundColor(.purple)
                }
            }
            
            // MARK: - Attendance Simulations
            Section(header: Text("Attendance Alerts (5s Delay)")) {
                
                Button(action: { NotificationManager.shared.testClassReminder() }) {
                    TestRow(icon: "bell.fill", color: .blue, title: "Class Finished", sub: "Time-based trigger")
                }
                
                Button(action: { NotificationManager.shared.testGeofenceEntryNotification() }) {
                    TestRow(icon: "location.fill", color: .green, title: "Geofence Entry", sub: "Arrived at class")
                }
                
                Button(action: { NotificationManager.shared.testGeofenceMissingAlert() }) {
                    TestRow(icon: "location.slash.fill", color: .red, title: "Geofence Miss", sub: "Absent detection")
                }
            }
            
            // MARK: - Task & Study Simulations
            Section(header: Text("Study Alerts")) {
                Button(action: { NotificationManager.shared.testTaskReminder() }) {
                    TestRow(icon: "checkmark.circle.fill", color: .orange, title: "Task Reminder", sub: "Due date alert")
                }
                
                Button(action: { NotificationManager.shared.testSmartGap() }) {
                    TestRow(icon: "clock.arrow.circlepath", color: .indigo, title: "Smart Gap", sub: "Free time suggestion")
                }
            }
            
            // MARK: - Insights Simulations
            Section(header: Text("Insights & Briefings")) {
                Button(action: { NotificationManager.shared.testStreakNotification() }) {
                    TestRow(icon: "flame.fill", color: .orange, title: "Streak Reward", sub: "Engagement Alert")
                }
                
                Button(action: { NotificationManager.shared.testHeavyDayNotification() }) {
                    TestRow(icon: "bed.double.fill", color: .purple, title: "Heavy Day", sub: "Morning Briefing")
                }
                
                Button(action: { NotificationManager.shared.testGradeRescueNotification() }) {
                    TestRow(icon: "chart.line.downtrend.xyaxis", color: .pink, title: "Grade Rescue", sub: "Low average alert")
                }
            }
            
            // MARK: - Real Logic Analysis
            Section(header: Text("Real Logic Analysis")) {
                Button(action: {
                    NotificationManager.shared.checkForSmartGaps(modelContext: modelContext)
                }) {
                    Label("Analyze Gaps", systemImage: "bolt.badge.clock.fill")
                        .foregroundColor(.yellow)
                }
                
                Button(action: {
                    NotificationManager.shared.scheduleHeavyDayWarning(modelContext: modelContext)
                }) {
                    Label("Check Heavy Load", systemImage: "calendar.badge.exclamationmark")
                        .foregroundColor(.red)
                }
                
                Button(action: {
                    NotificationManager.shared.checkGradeHealth(modelContext: modelContext)
                }) {
                    Label("Check Grade Health", systemImage: "cross.case.fill")
                        .foregroundColor(.pink)
                }
            }
            
            Section(footer: Text("Tap a simulation, then LOCK your screen immediately to see the notification appearance.")) {
                EmptyView()
            }
        }
        .navigationTitle("Notification Lab")
    }
}

// MARK: - Helper View
struct TestRow: View {
    let icon: String
    let color: Color
    let title: String
    let sub: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            VStack(alignment: .leading) {
                Text(title)
                    .foregroundColor(.primary)
                Text(sub)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("5s")
                .font(.caption)
                .padding(4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)
        }
    }
}
