import SwiftUI
import UserNotifications
import Combine
import SwiftData

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
                    self.setupNotificationCategories()
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                } else {
                    print("Notification permission denied")
                }
            }
        }
    }
    
    // --- Setup Categories ---
    func setupNotificationCategories() {
        // 1. GAP FILLER
        let startFocusAction = UNNotificationAction(identifier: "START_FOCUS_ACTION", title: "Start Focus Session", options: .foreground)
        let gapFillerCategory = UNNotificationCategory(identifier: "GAP_FILLER", actions: [startFocusAction], intentIdentifiers: [], options: .customDismissAction)
        
        // 2. TASK ACTIONS
        let markDoneAction = UNNotificationAction(identifier: "MARK_DONE_ACTION", title: "Mark Task Done", options: [])
        let preFlightCategory = UNNotificationCategory(identifier: "PRE_FLIGHT", actions: [markDoneAction], intentIdentifiers: [], options: .customDismissAction)
        
        // 3. CLASS ACTIONS
        let markPresentAction = UNNotificationAction(identifier: "MARK_PRESENT_ACTION", title: "Mark Present", options: [])
        let markLateAction = UNNotificationAction(identifier: "MARK_LATE_ACTION", title: "Running Late", options: [])
        let classStartCategory = UNNotificationCategory(identifier: "CLASS_START", actions: [markPresentAction, markLateAction], intentIdentifiers: [], options: .customDismissAction)
        
        // 4. HEAVY LOAD
        let heavyLoadCategory = UNNotificationCategory(identifier: "HEAVY_LOAD", actions: [], intentIdentifiers: [], options: .customDismissAction)
        
        // 5. GRADE RESCUE
        let checkWhatIfAction = UNNotificationAction(identifier: "CHECK_WHAT_IF_ACTION", title: "Check What-If Calculator", options: .foreground)
        let gradeRescueCategory = UNNotificationCategory(identifier: "GRADE_RESCUE", actions: [checkWhatIfAction], intentIdentifiers: [], options: .customDismissAction)
        
        UNUserNotificationCenter.current().setNotificationCategories([
            gapFillerCategory,
            preFlightCategory,
            classStartCategory,
            heavyLoadCategory,
            gradeRescueCategory
        ])
    }
    
    // --- FEATURE: Heavy Day Warning ---
    func scheduleHeavyDayWarning(modelContext: ModelContext) {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) else { return }
        let weekday = calendar.component(.weekday, from: tomorrow)
        
        let descriptor = FetchDescriptor<Subject>()
        guard let subjects = try? modelContext.fetch(descriptor) else { return }
        
        var classStartTimes: [Date] = []
        
        for subject in subjects {
            if subject.courseDays.contains(weekday) {
                if let start = normalizeTime(for: subject.courseStartTime, on: tomorrow) {
                    classStartTimes.append(start)
                }
            }
            if subject.seminarDays.contains(weekday) {
                if let start = normalizeTime(for: subject.seminarStartTime, on: tomorrow) {
                    classStartTimes.append(start)
                }
            }
        }
        
        if classStartTimes.count > 4 {
            classStartTimes.sort()
            guard let firstClass = classStartTimes.first else { return }
            
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            let timeString = formatter.string(from: firstClass)
            
            let content = UNMutableNotificationContent()
            content.title = "💤 Get some rest"
            content.body = "Tomorrow is busy! You have \(classStartTimes.count) classes starting at \(timeString)."
            content.sound = .default
            content.categoryIdentifier = "HEAVY_LOAD"
            
            var triggerDate = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: Date())!
            if triggerDate < Date() {
                triggerDate = Date().addingTimeInterval(60)
            }
            
            let components = calendar.dateComponents([.hour, .minute, .second], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "heavy-day-warning-\(weekday)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                // ✅ FIX: Removed invalid 'if let'
                if error == nil {
                    print("✅ Heavy Day Warning scheduled for 9:00 PM")
                }
            }
        }
    }
    
    // --- FEATURE: Grade Health Check ---
    func checkGradeHealth(modelContext: ModelContext) {
        print("📉 Checking Grade Health...")
        
        let descriptor = FetchDescriptor<Subject>()
        guard let subjects = try? modelContext.fetch(descriptor) else { return }
        
        for subject in subjects {
            if let currentGrade = subject.currentGrade, currentGrade < 5.0 {
                let content = UNMutableNotificationContent()
                content.title = "📉 \(subject.title) Alert"
                let formattedGrade = String(format: "%.1f", currentGrade)
                content.body = "Average is \(formattedGrade). Check What-If to see how to pass."
                content.sound = .default
                content.categoryIdentifier = "GRADE_RESCUE"
                content.userInfo = ["subjectID": subject.id.uuidString]
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                let request = UNNotificationRequest(identifier: "grade-rescue-\(subject.id.uuidString)", content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { error in
                    if error == nil {
                        print("⚠️ Grade Alert Scheduled for \(subject.title)")
                    }
                }
            }
        }
    }

    // --- REAL GAP LOGIC (Full Implementation) ---
    func checkForSmartGaps(modelContext: ModelContext) {
        print("🕵️‍♂️ Checking for gaps in today's schedule...")
        
        let descriptor = FetchDescriptor<Subject>()
        guard let subjects = try? modelContext.fetch(descriptor) else { return }
        
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        
        struct ClassEvent {
            let name: String
            let start: Date
            let end: Date
        }
        
        var todayEvents: [ClassEvent] = []
        
        for subject in subjects {
            if subject.courseDays.contains(weekday) {
                if let start = normalizeTime(for: subject.courseStartTime, on: today),
                   let end = normalizeTime(for: subject.courseEndTime, on: today) {
                    todayEvents.append(ClassEvent(name: "\(subject.title) (Course)", start: start, end: end))
                }
            }
            if subject.seminarDays.contains(weekday) {
                if let start = normalizeTime(for: subject.seminarStartTime, on: today),
                   let end = normalizeTime(for: subject.seminarEndTime, on: today) {
                    todayEvents.append(ClassEvent(name: "\(subject.title) (Seminar)", start: start, end: end))
                }
            }
        }
        
        todayEvents.sort { $0.start < $1.start }
        
        if todayEvents.isEmpty {
            print("📭 No classes found for today.")
            return
        }
        
        var gapFound = false
        for i in 0..<todayEvents.count - 1 {
            let currentClass = todayEvents[i]
            let nextClass = todayEvents[i+1]
            let gapDuration = nextClass.start.timeIntervalSince(currentClass.end)
            
            if gapDuration > 7200 { // > 2 hours
                gapFound = true
                let hours = String(format: "%.1f", gapDuration / 3600.0)
                
                let content = UNMutableNotificationContent()
                content.title = "🚀 \(hours)h Gap detected"
                content.body = "Free time between \(currentClass.name) and \(nextClass.name)."
                content.sound = .default
                content.categoryIdentifier = "GAP_FILLER"
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { error in
                    if error == nil { print("Notification dispatched!") }
                }
            }
        }
        
        if !gapFound {
            print("✅ Analysis Complete: No gaps > 2 hours found today.")
        }
    }

    // --- Standard Scheduling Methods ---
    
    func scheduleClassReminder(for subject: Subject, isCourseClass: Bool = true) {
        let classTime = isCourseClass ? subject.courseStartTime : subject.seminarStartTime
        let className = isCourseClass ? "Course" : "Seminar"
        let classDays = isCourseClass ? subject.courseDays : subject.seminarDays
        
        for day in classDays {
            let content = UNMutableNotificationContent()
            content.title = "🏫 Class Starting Soon"
            content.body = "\(subject.title) \(className) starts in 15 minutes"
            content.sound = .default
            content.categoryIdentifier = "CLASS_START"
            content.userInfo = ["subjectID": subject.id.uuidString]
            
            let reminderTime = Calendar.current.date(byAdding: .minute, value: -15, to: classTime) ?? classTime
            var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            dateComponents.weekday = day
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "class-\(subject.id.uuidString)-\(className)-\(day)", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    func scheduleTaskReminder(for task: StudyTask) {
        guard let dueDate = task.dueDate, task.reminderTime != .none else { return }
        let content = UNMutableNotificationContent()
        content.title = "📚 Task Due Soon"
        content.body = "\(task.title) is due soon!"
        content.sound = .default
        content.categoryIdentifier = "PRE_FLIGHT"
        
        guard let reminderDate = task.reminderTime.reminderDate(from: dueDate), reminderDate > Date() else { return }
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "task-\(task.id.uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleWeeklyProgressReminder() {
        let content = UNMutableNotificationContent()
        content.title = "📊 Weekly Progress Check"
        content.body = "Don't forget to update your grades and attendance for this week!"
        content.sound = .default
        var dateComponents = DateComponents(); dateComponents.weekday = 2; dateComponents.hour = 9; dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "weekly-progress", content: content, trigger: trigger))
    }

    // --- Helpers ---
    private func normalizeTime(for time: Date, on date: Date) -> Date? {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        var mergedComponents = DateComponents()
        mergedComponents.year = dateComponents.year
        mergedComponents.month = dateComponents.month
        mergedComponents.day = dateComponents.day
        mergedComponents.hour = timeComponents.hour
        mergedComponents.minute = timeComponents.minute
        
        return calendar.date(from: mergedComponents)
    }
    
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { completion($0) }
    }
    
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}

