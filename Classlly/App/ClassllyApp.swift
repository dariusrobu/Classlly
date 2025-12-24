import SwiftUI
import SwiftData

@main
struct ClassllyApp: App {
    // 🚨 CRITICAL FIX: Connect the AppDelegate to handle app lifecycle and notifications
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Source of Truth
    @State private var authManager = AuthenticationManager()
    
    // ObservableObjects (Combine) need StateObject to manage their lifecycle
    @StateObject private var themeManager = AppTheme.shared
    @StateObject private var calendarManager = AcademicCalendarManager.shared
    
    // MARK: - Database Setup
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AppUser.self,
            StudentProfile.self,
            Subject.self,
            StudyTask.self,
            GradeEntry.self,
            AttendanceEntry.self,
            StudyCalendarEvent.self
        ])
        
        // 1. Your specific App Group ID
        let appGroupIdentifier = "group.com.classlly.app"
        
        let modelConfiguration: ModelConfiguration
        
        // 2. Try to locate the App Group Container
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            
            // Construct the path to the database file
            let storeURL = containerURL.appendingPathComponent("Library/Application Support/default.store")
            
            // Explicitly create the directory if it doesn't exist
            let directoryURL = storeURL.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            
            // Persist to App Group
            modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)
            print("💾 App Group Storage: \(storeURL.path)")
            
        } else {
            print("⚠️ Warning: App Group '\(appGroupIdentifier)' not found. Falling back to standard sandbox.")
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                // Inject Swift 6 Observable
                .environment(authManager)
                // Inject Combine ObservableObjects (Required by Home/Calendar/Tasks Views)
                .environmentObject(themeManager)
                .environmentObject(calendarManager)
                // Inject Database
                .modelContainer(sharedModelContainer)
                // Apply Global Theme
                .preferredColorScheme(activeColorScheme)
        }
    }
    
    // Computed property to determine the active color scheme
    private var activeColorScheme: ColorScheme? {
        if themeManager.selectedGameMode == .rainbow {
            return .dark
        }
        return themeManager.darkModeEnabled ? .dark : .light
    }
}

/// A dedicated wrapper to route the user to the correct screen
struct RootView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @Query private var users: [AppUser]

    var body: some View {
        Group {
            if !authManager.hasCompletedOnboarding {
                StickyOnboardingView()
            }
            else if authManager.isAuthenticated {
                // If we have a session, verify we have a matching AppUser record
                if let _ = users.first(where: { $0.id == authManager.userSession?.uid }) {
                    MainTabView()
                } else {
                    ProfileSetupView()
                }
            }
            else {
                SignInView()
            }
        }
    }
}
