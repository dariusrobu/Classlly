import SwiftUI
import SwiftData

@main
struct ClassllyApp: App {
    // Source of Truth
    @State private var authManager = AuthenticationManager()
    
    // MARK: - Database Setup
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AppUser.self,
        ])
        
        // 1. Your specific App Group ID
        let appGroupIdentifier = "group.com.classlly.app"
        
        let modelConfiguration: ModelConfiguration
        
        // 2. Try to locate the App Group Container
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            
            // Construct the path to the database file
            let storeURL = containerURL.appendingPathComponent("Library/Application Support/default.store")
            
            // 🚨 CRITICAL FIX: Explicitly create the directory if it doesn't exist
            let directoryURL = storeURL.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            
            // 3. COMPILE FIX: We include 'schema' here to disambiguate the initializer.
            // This matches init(url:schema:isStoredInMemoryOnly:)
            modelConfiguration = ModelConfiguration(url: storeURL, schema: schema, isStoredInMemoryOnly: false)
            
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
                .environment(authManager)
                .modelContainer(sharedModelContainer)
        }
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