// MARK: - Testing Extension
extension NotificationManager {
    
    func testHeavyDayNotification() {
        let content = UNMutableNotificationContent()
        content.title = "💤 Get some rest"
        content.body = "Tomorrow is busy! You have 6 classes starting at 8:00 AM."
        content.sound = .default
        content.categoryIdentifier = "HEAVY_LOAD"
        triggerTest(content: content)
    }
    
    func testGradeRescueNotification() {
        let content = UNMutableNotificationContent()
        content.title = "📉 Calculus Alert"
        content.body = "Average is 4.2. Check What-If to see how to pass."
        content.sound = .default
        content.categoryIdentifier = "GRADE_RESCUE"
        triggerTest(content: content)
    }
    
    func testClassReminder() {
        let content = UNMutableNotificationContent()
        content.title = "🏫 Class Starting Soon"
        content.body = "Software Engineering starts in 15 minutes."
        content.categoryIdentifier = "CLASS_START"
        triggerTest(content: content)
    }
    
    func testTaskReminder() {
        let content = UNMutableNotificationContent()
        content.title = "📚 Task Due Soon"
        content.body = "Calculus Homework is due in 1 hour!"
        content.categoryIdentifier = "PRE_FLIGHT"
        triggerTest(content: content)
    }
    
    func testSmartGap() {
        let content = UNMutableNotificationContent()
        content.title = "🚀 You have a 2.5h gap"
        content.body = "Perfect time to finish History Essay."
        content.categoryIdentifier = "GAP_FILLER"
        triggerTest(content: content)
    }
    
    func testStreakNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🔥 5-Class Streak!"
        content.body = "Keep it up!"
        triggerTest(content: content)
    }
    
    private func triggerTest(content: UNMutableNotificationContent) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "test-\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error { print("Error testing notification: \(error)") }
        }
    }
}
