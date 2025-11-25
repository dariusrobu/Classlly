import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var pendingNotifications: [UNNotificationRequest] = []
    @EnvironmentObject var themeManager: AppTheme
    
    public init() {}
    
    var body: some View {
        List {
            Section(header: Text("Notification Status")) {
                HStack {
                    Text("Permission Status")
                        .foregroundColor(.themeTextPrimary)
                    Spacer()
                    Text(notificationManager.permissionGranted ? "Granted" : "Denied")
                        .foregroundColor(notificationManager.permissionGranted ? .themeGreen : .themeRed)
                }
                HStack {
                    Text("Pending Notifications")
                        .foregroundColor(.themeTextPrimary)
                    Spacer()
                    Text("\(pendingNotifications.count)")
                        .foregroundColor(.themeBlue)
                }
            }
            .adaptiveListRow() // FIX
            
            Section(header: Text("Manage Notifications")) {
                Button("View All Pending Notifications") { loadPendingNotifications() }
                    .foregroundColor(.themeTextPrimary)
                Button("Remove All Notifications", role: .destructive) { removeAllNotifications() }
            }
            .adaptiveListRow() // FIX
            
            if !pendingNotifications.isEmpty {
                Section(header: Text("Pending Notifications")) {
                    ForEach(pendingNotifications, id: \.identifier) { notification in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(notification.content.title)
                                .foregroundColor(.themeTextPrimary)
                            Text(notification.content.body)
                                .foregroundColor(.themeTextSecondary)
                            if let trigger = notification.trigger as? UNCalendarNotificationTrigger {
                                Text("Scheduled: \(formatTriggerDate(trigger))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .adaptiveListRow() // FIX
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .navigationTitle("Notification Settings")
        .onAppear { loadPendingNotifications() }
    }
    
    private func loadPendingNotifications() {
        notificationManager.getPendingNotifications { requests in
            DispatchQueue.main.async { self.pendingNotifications = requests }
        }
    }
    
    private func removeAllNotifications() {
        notificationManager.removeAllNotifications()
        loadPendingNotifications()
    }
    
    private func formatTriggerDate(_ trigger: UNCalendarNotificationTrigger) -> String {
        if let date = trigger.nextTriggerDate() {
            let formatter = DateFormatter(); formatter.dateStyle = .medium; formatter.timeStyle = .short
            return formatter.string(from: date)
        } else { return "Unknown" }
    }
}
