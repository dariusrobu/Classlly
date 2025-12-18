import SwiftUI
import UserNotifications
import Combine

class StudyTimerManager: ObservableObject {
    static let shared = StudyTimerManager()
    
    @Published var timeRemaining: TimeInterval = 25 * 60
    @Published var totalTime: TimeInterval = 25 * 60
    @Published var isRunning = false
    @Published var selectedMode = 0
    @Published var progress: Double = 0.0
    
    private var timer: AnyCancellable?
    private var endDate: Date? // Critical for background calculation
    
    init() {
        requestPermissions()
    }
    
    func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func setMode(_ mode: Int) {
        guard !isRunning else { return }
        selectedMode = mode
        switch mode {
        case 0: totalTime = 25 * 60 // Focus
        case 1: totalTime = 5 * 60  // Short Break
        case 2: totalTime = 15 * 60 // Long Break
        default: totalTime = 25 * 60
        }
        timeRemaining = totalTime
        progress = 0.0
    }
    
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        // Set the definitive end time based on current wall-clock time
        endDate = Date().addingTimeInterval(timeRemaining)
        
        scheduleCompletionNotification()
        startTimerLoop()
    }
    
    func pause() {
        isRunning = false
        timer?.cancel()
        timer = nil
        endDate = nil
        cancelNotifications()
    }
    
    func reset() {
        pause()
        setMode(selectedMode)
    }
    
    // MARK: - Lifecycle Hooks
    
    func appDidEnterBackground() {
        // App is suspending; the loop will stop, but `endDate` and notification remain valid.
        print("Timer backgrounded. Scheduled end: \(String(describing: endDate))")
    }
    
    func appWillEnterForeground() {
        guard isRunning, let end = endDate else { return }
        
        let remaining = end.timeIntervalSinceNow
        
        if remaining <= 0 {
            // Timer finished while in background
            stop()
        } else {
            // Timer still valid; catch up the UI
            self.timeRemaining = remaining
            self.progress = 1.0 - (remaining / totalTime)
            
            // Restart the loop if it was killed
            if timer == nil {
                startTimerLoop()
            }
        }
    }
    
    // MARK: - Private Logic
    
    private func startTimerLoop() {
        timer?.cancel()
        // Standard timer loop for UI updates
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            self?.tick()
        }
    }
    
    private func tick() {
        guard let endDate = endDate else { return }
        let remaining = endDate.timeIntervalSinceNow
        
        if remaining <= 0 {
            stop()
        } else {
            self.timeRemaining = remaining
            self.progress = 1.0 - (remaining / totalTime)
        }
    }
    
    private func stop() {
        isRunning = false
        timeRemaining = 0
        progress = 1.0
        timer?.cancel()
        timer = nil
        endDate = nil
        // We don't cancel notifications here; allow the final "Ding" to show
    }
    
    private func scheduleCompletionNotification() {
        cancelNotifications() // Clear old ones
        
        let content = UNMutableNotificationContent()
        content.title = selectedMode == 0 ? "Session Complete" : "Break Over"
        content.body = selectedMode == 0 ? "Great job! Time to take a break." : "Time to get back to work!"
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        
        // Fire exactly when timeRemaining runs out
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeRemaining, repeats: false)
        let request = UNNotificationRequest(identifier: "StudyTimerComplete", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["StudyTimerComplete"])
    }
}
