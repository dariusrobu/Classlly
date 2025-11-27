import SwiftUI
import SwiftData

enum MigrationManager {
    static let schema = Schema([
        Subject.self,
        StudyTask.self,
        GradeEntry.self,
        AttendanceEntry.self,
        StudyCalendarEvent.self
        // ❌ REMOVED: UserProfile.self (It is now a struct, not a @Model)
    ])
    
    static let modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false
    )
    
    static var container: ModelContainer {
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    /// Clears all application data from SwiftData (For debugging/reset purposes)
    /// Note: This does NOT clear UserProfile since it is stored in UserDefaults/iCloud now.
    @MainActor
    static func clearAllData(context: ModelContext) {
        do {
            try context.delete(model: Subject.self)
            try context.delete(model: StudyTask.self)
            try context.delete(model: GradeEntry.self)
            try context.delete(model: AttendanceEntry.self)
            try context.delete(model: StudyCalendarEvent.self)
            // ❌ REMOVED: try context.delete(model: UserProfile.self)
            
            print("✅ SwiftData cleared successfully.")
        } catch {
            print("❌ Failed to clear SwiftData: \(error)")
        }
    }
}
