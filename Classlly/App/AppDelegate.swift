import UIKit
import UserNotifications
import SwiftData

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = self
        NotificationManager.shared.requestPermission()
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("APNs token: \(token)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
}

// Handle notifications actions
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        // 🚀 Create a ModelContext for background work
        let modelContext = ModelContext(SharedModelContainer.shared)
        
        Task { @MainActor in
            switch actionIdentifier {
                
            // MARK: - Attendance Actions
            case "PRESENT_ACTION":
                if let subjectID = userInfo["subjectID"] as? String {
                    logAttendance(subjectID: subjectID, status: .present, context: modelContext)
                }
            case "ABSENT_ACTION":
                if let subjectID = userInfo["subjectID"] as? String {
                    logAttendance(subjectID: subjectID, status: .absent, context: modelContext)
                }
                
            // MARK: - Task Actions
            case "START_TIMER_ACTION":
                print("⏱️ ACTION: Start Timer requested")
                NotificationCenter.default.post(name: NSNotification.Name("StartFocusTimer"), object: nil)
                
            case "COMPLETE_TASK_ACTION":
                if let taskID = userInfo["taskID"] as? String {
                    markTaskComplete(taskID: taskID, context: modelContext)
                }
                
            // MARK: - Navigation Actions
            case "CALCULATE_TARGET_ACTION", "ADD_GRADE_ACTION", "VIEW_SCHEDULE_ACTION", "QUICK_ADD_TASK_ACTION":
                // These have .foreground option, so app opens automatically.
                // You can add deep linking logic here if needed.
                print("📱 App opened for action: \(actionIdentifier)")
                
            default:
                break
            }
            
            completionHandler()
        }
    }
    
    // Helper to log attendance cleanly
    private func logAttendance(subjectID: String, status: AttendanceStatus, context: ModelContext) {
        let descriptor = FetchDescriptor<Subject>(predicate: #Predicate { $0.id == subjectID })
        if let subject = try? context.fetch(descriptor).first {
            let entry = AttendanceEntry(date: Date(), status: status, note: "Logged via Notification")
            subject.attendance?.append(entry) // Relationship handles insertion
            try? context.save()
            print("✅ ACTION: Logged \(status.rawValue) for \(subject.title)")
        } else {
            print("⚠️ Subject not found for ID: \(subjectID)")
        }
    }
    
    // Helper to mark task complete
    private func markTaskComplete(taskID: String, context: ModelContext) {
        let descriptor = FetchDescriptor<StudyTask>(predicate: #Predicate { $0.id == taskID })
        if let task = try? context.fetch(descriptor).first {
            task.isCompleted = true
            try? context.save()
            print("✅ ACTION: Task \(task.title) marked complete")
        }
    }
}
