import SwiftUI
import UIKit
import SwiftData

@main
struct ClassllyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var calendarManager = AcademicCalendarManager()
    @StateObject private var themeManager = AppTheme()

    // SwiftData Model Container Setup
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StudentProfile.self, // ADD THIS
            Subject.self,
            StudyTask.self,
            GradeEntry.self,
            AttendanceEntry.self,
            StudyCalendarEvent.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
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
                .environmentObject(themeManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
