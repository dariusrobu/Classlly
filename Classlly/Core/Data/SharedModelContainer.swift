import SwiftData
import Foundation

class SharedModelContainer {
    static func create() -> ModelContainer {
        let schema = Schema([
            Subject.self,
            StudyTask.self,
            GradeEntry.self,
            AttendanceEntry.self,
            StudyCalendarEvent.self
        ])
        
        let modelConfiguration: ModelConfiguration
        
        // IMPORTANT: Replace "group.com.robudarius.classlly" with your exact App Group ID if different
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.robudarius.classlly") {
            let storeURL = containerURL.appendingPathComponent("Classlly.sqlite")
            // FIX: Removed 'isStoredInMemoryOnly: false' as it is not valid with 'url:'
            modelConfiguration = ModelConfiguration(url: storeURL)
        } else {
            // Fallback for previews or if App Group isn't found
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create Shared ModelContainer: \(error)")
        }
    }
}
