import SwiftUI
import SwiftData

@main
struct ClassllyApp: App {
    // Initialize services
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var themeManager = AppTheme.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
    // We use the shared container for Widget support
    let container = SharedModelContainer.shared
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                // Main App Flow
                MainTabView()
                    .environmentObject(authManager)
                    .environmentObject(themeManager)
                    .environmentObject(notificationManager)
                    // Inject the specific model context from the shared container
                    .modelContext(container.mainContext)
            } else {
                // Onboarding Flow
                NavigationStack {
                    StickyOnboardingView()
                }
                .environmentObject(authManager)
                .environmentObject(themeManager)
                .environmentObject(notificationManager)
                .modelContext(container.mainContext)
            }
        }
        // Attach the container to the entire WindowGroup
        .modelContainer(container)
    }
}
