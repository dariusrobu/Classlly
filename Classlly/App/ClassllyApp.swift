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
            // ⬇️ APPLY MODIFIER INSIDE HERE TO A VIEW, NOT THE WINDOW GROUP
            Group {
                if authManager.isAuthenticated {
                    // Main App Flow
                    MainTabView()
                        .environmentObject(authManager)
                        .environmentObject(themeManager)
                        .environmentObject(notificationManager)
                        .environmentObject(calendarManager)
                        .environmentObject(studyTimerManager)
                        .modelContext(container.mainContext)
                } else {
                    // Onboarding Flow
                    NavigationStack {
                        StickyOnboardingView()
                    }
                    .environmentObject(authManager)
                    .environmentObject(themeManager)
                    .environmentObject(notificationManager)
                    .environmentObject(calendarManager)
                    .environmentObject(studyTimerManager)
                    .modelContext(container.mainContext)
                }
            }
            // ✅ MOVED INSIDE: Attaches to the 'Group' view
            .preferredColorScheme(themeManager.darkModeEnabled ? .dark : .light)
        }
        // Attach the container to the entire WindowGroup
        .modelContainer(container)
    }
}
