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
            // Ensure StudyCalendarEvent exists in your project, otherwise remove this line
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
        
        // ✅ FIX: Renamed store to 'classlly.store' to force a fresh database creation.
        // This resolves the "CloudKit unique constraint" crash by abandoning the old, incompatible 'default.store'.
        let storeURL = containerURL.appendingPathComponent("classlly.store")
        
        let modelConfiguration = ModelConfiguration(
            url: storeURL,
            allowsSave: true
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("❌ FATAL ERROR: Could not create ModelContainer: \(error)")
            // Fallback for extreme cases (prevents crash loops)
            do {
                print("🔄 Attempting fallback to local temporary store...")
                let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: false)
                return try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                fatalError("Could not create Shared ModelContainer even with fallback: \(error)")
            }
        }
    }()
}
