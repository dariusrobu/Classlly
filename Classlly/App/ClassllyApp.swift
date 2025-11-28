import SwiftUI
import SwiftData

@main
struct ClassllyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var calendarManager = AcademicCalendarManager()
    @StateObject private var themeManager = AppTheme()

    // FIX: Use the shared factory method
    var modelContainer: ModelContainer = SharedModelContainer.create()
    
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
                .environmentObject(themeManager)
        }
        .modelContainer(modelContainer)
    }
}
