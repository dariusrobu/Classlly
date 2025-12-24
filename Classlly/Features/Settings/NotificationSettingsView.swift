import SwiftUI
import UserNotifications

// MARK: - MAIN SWITCHER
struct NotificationSettingsView: View {
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .rainbow:
                // Force dark mode for Rainbow theme consistency
                AnyView(UsefulNotificationSettingsView().preferredColorScheme(.dark))
            case .standard:
                AnyView(UsefulNotificationSettingsView())
            }
        }
    }
}

// MARK: - 🔔 USEFUL SETTINGS VIEW
struct UsefulNotificationSettingsView: View {
    @ObservedObject private var notificationManager = NotificationManager.shared
    @Environment(\.scenePhase) var scenePhase
    
    // Persistent User Preferences
    @AppStorage("notifyClasses") private var notifyClasses = true
    @AppStorage("notifyTasks") private var notifyTasks = true
    @AppStorage("notifySmartTips") private var notifySmartTips = true
    @AppStorage("classReminderOffset") private var classReminderOffset = 15 // minutes
    
    var body: some View {
        Form {
            // 1. System Permission Status
            Section {
                HStack {
                    ZStack {
                        // Dynamic Color based on status
                        Circle().fill(statusColor.opacity(0.2))
                            .frame(width: 40, height: 40)
                        Image(systemName: statusIcon)
                            .foregroundStyle(statusColor)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(statusTitle)
                            .font(.headline)
                        if notificationManager.permissionStatus != .authorized {
                            Text(statusSubtitle)
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // 🚨 SMART BUTTON LOGIC
                    if notificationManager.permissionStatus == .notDetermined {
                        Button("Enable") {
                            notificationManager.requestPermission()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    } else if notificationManager.permissionStatus == .denied {
                        Button("Settings") {
                            notificationManager.openSettings()
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    } else {
                        Button("Manage") {
                            notificationManager.openSettings()
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                        .tint(.gray)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("System Status")
            }
            
            // 2. Reminder Preferences (Only show if authorized)
            if notificationManager.permissionGranted {
                Section {
                    Toggle(isOn: $notifyClasses) {
                        Label("Class Reminders", systemImage: "graduationcap.fill")
                    }
                    .tint(.purple)
                    
                    if notifyClasses {
                        Picker("Alert Me Before", selection: $classReminderOffset) {
                            Text("5 Minutes").tag(5)
                            Text("10 Minutes").tag(10)
                            Text("15 Minutes").tag(15)
                            Text("30 Minutes").tag(30)
                            Text("1 Hour").tag(60)
                        }
                    }
                    
                    Toggle(isOn: $notifyTasks) {
                        Label("Task Deadlines", systemImage: "checklist")
                    }
                    .tint(.blue)
                    
                } header: {
                    Text("Alert Preferences")
                } footer: {
                    Text("Customize when you receive alerts for your academic schedule.")
                }
                
                // 3. Smart Features
                Section {
                    Toggle(isOn: $notifySmartTips) {
                        Label("Smart Insights", systemImage: "sparkles")
                    }
                    .tint(.orange)
                } header: {
                    Text("Intelligence")
                } footer: {
                    Text("Receive alerts for study gaps, grade drops, and heavy workload days.")
                }
                
                // 4. Troubleshooting
                Section {
                    Button {
                        notificationManager.testClassReminder()
                    } label: {
                        Label("Send Test Notification", systemImage: "paperplane.fill")
                    }
                    
                    Button(role: .destructive) {
                        notificationManager.removeAllNotifications()
                    } label: {
                        Label("Clear All Pending", systemImage: "trash")
                    }
                } header: {
                    Text("Troubleshooting")
                }
            } else {
                Section {
                    ContentUnavailableView(
                        "Notifications Disabled",
                        systemImage: "bell.slash",
                        description: Text("Please enable notifications above to access reminders and smart alerts.")
                    )
                }
            }
        }
        .navigationTitle("Notifications")
        .onAppear {
            notificationManager.checkPermission()
        }
        // Re-check permission when coming back from Settings app
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                notificationManager.checkPermission()
            }
        }
    }
    
    // Helper Properties for UI State
    private var statusColor: Color {
        switch notificationManager.permissionStatus {
        case .authorized, .provisional, .ephemeral: return .green
        case .denied: return .red
        case .notDetermined: return .orange
        @unknown default: return .gray
        }
    }
    
    private var statusIcon: String {
        switch notificationManager.permissionStatus {
        case .authorized, .provisional, .ephemeral: return "bell.badge.fill"
        case .denied: return "bell.slash.fill"
        case .notDetermined: return "bell.fill"
        @unknown default: return "questionmark.circle"
        }
    }
    
    private var statusTitle: String {
        switch notificationManager.permissionStatus {
        case .authorized, .provisional, .ephemeral: return "Enabled"
        case .denied: return "Disabled"
        case .notDetermined: return "Not Setup"
        @unknown default: return "Unknown"
        }
    }
    
    private var statusSubtitle: String {
        switch notificationManager.permissionStatus {
        case .denied: return "You denied permission. Tap Settings to allow."
        case .notDetermined: return "Tap Enable to start receiving alerts."
        default: return ""
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
            .environmentObject(AppTheme.shared)
    }
}
