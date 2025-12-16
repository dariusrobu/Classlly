import SwiftUI
import UserNotifications

// MARK: - MAIN SWITCHER
struct NotificationSettingsView: View {
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .arcade:
                ArcadeNotificationSettingsView()
            case .rainbow:
                StandardNotificationSettingsView().preferredColorScheme(.dark)
            case .none:
                StandardNotificationSettingsView()
            }
        }
    }
}

// MARK: - 👔 STANDARD VIEW
struct StandardNotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
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
        notificationManager.getPendingNotifications { requests in
            DispatchQueue.main.async {
                self.pendingNotifications = requests
            }
        }
    }
    
    private func removeAllNotifications() {
        notificationManager.removeAllNotifications()
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

// MARK: - 🕹️ ARCADE VIEW
struct ArcadeNotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var pendingNotifications: [UNNotificationRequest] = []
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    HStack {
                        Text("SYSTEM ALERTS")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.black)
                            .foregroundColor(.cyan)
                        Spacer()
                        Text(notificationManager.permissionGranted ? "ONLINE" : "OFFLINE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(6)
                            .background(notificationManager.permissionGranted ? Color.green : Color.red)
                            .foregroundColor(.black)
                            .cornerRadius(8)
                    }
                    .padding()
                    
                    HStack(spacing: 12) {
                        Button(action: loadPendingNotifications) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("SCAN")
                            }
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue, lineWidth: 1))
                        }
                        
                        Button(action: removeAllNotifications) {
                            HStack {
                                Image(systemName: "trash")
                                Text("PURGE")
                            }
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("ACTIVE SIGNALS (\(pendingNotifications.count))")
                            .font(.caption)
                            .fontWeight(.black)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        if pendingNotifications.isEmpty {
                            Text("NO ACTIVE ALERTS")
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding(40)
                                .background(Color(white: 0.1))
                                .cornerRadius(16)
                                .padding(.horizontal)
                        } else {
                            ForEach(pendingNotifications, id: \.identifier) { notification in
                                HStack(alignment: .top, spacing: 16) {
                                    Image(systemName: "bell.badge.fill")
                                        .font(.title2)
                                        .foregroundColor(.yellow)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(notification.content.title)
                                            .font(.system(.headline, design: .rounded))
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        Text(notification.content.body)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        
                                        if let trigger = notification.trigger as? UNCalendarNotificationTrigger {
                                            Text("T-MINUS: \(formatTriggerDate(trigger))")
                                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                .foregroundColor(.cyan)
                                                .padding(.top, 4)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Color(white: 0.1))
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadPendingNotifications()
        }
    }
    
    private func loadPendingNotifications() {
        notificationManager.getPendingNotifications { requests in
            DispatchQueue.main.async {
                self.pendingNotifications = requests
            }
        }
    }
    
    private func removeAllNotifications() {
        notificationManager.removeAllNotifications()
        loadPendingNotifications()
    }
    
    private func formatTriggerDate(_ trigger: UNCalendarNotificationTrigger) -> String {
        if let date = trigger.nextTriggerDate() {
            let f = DateFormatter()
            f.dateFormat = "MM/dd HH:mm"
            return f.string(from: date)
        }
        return "UNKNOWN"
    }
}
