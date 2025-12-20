import Foundation
import SwiftData

class SharedModelContainer {
    // Singleton instance to be shared across the App and Widget
    static let shared: ModelContainer = {
        let schema = Schema([
            Subject.self,
            StudyTask.self,
            GradeEntry.self,
            AttendanceEntry.self,
            StudentProfile.self,
            // ✅ FIX: Use the actual Model class name, not the file name
            StudyCalendarEvent.self
        ])
        
        // Define the App Group ID
        let appGroupIdentifier = "group.com.classlly"
        
        // Construct the URL for the shared container
        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let storeURL = containerURL.appendingPathComponent("default.store")
        
        let modelConfiguration = ModelConfiguration(
            url: storeURL,
            allowsSave: true
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create Shared ModelContainer: \(error)")
        }
    }()
}
