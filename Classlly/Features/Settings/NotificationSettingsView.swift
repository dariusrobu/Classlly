import SwiftUI
import UserNotifications

// MARK: - MAIN SWITCHER
struct NotificationSettingsView: View {
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .rainbow:
                // Wrapped in AnyView because .preferredColorScheme changes the return type
                AnyView(StandardNotificationSettingsView().preferredColorScheme(.dark))
            case .standard:
                AnyView(StandardNotificationSettingsView())
            }
        }
    }
}

// MARK: - 👔 STANDARD VIEW
struct StandardNotificationSettingsView: View {
    // We observe the singleton instance here
    @ObservedObject private var notificationManager = NotificationManager.shared
    @State private var pendingNotifications: [UNNotificationRequest] = []
    
    var body: some View {
        List {
            Section(header: Text("Status")) {
                HStack {
                    Text("Permission Status")
                    Spacer()
                    Text(notificationManager.permissionGranted ? "Granted" : "Denied")
                        .foregroundColor(notificationManager.permissionGranted ? .green : .red)
                }
                HStack {
                    Text("Pending Notifications")
                    Spacer()
                    Text("\(pendingNotifications.count)")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Actions")) {
                Button("Refresh List") {
                    loadPendingNotifications()
                }
                Button("Remove All Notifications", role: .destructive) {
                    removeAllNotifications()
                }
            }
            
            if !pendingNotifications.isEmpty {
                Section(header: Text("Scheduled")) {
                    ForEach(pendingNotifications, id: \.identifier) { notification in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(notification.content.title)
                                .font(.headline)
                            Text(notification.content.body)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if let trigger = notification.trigger as? UNCalendarNotificationTrigger {
                                Text("Scheduled: \(formatTriggerDate(trigger))")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .onAppear {
            loadPendingNotifications()
        }
    }
    
    private func loadPendingNotifications() {
        // Access shared instance directly
        NotificationManager.shared.getPendingNotifications { requests in
            DispatchQueue.main.async {
                self.pendingNotifications = requests
            }
        }
    }
    
    private func removeAllNotifications() {
        NotificationManager.shared.removeAllNotifications()
        loadPendingNotifications()
    }
    
    private func formatTriggerDate(_ trigger: UNCalendarNotificationTrigger) -> String {
        if let date = trigger.nextTriggerDate() {
            let f = DateFormatter()
            f.dateStyle = .medium
            f.timeStyle = .short
            return f.string(from: date)
        }
        return "Unknown"
    }
}
