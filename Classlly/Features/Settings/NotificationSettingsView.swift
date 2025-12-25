import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        Group {
            if themeManager.selectedGameMode == .rainbow {
                UsefulNotificationSettingsView().preferredColorScheme(.dark)
            } else {
                UsefulNotificationSettingsView()
            }
        }
    }
}

struct UsefulNotificationSettingsView: View {
    @ObservedObject private var notificationManager = NotificationManager.shared
    @Environment(\.scenePhase) var scenePhase
    
    @AppStorage("notifyClasses") private var notifyClasses = true
    @AppStorage("notifyTasks") private var notifyTasks = true
    @AppStorage("classReminderOffset") private var classReminderOffset = 15
    
    var body: some View {
        Form {
            Section("System Status") {
                HStack {
                    statusIconView
                    VStack(alignment: .leading) {
                        Text(statusTitle).font(.headline)
                        if !notificationManager.permissionGranted {
                            Text(statusSubtitle).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    permissionButton
                }
            }
            
            if notificationManager.permissionGranted {
                Section("Alert Preferences") {
                    Toggle("Class Reminders", systemImage: "graduationcap.fill", isOn: $notifyClasses)
                    if notifyClasses {
                        Picker("Alert Me Before", selection: $classReminderOffset) {
                            Text("5 Minutes").tag(5)
                            Text("15 Minutes").tag(15)
                            Text("1 Hour").tag(60)
                        }
                    }
                    Toggle("Task Deadlines", systemImage: "checklist", isOn: $notifyTasks)
                }
                
                Section("Troubleshooting") {
                    Button(action: { notificationManager.testClassReminder() }) {
                        Label("Send Test Notification", systemImage: "paperplane.fill")
                    }
                    Button(role: .destructive, action: { notificationManager.removeAllNotifications() }) {
                        Label("Clear All Pending", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .onAppear { notificationManager.checkPermission() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { notificationManager.checkPermission() }
        }
    }
    
    @ViewBuilder
    private var statusIconView: some View {
        Circle().fill(statusColor.opacity(0.2))
            .frame(width: 40, height: 40)
            .overlay(Image(systemName: statusIcon).foregroundStyle(statusColor))
    }

    @ViewBuilder
    private var permissionButton: some View {
        if notificationManager.permissionStatus == .notDetermined {
            Button("Enable") { notificationManager.requestPermission() }.buttonStyle(.borderedProminent)
        } else {
            Button("Settings") { notificationManager.openSettings() }.buttonStyle(.bordered)
        }
    }

    private var statusColor: Color {
        notificationManager.permissionGranted ? .green : (notificationManager.permissionStatus == .denied ? .red : .orange)
    }
    private var statusIcon: String { notificationManager.permissionGranted ? "bell.badge.fill" : "bell.slash.fill" }
    private var statusTitle: String { notificationManager.permissionGranted ? "Enabled" : "Disabled" }
    private var statusSubtitle: String { notificationManager.permissionStatus == .denied ? "Permission denied. Update in Settings." : "Enable to receive alerts." }
}
