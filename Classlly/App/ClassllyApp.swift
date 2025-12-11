import SwiftUI
import SwiftData

@main
struct ClassllyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Initialize shared managers
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var themeManager = AppTheme.shared
    @StateObject private var calendarManager = AcademicCalendarManager.shared
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                // ✅ LOGGED IN: Show Main Tab Bar
                MainTabView()
                    .environmentObject(themeManager)
                    .environmentObject(authManager)
                    .environmentObject(calendarManager)
            } else {
                // 🔒 LOGGED OUT: Show Sign In
                SignInView()
                    .environmentObject(authManager)
                    .environmentObject(calendarManager)
            }
        }
        // 🔴 CRITICAL: Registers the database. If this is missing, the app crashes.
        .modelContainer(for: [
            Subject.self,
            StudyTask.self,
            GradeEntry.self,
            AttendanceEntry.self,
            StudyCalendarEvent.self,
            StudentProfile.self,
            ClassEvent.self
        ])
    }
}
