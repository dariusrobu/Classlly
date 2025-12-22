import Foundation
import UserNotifications
import SwiftData
import Combine

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    
    // Helper property for UI status checks
    var permissionGranted: Bool {
        permissionStatus == .authorized
    }
    
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
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.id])
    }
    
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            completion(requests)
        }
    }
    
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - 🧪 DEBUG SIMULATIONS
    
    func testClassReminder() {
        scheduleDebugNotification(title: "Upcoming Class: Math 101", body: "Starts in 15 minutes in Room 304.", timeInterval: 5)
    }
    
    func testTaskReminder() {
        scheduleDebugNotification(title: "Task Due Soon", body: "Calculus Homework is due in 1 hour.", timeInterval: 5)
    }
    
    func testSmartGap() {
        scheduleDebugNotification(title: "Free Time Detected", body: "You have a 2h gap. Perfect for a quick study session!", timeInterval: 5)
    }
    
    func testStreakNotification() {
        scheduleDebugNotification(title: "🔥 5 Day Streak!", body: "You're on fire! Keep attending classes to maintain it.", timeInterval: 5)
    }
    
    func testHeavyDayNotification() {
        scheduleDebugNotification(title: "Busy Day Ahead", body: "Prepare yourself! You have 6 classes tomorrow.", timeInterval: 5)
    }
    
    func testGradeRescueNotification() {
        scheduleDebugNotification(title: "Grade Alert 📉", body: "Your Math average dropped below 6.0. Let's boost it!", timeInterval: 5)
    }
    
    // MARK: - 🧠 REAL LOGIC PLACEHOLDERS
    
    @MainActor
    func checkForSmartGaps(modelContext: ModelContext) {
        // Logic to check gaps would go here.
        // For debug, we just print or trigger a notification if a gap is found in data.
        print("🔍 Checking for smart gaps...")
        // If successful logic finds gap:
        testSmartGap()
    }
    
    @MainActor
    func scheduleHeavyDayWarning(modelContext: ModelContext) {
        // Logic to count tomorrow's classes
        print("🔍 Checking heavy load for tomorrow...")
        testHeavyDayNotification()
    }
    
    @MainActor
    func checkGradeHealth(modelContext: ModelContext) {
        // Logic to scan grades < threshold
        print("🔍 Checking grade health...")
        testGradeRescueNotification()
    }
    
    // MARK: - PRIVATE HELPERS
    
    private func scheduleDebugNotification(title: String, body: String, timeInterval: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Test Notification Failed: \(error)")
            } else {
                print("✅ Test Notification Scheduled: \(title) in \(timeInterval)s")
            }
        }
    }
}
