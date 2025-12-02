import SwiftUI
import UserNotifications
import Combine

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var permissionGranted = false
    
    private init() {}
    
    // Request notification permission
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.permissionGranted = granted
                
                if granted {
                    print("Notification permission granted")
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                } else {
                    print("Notification permission denied")
                }
                
                if let error = error {
                    print("Error requesting notification permission: \(error)")
                }
            }
        }
    }
    
    // --- 1. THIS FUNCTION IS NOW UPDATED ---
    func scheduleTaskReminder(for task: StudyTask) {
        // Don't schedule if there's no due date or reminder is set to "none"
        guard let dueDate = task.dueDate, task.reminderTime != .none else {
            // If reminder was set to "none", make sure to remove any old notification
            removeTaskReminder(for: task)
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "📚 Task Due Soon"
        content.body = "\(task.title) is due soon!"
        content.sound = .default
        content.categoryIdentifier = "TASK_REMINDER"
        
        // 2. Calculate the reminder date using our new enum
        guard let reminderDate = task.reminderTime.reminderDate(from: dueDate) else {
            // This should only happen for .none, which we already checked
            return
        }
        
        // 3. Check if the reminder date is in the future
        guard reminderDate > Date() else {
            print("Skipping notification for task '\(task.title)' because reminder time is in the past.")
            return
        }
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "task-\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling task notification: \(error)")
            } else {
                print("Task reminder scheduled for \(task.title) at \(reminderDate)")
            }
        }
    }
    // --- END OF UPDATES ---
    
    // (scheduleClassReminder function is unchanged)
    func scheduleClassReminder(for subject: Subject, isCourseClass: Bool = true) {
        let classTime = isCourseClass ? subject.courseStartTime : subject.seminarStartTime
        let className = isCourseClass ? "Course" : "Seminar"
        let classDays = isCourseClass ? subject.courseDays : subject.seminarDays
        
        for day in classDays {
            scheduleWeeklyClassReminder(
                subject: subject,
                classTime: classTime,
                className: className,
                weekday: day
            )
        }
    }
    
    private func scheduleWeeklyClassReminder(subject: Subject, classTime: Date, className: String, weekday: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🏫 Class Starting Soon"
        content.body = "\(subject.title) \(className) starts in 15 minutes"
        content.sound = .default
        content.categoryIdentifier = "CLASS_REMINDER"
        
        let reminderTime = Calendar.current.date(byAdding: .minute, value: -15, to: classTime) ?? classTime
        
        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        dateComponents.weekday = weekday
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "class-\(subject.id.uuidString)-\(className)-\(weekday)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling class notification: \(error)")
            } else {
                print("Class reminder scheduled for \(subject.title) on weekday \(weekday)")
            }
        }
    }
    
    // (scheduleWeeklyProgressReminder function is unchanged)
    func scheduleWeeklyProgressReminder() {
        let content = UNMutableNotificationContent()
        content.title = "📊 Weekly Progress Check"
        content.body = "Don't forget to update your grades and attendance for this week!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.weekday = 2
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "weekly-progress-reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // (removeTaskReminder function is unchanged)
    func removeTaskReminder(for task: StudyTask) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["task-\(task.id.uuidString)"]
        )
    }
    
    // (removeClassReminders function is unchanged)
    func removeClassReminders(for subject: Subject) {
        var identifiers: [String] = []
        
        for day in subject.courseDays {
            identifiers.append("class-\(subject.id.uuidString)-Course-\(day)")
        }
        
        for day in subject.seminarDays {
            identifiers.append("class-\(subject.id.uuidString)-Seminar-\(day)")
        }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    // (getPendingNotifications function is unchanged)
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            completion(requests)
        }
    }
    
    // (removeAllNotifications function is unchanged)
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "tomorrow"
        } else {
            formatter.dateFormat = "MMM d"
            return "on \(formatter.string(from: date))"
        }
    }
}
