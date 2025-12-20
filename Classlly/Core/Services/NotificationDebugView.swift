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
            
            // MARK: - Simulations
            Section(header: Text("Simulations (Trigger in 5s)")) {
                
                Button(action: { NotificationManager.shared.testClassReminder() }) {
                    TestRow(icon: "bell.fill", color: .blue, title: "Class Reminder", sub: "Standard Alert")
                }
                
                Button(action: { NotificationManager.shared.testTaskReminder() }) {
                    TestRow(icon: "checkmark.circle.fill", color: .green, title: "Task Reminder", sub: "Action: Mark Done")
                }
                
                Button(action: { NotificationManager.shared.testSmartGap() }) {
                    TestRow(icon: "clock.arrow.circlepath", color: .orange, title: "Smart Gap", sub: "Action: Start Focus")
                }
                
                Button(action: { NotificationManager.shared.testStreakNotification() }) {
                    TestRow(icon: "flame.fill", color: .red, title: "Streak Reward", sub: "Engagement Alert")
                }
                
                Button(action: { NotificationManager.shared.testHeavyDayNotification() }) {
                    TestRow(icon: "bed.double.fill", color: .indigo, title: "Heavy Day Warning", sub: "Info: 6 Classes Tomorrow")
                }
                
                // ✅ NEW BUTTON: Grade Rescue
                Button(action: { NotificationManager.shared.testGradeRescueNotification() }) {
                    TestRow(icon: "chart.line.downtrend.xyaxis", color: .pink, title: "Grade Rescue", sub: "Alert: Low Average")
                }
            }
            
            // MARK: - Real Logic
            Section(header: Text("Real Logic Analysis")) {
                Button(action: {
                    NotificationManager.shared.checkForSmartGaps(modelContext: modelContext)
                }) {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Analyze Gaps")
                                .fontWeight(.medium)
                            Text("Checks today's gaps > 2h")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "bolt.badge.clock.fill")
                            .foregroundColor(.yellow)
                    }
                }
                
                Button(action: {
                    NotificationManager.shared.scheduleHeavyDayWarning(modelContext: modelContext)
                }) {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Check Heavy Load")
                                .fontWeight(.medium)
                            Text("Checks tomorrow's class count")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .foregroundColor(.red)
                    }
                }
                
                // ✅ NEW BUTTON: Check Grade Health
                Button(action: {
                    NotificationManager.shared.checkGradeHealth(modelContext: modelContext)
                }) {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Check Grade Health")
                                .fontWeight(.medium)
                            Text("Scans for subjects < 5.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "cross.case.fill")
                            .foregroundColor(.pink)
                    }
                }
            }
            
            Section(footer: Text("Tap a simulation, then LOCK your screen immediately to see the notification appearance.")) {
                EmptyView()
            }
        }
        .navigationTitle("Notification Lab")
    }
}

// Helper View for Rows (Preserved)
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
