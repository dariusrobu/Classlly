import Foundation
import UserNotifications
import SwiftData

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    
    private init() {
        checkPermission()
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.checkPermission()
                if granted {
                    print("✅ Notification Permission Granted")
                } else if let error = error {
                    print("❌ Notification Permission Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.permissionStatus = settings.authorizationStatus
            }
        }
    }
    
    func scheduleTaskNotification(for task: StudyTask) {
        // ✅ FIX: Ensure reminderTime exists and isn't .none
        guard let dueDate = task.dueDate, task.reminderTime != .none else { return }
        
        // Calculate Trigger Date
        guard let triggerDate = task.reminderTime.reminderDate(from: dueDate) else { return }
        
        // Don't schedule if date is in the past
        if triggerDate < Date() { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder: \(task.title)"
        content.body = "Due: \(dueDate.formatted(date: .abbreviated, time: .shortened))"
        content.sound = .default
        
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        
        // ✅ FIX: task.id is already a String, do not use .uuidString
        let request = UNNotificationRequest(identifier: task.id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error)")
            } else {
                print("🔔 Scheduled notification for \(task.title) at \(triggerDate)")
            }
        }
    }
    
    func removeNotification(for task: StudyTask) {
        // ✅ FIX: task.id is String
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.id])
    }
}
