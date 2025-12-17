import SwiftUI
import SwiftData

@main
struct ClassllyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Shared Managers
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var themeManager = AppTheme.shared
    @StateObject private var calendarManager = AcademicCalendarManager.shared
    
    // Listen to Settings
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    MainTabView()
                        .environmentObject(themeManager)
                        .environmentObject(authManager)
                        .environmentObject(calendarManager)
                } else {
                    SignInView()
                        .environmentObject(authManager)
                        .environmentObject(calendarManager)
                        .environmentObject(themeManager) // ✅ FIXED: Injected here so Onboarding can see it
                }
            }
            // 1. Force Dark Mode based on settings
            .preferredColorScheme(darkModeEnabled ? .dark : nil)
            // 2. Global Accent Color (buttons, tabs, links)
            .tint(themeManager.selectedTheme.primaryColor)
            // Database
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
}
