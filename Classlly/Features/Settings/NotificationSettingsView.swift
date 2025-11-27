import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var pendingNotifications: [UNNotificationRequest] = []
    @Environment(\.colorScheme) var colorScheme
    
    public init() {}
    
    var body: some View {
        List {
            Section(header: Text("Notification Status").foregroundColor(.secondary)) {
                HStack {
                    Text("Permission Status")
                    Spacer()
                    Text(notificationManager.permissionGranted ? "Granted" : "Denied")
                        .foregroundColor(notificationManager.permissionGranted ? .themeSuccess : .themeError)
                }
                HStack {
                    Text("Pending Notifications")
                    Spacer()
                    Text("\(pendingNotifications.count)")
                        .foregroundColor(.themePrimary)
                }
            }
            .listRowBackground(Color.themeSurface)
            
            Section(header: Text("Manage Notifications").foregroundColor(.secondary)) {
                Button("View All Pending Notifications") { loadPendingNotifications() }
                Button("Remove All Notifications", role: .destructive) { removeAllNotifications() }
            }
            .listRowBackground(Color.themeSurface)
            
            if !pendingNotifications.isEmpty {
                Section(header: Text("Pending Notifications").foregroundColor(.secondary)) {
                    ForEach(pendingNotifications, id: \.identifier) { notification in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(notification.content.title)
                            Text(notification.content.body)
                            if let trigger = notification.trigger as? UNCalendarNotificationTrigger {
                                Text("Scheduled: \(formatTriggerDate(trigger))")
                            }
                        }
                        .font(.caption)
                    }
                }
                .listRowBackground(Color.themeSurface)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.themeBackground)
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
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else {
            return "Unknown"
        }
    }
}
