//
//  NotificationSettingsView.swift
//  Classlly
//
//  Created by Robu Darius on 24.11.2025.
//


import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var pendingNotifications: [UNNotificationRequest] = []
    @Environment(\.colorScheme) var colorScheme
    
    public init() {}
    
    var body: some View {
        List {
            Section(header: Text("Notification Status").foregroundColor(.themeTextSecondary)) {
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
            
            Section(header: Text("Manage Notifications").foregroundColor(.themeTextSecondary)) {
                Button("Refresh Status") {
                    loadPendingNotifications()
                }
                
                Button("Remove All Notifications", role: .destructive) {
                    removeAllNotifications()
                }
            }
            .listRowBackground(Color.themeSurface)
            
            if !pendingNotifications.isEmpty {
                Section(header: Text("Pending Queue").foregroundColor(.themeTextSecondary)) {
                    ForEach(pendingNotifications, id: \.identifier) { notification in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(notification.content.title)
                                .font(.headline)
                                .foregroundColor(.themeTextPrimary)
                            
                            Text(notification.content.body)
                                .font(.subheadline)
                                .foregroundColor(.themeTextSecondary)
                            
                            if let trigger = notification.trigger as? UNCalendarNotificationTrigger {
                                Text("Scheduled: \(formatTriggerDate(trigger))")
                                    .font(.caption)
                                    .foregroundColor(.themePrimary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listRowBackground(Color.themeSurface)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.themeBackground)
        .navigationTitle("Notification Settings")
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
        // Reload after a short delay to ensure system updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            loadPendingNotifications()
        }
    }
    
    private func formatTriggerDate(_ trigger: UNCalendarNotificationTrigger) -> String {
        if let date = trigger.nextTriggerDate() {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else {
            return "Unknown time"
        }
    }
}