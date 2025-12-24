import Foundation
import UserNotifications
import SwiftData
import Combine
import UIKit

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    
    // Helper property for UI status checks
    var permissionGranted: Bool {
        permissionStatus == .authorized || permissionStatus == .provisional || permissionStatus == .ephemeral
    }
    
    private init() {
        checkPermission()
        // Phase 1: Initialize Categories
        setupNotificationCategories()
    }
    
    // MARK: - Phase 1: Setup Categories
    func setupNotificationCategories() {
        // 1. ATTENDANCE_CHECK
        let presentAction = UNNotificationAction(identifier: "PRESENT_ACTION", title: "Present", options: [])
        let absentAction = UNNotificationAction(identifier: "ABSENT_ACTION", title: "Absent", options: [.destructive])
        let attendanceCategory = UNNotificationCategory(identifier: "ATTENDANCE_CHECK", actions: [presentAction, absentAction], intentIdentifiers: [], options: .customDismissAction)

        // 2. TASK_REMINDER
        let timerAction = UNNotificationAction(identifier: "START_TIMER_ACTION", title: "Start 25m Timer", options: [])
        let completeAction = UNNotificationAction(identifier: "COMPLETE_TASK_ACTION", title: "Mark Complete", options: [])
        let taskCategory = UNNotificationCategory(identifier: "TASK_REMINDER", actions: [timerAction, completeAction], intentIdentifiers: [], options: .customDismissAction)

        // 3. GRADE_ALERT
        let calcTargetAction = UNNotificationAction(identifier: "CALCULATE_TARGET_ACTION", title: "Calculate Target", options: [.foreground])
        let addGradeAction = UNNotificationAction(identifier: "ADD_GRADE_ACTION", title: "Add Grade", options: [.foreground])
        let gradeCategory = UNNotificationCategory(identifier: "GRADE_ALERT", actions: [calcTargetAction, addGradeAction], intentIdentifiers: [], options: [])

        // 4. MORNING_BRIEFING
        let viewScheduleAction = UNNotificationAction(identifier: "VIEW_SCHEDULE_ACTION", title: "View Schedule", options: [.foreground])
        let quickAddTaskAction = UNNotificationAction(identifier: "QUICK_ADD_TASK_ACTION", title: "Quick Add Task", options: [.foreground])
        let briefingCategory = UNNotificationCategory(identifier: "MORNING_BRIEFING", actions: [viewScheduleAction, quickAddTaskAction], intentIdentifiers: [], options: [])

        UNUserNotificationCenter.current().setNotificationCategories([attendanceCategory, taskCategory, gradeCategory, briefingCategory])
        print("✅ Notification Categories Registered")
    }
    
    // MARK: - Permissions
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
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Phase 2: Scheduling Logic
    
    func scheduleAttendanceCheck(for subject: Subject, at date: Date) {
        // Schedule for 5 minutes after class ends
        let triggerDate = date.addingTimeInterval(5 * 60)
        
        // Don't schedule if it's already more than 30 mins past the trigger
        if triggerDate < Date().addingTimeInterval(-30 * 60) { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Class Finished: \(subject.title)"
        content.body = "Did you attend? Long press to log it."
        content.sound = .default
        content.categoryIdentifier = "ATTENDANCE_CHECK"
        content.userInfo = ["subjectID": subject.id]
        
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        
        let request = UNNotificationRequest(identifier: "attendance-\(subject.id)-\(date.timeIntervalSince1970)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule attendance check: \(error)")
            } else {
                print("🎓 Scheduled attendance check for \(subject.title) at \(triggerDate.formatted(date: .omitted, time: .shortened))")
            }
        }
    }
    
    func scheduleTaskNotification(for task: StudyTask) {
        guard let dueDate = task.dueDate, task.reminderTime != .none else { return }
        guard let triggerDate = task.reminderTime.reminderDate(from: dueDate) else { return }
        if triggerDate < Date() { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder: \(task.title)"
        content.body = "Due: \(dueDate.formatted(date: .abbreviated, time: .shortened))"
        content.sound = .default
        content.categoryIdentifier = "TASK_REMINDER"
        content.userInfo = ["taskID": task.id]
        
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: task.id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in if let e = error { print("❌ Error: \(e)") } }
    }
    
    func removeNotification(for task: StudyTask) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.id])
    }
    
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in completion(requests) }
    }
    
    // MARK: - 🧪 DEBUG SIMULATIONS
    
    func testAllNotifications() {
        // 1. Attendance Check (Interactive)
        scheduleDebugNotification(title: "Class Finished: Math 101", body: "Did you attend? Long press to log it.", timeInterval: 2, categoryIdentifier: "ATTENDANCE_CHECK")
        
        // 2. Task Reminder (Interactive)
        scheduleDebugNotification(title: "Task Reminder: Calculus HW", body: "Due in 1 hour.", timeInterval: 4, categoryIdentifier: "TASK_REMINDER")
        
        // 3. Smart Gap (Standard)
        scheduleDebugNotification(title: "Free Time Detected", body: "You have a 2h gap. Perfect for a quick study session!", timeInterval: 6)
        
        // 4. Streak (Standard)
        scheduleDebugNotification(title: "🔥 5 Day Streak!", body: "You're on fire! Keep attending classes to maintain it.", timeInterval: 8)
        
        // 5. Morning Briefing (Interactive)
        scheduleDebugNotification(title: "Busy Day Ahead", body: "Prepare yourself! You have 6 classes tomorrow.", timeInterval: 10, categoryIdentifier: "MORNING_BRIEFING")
        
        // 6. Grade Alert (Interactive)
        scheduleDebugNotification(title: "Grade Alert 📉", body: "Your Math average dropped below 6.0. Let's boost it!", timeInterval: 12, categoryIdentifier: "GRADE_ALERT")
        
        print("🚀 Scheduled ALL test notifications sequence.")
    }
    
    // Legacy individual testers - Updated to use Categories
    func testClassReminder() { scheduleDebugNotification(title: "Class Finished: Math 101", body: "Did you attend?", timeInterval: 5, categoryIdentifier: "ATTENDANCE_CHECK") }
    
    func testTaskReminder() { scheduleDebugNotification(title: "Task Reminder", body: "Homework Due", timeInterval: 5, categoryIdentifier: "TASK_REMINDER") }
    
    func testSmartGap() { scheduleDebugNotification(title: "Smart Gap", body: "Free time detected", timeInterval: 5) }
    
    func testStreakNotification() { scheduleDebugNotification(title: "Streak", body: "Keep it up!", timeInterval: 5) }
    
    func testHeavyDayNotification() { scheduleDebugNotification(title: "Heavy Load", body: "Busy day tomorrow", timeInterval: 5, categoryIdentifier: "MORNING_BRIEFING") }
    
    func testGradeRescueNotification() { scheduleDebugNotification(title: "Grade Alert", body: "Low grade detected", timeInterval: 5, categoryIdentifier: "GRADE_ALERT") }
    
    // MARK: - 🧠 REAL LOGIC PLACEHOLDERS
    @MainActor func checkForSmartGaps(modelContext: ModelContext) { print("🔍 Checking gaps..."); testSmartGap() }
    @MainActor func scheduleHeavyDayWarning(modelContext: ModelContext) { print("🔍 Checking heavy load..."); testHeavyDayNotification() }
    @MainActor func checkGradeHealth(modelContext: ModelContext) { print("🔍 Checking grades..."); testGradeRescueNotification() }

    // MARK: - PRIVATE HELPERS
    private func scheduleDebugNotification(title: String, body: String, timeInterval: TimeInterval, categoryIdentifier: String? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        if let cat = categoryIdentifier { content.categoryIdentifier = cat }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error { print("❌ Test Notification Failed: \(error)") }
            else { print("✅ Test Notification Scheduled: \(title)") }
        }
    }
}
