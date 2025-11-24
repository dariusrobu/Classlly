import SwiftUI
import SwiftData

actor MigrationManager {
    static let shared = MigrationManager()
    
    private init() {}
    
    /// Performs one-time migration from Local to Cloud
    @MainActor
    func migrateLocalDataToCloud(modelContext: ModelContext) {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "hasMigratedToCloud") { return }
        
        print("🔄 Starting migration to CloudKit...")
        
        // 1. Define the URL of the OLD local store
        guard let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        let localStoreURL = supportDir.appendingPathComponent("default.store")
        
        // Only migrate if local file actually exists
        guard FileManager.default.fileExists(atPath: localStoreURL.path) else {
            defaults.set(true, forKey: "hasMigratedToCloud")
            return
        }
        
        // 2. Create a container for the OLD local data
        // FIX: Pass allowsSave directly in init to avoid "let" constant error
        let localConfig = ModelConfiguration(url: localStoreURL, allowsSave: false)
        
        do {
            let localContainer = try ModelContainer(
                for: Subject.self, StudyTask.self, GradeEntry.self, AttendanceEntry.self, StudyCalendarEvent.self, UserProfile.self,
                configurations: localConfig
            )
            let localContext = localContainer.mainContext
            
            // 3. Fetch all old data
            let subjects = try localContext.fetch(FetchDescriptor<Subject>())
            let tasks = try localContext.fetch(FetchDescriptor<StudyTask>())
            let grades = try localContext.fetch(FetchDescriptor<GradeEntry>())
            let attendance = try localContext.fetch(FetchDescriptor<AttendanceEntry>())
            let events = try localContext.fetch(FetchDescriptor<StudyCalendarEvent>())
            let profiles = try localContext.fetch(FetchDescriptor<UserProfile>())
            
            print("📥 Found \(subjects.count) subjects, \(tasks.count) tasks to migrate.")
            
            // 4. Re-insert into the NEW Cloud context
            for profile in profiles { modelContext.insert(profile) }
            for subject in subjects { modelContext.insert(subject) }
            for task in tasks { modelContext.insert(task) }
            for grade in grades { modelContext.insert(grade) }
            for att in attendance { modelContext.insert(att) }
            for event in events { modelContext.insert(event) }
            
            try modelContext.save()
            
            // 5. Mark complete
            defaults.set(true, forKey: "hasMigratedToCloud")
            print("✅ Migration successful!")
            
        } catch {
            print("❌ Migration failed: \(error)")
        }
    }
    
    func resetCloudData(in context: ModelContext) {
        do {
            try context.delete(model: Subject.self)
            try context.delete(model: StudyTask.self)
            try context.delete(model: GradeEntry.self)
            try context.delete(model: AttendanceEntry.self)
            try context.delete(model: StudyCalendarEvent.self)
            try context.delete(model: UserProfile.self)
            try context.save()
            print("⚠️ Cloud data reset.")
        } catch {
            print("Error resetting data: \(error)")
        }
    }
}
