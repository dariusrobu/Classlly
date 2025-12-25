import Foundation
import UserNotifications
import SwiftData
import Combine
import UIKit
import CoreLocation

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    
    var permissionGranted: Bool {
        permissionStatus == .authorized || permissionStatus == .provisional || permissionStatus == .ephemeral
    }
    
    private init() {
        checkPermission()
        setupNotificationCategories()
    }
    
    func setupNotificationCategories() {
        // 1. Attendance Actions
        let presentAction = UNNotificationAction(identifier: "PRESENT_ACTION", title: "Present", options: [])
        let absentAction = UNNotificationAction(identifier: "ABSENT_ACTION", title: "Absent", options: [.destructive])
        let attendanceCategory = UNNotificationCategory(identifier: "ATTENDANCE_CHECK", actions: [presentAction, absentAction], intentIdentifiers: [], options: .customDismissAction)

        // 2. Task Actions
        let timerAction = UNNotificationAction(identifier: "START_TIMER_ACTION", title: "Start 25m Timer", options: [])
        let completeAction = UNNotificationAction(identifier: "COMPLETE_TASK_ACTION", title: "Mark Complete", options: [])
        let taskCategory = UNNotificationCategory(identifier: "TASK_REMINDER", actions: [timerAction, completeAction], intentIdentifiers: [], options: .customDismissAction)

        // 3. Grade Actions
        let calcTargetAction = UNNotificationAction(identifier: "CALCULATE_TARGET_ACTION", title: "Calculate Target", options: [.foreground])
        let addGradeAction = UNNotificationAction(identifier: "ADD_GRADE_ACTION", title: "Add Grade", options: [.foreground])
        let gradeCategory = UNNotificationCategory(identifier: "GRADE_ALERT", actions: [calcTargetAction, addGradeAction], intentIdentifiers: [], options: [])

        // 4. Briefing Actions
        let viewScheduleAction = UNNotificationAction(identifier: "VIEW_SCHEDULE_ACTION", title: "View Schedule", options: [.foreground])
        let quickAddTaskAction = UNNotificationAction(identifier: "QUICK_ADD_TASK_ACTION", title: "Quick Add Task", options: [.foreground])
        let briefingCategory = UNNotificationCategory(identifier: "MORNING_BRIEFING", actions: [viewScheduleAction, quickAddTaskAction], intentIdentifiers: [], options: [])

        UNUserNotificationCenter.current().setNotificationCategories([attendanceCategory, taskCategory, gradeCategory, briefingCategory])
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async { self.checkPermission() }
        }
    }
    
    func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { self.permissionStatus = settings.authorizationStatus }
        }
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Smart Attendance (Location-Based)
    
    func scheduleLocationBasedAttendanceCheck(for subject: Subject) {
        guard let lat = subject.latitude, let lon = subject.longitude else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Class Started: \(subject.title)"
        content.body = "We noticed you're in the classroom. Pre-mark as Present?"
        content.sound = .default
        content.categoryIdentifier = "ATTENDANCE_CHECK"
        content.userInfo = ["subjectID": subject.id, "trigger": "geofence_entry"]

        let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let region = CLCircularRegion(center: center, radius: subject.geofenceRadius, identifier: "region-\(subject.id)")
        region.notifyOnEntry = true
        region.notifyOnExit = false
        
        let trigger = UNLocationNotificationTrigger(region: region, repeats: true)
        let request = UNNotificationRequest(identifier: "geo-attendance-\(subject.id)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleAttendanceCheck(for subject: Subject, at date: Date) {
        let triggerDate = date.addingTimeInterval(5 * 60)
        if triggerDate < Date().addingTimeInterval(-30 * 60) { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Class Finished: \(subject.title)"
        content.body = "Did you attend? Long press to log it."
        content.sound = .default
        content.categoryIdentifier = "ATTENDANCE_CHECK"
        content.userInfo = ["subjectID": subject.id]
        
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: "attendance-\(subject.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleTaskNotification(for task: StudyTask) {
        guard let dueDate = task.dueDate, let triggerDate = task.reminderTime.reminderDate(from: dueDate) else { return }
        if triggerDate < Date() { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder: \(task.title)"
        content.body = "Due soon!"
        content.categoryIdentifier = "TASK_REMINDER"
        content.userInfo = ["taskID": task.id]
        
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: task.id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - 🧪 DEBUG SIMULATIONS
    
    // 1. Attendance
    func testClassReminder() {
        scheduleDebugNotification(
            title: "Class Finished: Math 101",
            body: "Did you attend? (Simulated)",
            timeInterval: 5,
            categoryIdentifier: "ATTENDANCE_CHECK",
            userInfo: ["subjectID": "TEST_SUBJECT_ID"]
        )
    }
    
    // ✅ NEW: Geofence Entry
    func testGeofenceEntryNotification() {
        scheduleDebugNotification(
            title: "Class Started: History",
            body: "You arrived at the classroom. Pre-mark present?",
            timeInterval: 5,
            categoryIdentifier: "ATTENDANCE_CHECK",
            userInfo: ["subjectID": "TEST_SUBJECT_ID", "trigger": "geofence_entry"]
        )
    }
    
    // ✅ NEW: Geofence Miss
    func testGeofenceMissingAlert() {
        scheduleDebugNotification(
            title: "Missing Class?",
            body: "We noticed you weren't in the classroom for Physics. Mark as Absent?",
            timeInterval: 5,
            categoryIdentifier: "ATTENDANCE_CHECK",
            userInfo: ["subjectID": "TEST_SUBJECT_ID", "trigger": "geofence_miss"]
        )
    }
    
    // 2. Tasks
    func testTaskReminder() {
        scheduleDebugNotification(
            title: "Task Reminder",
            body: "Calculus Homework Due",
            timeInterval: 5,
            categoryIdentifier: "TASK_REMINDER",
            userInfo: ["taskID": "TEST_TASK_ID"]
        )
    }
    
    // 3. Smart Features
    func testSmartGap() {
        scheduleDebugNotification(title: "Smart Gap", body: "2h Free time detected. Study now?", timeInterval: 5)
    }
    
    func testStreakNotification() {
        scheduleDebugNotification(title: "🔥 5 Day Streak!", body: "Keep it up!", timeInterval: 5)
    }
    
    func testHeavyDayNotification() {
        scheduleDebugNotification(
            title: "Busy Day Ahead",
            body: "You have 6 classes tomorrow.",
            timeInterval: 5,
            categoryIdentifier: "MORNING_BRIEFING"
        )
    }
    
    func testGradeRescueNotification() {
        scheduleDebugNotification(
            title: "Grade Alert 📉",
            body: "Math average is low (5.2).",
            timeInterval: 5,
            categoryIdentifier: "GRADE_ALERT",
            userInfo: ["subjectID": "TEST_SUBJECT_ID"]
        )
    }

    @MainActor func checkForSmartGaps(modelContext: ModelContext) { testSmartGap() }
    @MainActor func scheduleHeavyDayWarning(modelContext: ModelContext) { testHeavyDayNotification() }
    @MainActor func checkGradeHealth(modelContext: ModelContext) { testGradeRescueNotification() }

    // ✅ FIXED: Added userInfo parameter
    private func scheduleDebugNotification(title: String, body: String, timeInterval: TimeInterval, categoryIdentifier: String? = nil, userInfo: [AnyHashable: Any] = [:]) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        if let cat = categoryIdentifier { content.categoryIdentifier = cat }
        content.userInfo = userInfo // Inject fake data
        
        // Always use a unique UUID so tests don't overwrite each other
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
