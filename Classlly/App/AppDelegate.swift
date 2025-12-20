import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Request notification permission
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

// Handle notifications
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        switch actionIdentifier {
        case "START_FOCUS_ACTION":
            print("▶️ ACTION: Start Focus Session")
            
        case "MARK_DONE_ACTION":
            print("✅ ACTION: Mark Task Done")
            
        case "MARK_PRESENT_ACTION":
            // 🚀 Logic Hook: Mark attendance as Present
            print("👋 ACTION: Marked Present for subject ID: \(userInfo["subjectID"] ?? "unknown")")
            
        case "MARK_LATE_ACTION":
            // 🚀 Logic Hook: Mark attendance as Late
            print("🏃 ACTION: Marked Late for subject ID: \(userInfo["subjectID"] ?? "unknown")")
            
        case UNNotificationDefaultActionIdentifier:
            print("Notification body tapped")
            
        case UNNotificationDismissActionIdentifier:
            print("Notification dismissed")
            
        default:
            break
        }
        
        completionHandler()
    }
}
