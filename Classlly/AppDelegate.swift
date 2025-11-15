//
//  AppDelegate.swift
//  Classlly
//
//  Created by Robu Darius on 14.11.2025.
//


// File: Classlly/AppDelegate.swift
// Note: This file manages app-level events, including
// setting up and handling push notifications.

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
    
    // Handle remote notification registration
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("APNs token: \(token)")
        // Send this token to your server for push notifications
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
}

// Handle notifications while app is in foreground
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap
        let userInfo = response.notification.request.content.userInfo
        print("Notification tapped with info: \(userInfo)")
        
        // You can add deep linking here based on notification type
        completionHandler()
    }
}