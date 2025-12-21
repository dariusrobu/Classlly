import SwiftUI
import SwiftData

@main
struct ClassllyApp: App {
    // MARK: - Services
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var themeManager = AppTheme.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var calendarManager = AcademicCalendarManager.shared
    @StateObject private var studyTimerManager = StudyTimerManager.shared
    
    // MARK: - Data Persistence
    let container = SharedModelContainer.shared
    
    var body: some Scene {
        WindowGroup {
            // ZStack ensures the root view hierarchy remains stable during transitions
            ZStack {
                // MARK: - Routing Logic
                if !authManager.hasSeenCarousel {
                    // 1. First Launch: Show Carousel
                    StickyOnboardingView()
                        .transition(.opacity)
                        .zIndex(1)
                } else if !authManager.isAuthenticated {
                    // 2. Carousel Done, Needs Sign In
                    SignInView()
                        .transition(.move(edge: .trailing))
                        .zIndex(2)
                } else if !authManager.hasCompletedOnboarding {
                    // 3. Signed In, Needs Profile Setup
                    if let user = authManager.currentUser {
                        ProfileSetupView(user: user)
                            .transition(.move(edge: .bottom))
                            .zIndex(3)
                    } else {
                        // Fallback: Recover user from DB if memory was lost (e.g. restart)
                        UserRecoveryView()
                            .zIndex(3)
                    }
                } else {
                    // 4. All Done: Main Dashboard
                    MainTabView()
                        .transition(.opacity)
                        .zIndex(4)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
            .animation(.easeInOut(duration: 0.3), value: authManager.hasCompletedOnboarding)
            .environmentObject(authManager)
            .environmentObject(themeManager)
            .environmentObject(notificationManager)
            .environmentObject(calendarManager)
            .environmentObject(studyTimerManager)
            .preferredColorScheme(themeManager.darkModeEnabled ? .dark : .light)
        }
        .modelContainer(container)
    }
}

// Helper View to recover user if memory is lost but auth is true
struct UserRecoveryView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var authManager: AuthenticationManager
    @Query private var students: [StudentProfile]
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Restoring Session...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            // Attempt to restore user from DB
            if let existing = students.first {
                print("🔄 Recovered user from database")
                authManager.currentUser = existing
            } else {
                // If persistence failed or user was deleted, we must reset to Sign In
                print("❌ No user found in storage. Resetting auth.")
                authManager.signOut()
            }
        }
    }
}
