import SwiftData
import Foundation

struct SharedPersistence {
    // ⚠️ REPLACE THIS with your actual App Group ID from Xcode Signing & Capabilities
    static let appGroupIdentifier = "group.com.robudarius.classlly"

    static var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            Subject.self,
            StudyTask.self,
            GradeEntry.self,
            AttendanceEntry.self,
            StudyCalendarEvent.self
        ])
        
        let modelConfiguration: ModelConfiguration
        
        // Point to the App Group container so Widgets can read it
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            let sqliteURL = url.appendingPathComponent("Classlly.sqlite")
            // ✅ FIXED: Removed 'cloudKitDatabase: .private' to fix build error
            modelConfiguration = ModelConfiguration("Default", url: sqliteURL)
        } else {
            // Fallback if App Group is missing
            modelConfiguration = ModelConfiguration("Default", isStoredInMemoryOnly: false)
        }

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create Shared ModelContainer: \(error)")
        }
    }()
}
