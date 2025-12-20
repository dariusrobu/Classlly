import Foundation
import SwiftData

class SharedModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([
            Subject.self,
            StudyTask.self,
            GradeEntry.self,
            AttendanceEntry.self,
            StudentProfile.self,
            // ⚠️ Ensure this class actually exists in your project!
            // If StudyCalendarEvent is missing, remove this line.
            StudyCalendarEvent.self
        ])
        
        // Define the App Group ID
        let appGroupIdentifier = "group.com.classlly"
        
        // Try to use the App Group, but fallback safely to Documents if it fails
        let containerURL: URL
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            containerURL = groupURL
        } else {
            print("⚠️ WARNING: App Group container not found. Falling back to local Documents.")
            containerURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        }
        
        let storeURL = containerURL.appendingPathComponent("default.store")
        
        let modelConfiguration = ModelConfiguration(
            url: storeURL,
            allowsSave: true
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Print the error so you can see it in the debug console
            print("❌ FATAL ERROR: Could not create ModelContainer: \(error)")
            fatalError("Could not create Shared ModelContainer: \(error)")
        }
    }()
}
