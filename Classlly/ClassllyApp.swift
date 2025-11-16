import SwiftUI
import UIKit
import SwiftData

@main
struct ClassllyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var calendarManager = AcademicCalendarManager()
    @StateObject private var themeManager = AppTheme() // Use AppTheme

    // --- THIS IS THE FINAL FIX ---
    var modelContainer: ModelContainer = {
        let schema = Schema([
            Subject.self,
            StudyTask.self,
            GradeEntry.self,
            AttendanceEntry.self,
            StudyCalendarEvent.self
        ])
        
        // 1. Create a ModelConfiguration for iCloud using the CORRECT initializer
        // This initializer matches the error message from your previous screenshot.
        // SwiftData will automatically find the container ID from your .entitlements file.
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true, // This was the missing 'allowsSave' parameter
            groupContainer: .automatic,
            cloudKitDatabase: .automatic // This must be .automatic, NOT a function call
        )

        do {
            // 2. Pass this configuration to the container
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Your crash will no longer happen here if the entitlements
            // and data models are also fixed.
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    // --- END OF FIX ---
    
    init() {
        // --- This is the "off-black" theme for nav bars and lists ---
        let dynamicListBackground = UIColor.systemGroupedBackground
        let dynamicCellBackground = UIColor.secondarySystemGroupedBackground

        UITableView.appearance().backgroundColor = dynamicListBackground
        UITableViewCell.appearance().backgroundColor = dynamicCellBackground
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        
        navBarAppearance.backgroundColor = dynamicListBackground
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        // --- This reverts your tab bar to the original style ---
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(calendarManager)
                .environmentObject(themeManager) // Pass the theme manager
        }
        .modelContainer(modelContainer)
    }
}
