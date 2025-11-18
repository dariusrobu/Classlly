import SwiftUI
import UIKit
import SwiftData

@main
struct ClassllyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var calendarManager = AcademicCalendarManager()
    @StateObject private var themeManager = AppTheme()

    var modelContainer: ModelContainer = {
        let schema = Schema([
            Subject.self,
            StudyTask.self,
            GradeEntry.self,
            AttendanceEntry.self,
            StudyCalendarEvent.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        // --- STANDARD MODE DEFAULT ---
        // We do NOT force transparent backgrounds here anymore.
        // This ensures "Normal" mode looks like a standard iOS app.
        
        // We only keep TableView clear so that if we ARE in gamified mode,
        // the background image can show through the lists.
        // In standard mode, ContentView provides the system background, so this is safe.
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear
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
