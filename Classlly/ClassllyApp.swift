import SwiftUI
import SwiftData
import CloudKit

@main
struct ClassllyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var calendarManager = AcademicCalendarManager()
    @StateObject private var themeManager = AppTheme()

    let container: ModelContainer
    
    init() {
        // UI Appearance Setup
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
        
        // SwiftData Container
        do {
            let schema = Schema([
                Subject.self,
                StudyTask.self,
                GradeEntry.self,
                AttendanceEntry.self,
                StudyCalendarEvent.self,
                UserProfile.self
            ])
            
            // FIX: Removed 'cloudKitDatabase: .private' as it is the default behavior
            // and causing overload resolution errors.
            // Ensuring 'isStoredInMemoryOnly: false' enables persistence.
            // CloudKit is enabled via the project Capabilities tab.
            let config = ModelConfiguration(
                "ClassllyCloudStore",
                schema: schema,
                isStoredInMemoryOnly: false
            )
            
            container = try ModelContainer(for: schema, configurations: config)
            
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(calendarManager)
                .environmentObject(themeManager)
                .onReceive(NotificationCenter.default.publisher(for: .deviceDidShakeNotification)) { _ in
                    showDebugMenu()
                }
                .task {
                    // Trigger migration
                    await MigrationManager.shared.migrateLocalDataToCloud(modelContext: container.mainContext)
                }
        }
        .modelContainer(container)
    }
    
    func showDebugMenu() {
        let alert = UIAlertController(title: "Debug Menu", message: "Reset all CloudKit data?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset Cloud Data", style: .destructive) { _ in
            Task { @MainActor in
                await MigrationManager.shared.resetCloudData(in: container.mainContext)
            }
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(alert, animated: true)
        }
    }
}

// Helper for shake gesture
extension NSNotification.Name {
    static let deviceDidShakeNotification = NSNotification.Name("DeviceDidShakeNotification")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShakeNotification, object: nil)
        }
    }
}
