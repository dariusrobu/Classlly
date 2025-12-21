import SwiftUI
import SwiftData

@main
struct ClassllyApp: App {
    // Initialize services
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var themeManager = AppTheme.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var calendarManager = AcademicCalendarManager.shared
    @StateObject private var studyTimerManager = StudyTimerManager.shared
    
    // We use the shared container for Widget support
    let container = SharedModelContainer.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    // 1. User is fully logged in -> Main App
                    MainTabView()
                } else if authManager.hasCompletedOnboarding {
                    // 2. User finished slides but hasn't signed in -> Sign In
                    SignInView()
                } else {
                    // 3. New user -> Onboarding Slides
                    NavigationStack {
                        StickyOnboardingView()
                    }
                }
            }
            .environmentObject(authManager)
            .environmentObject(themeManager)
            .environmentObject(notificationManager)
            .environmentObject(calendarManager)
            .environmentObject(studyTimerManager)
            .modelContext(container.mainContext)
            .preferredColorScheme(themeManager.darkModeEnabled ? .dark : .light)
        }
        .modelContainer(container)
    }
}
