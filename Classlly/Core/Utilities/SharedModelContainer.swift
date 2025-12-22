import Foundation
import SwiftData

class SharedModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([
            StudentProfile.self,
            Subject.self,
            StudyTask.self,
            GradeEntry.self,
            AttendanceEntry.self,
            StudyCalendarEvent.self
        ])
        
        // Define the configuration
        // Note: isStoredInMemoryOnly: false ensures data persists to disk
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            // Attempt to load the container normally
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("❌ FATAL ERROR: Could not create ModelContainer: \(error)")
            
            // ⚠️ DEV MODE: DATA RESET FALLBACK
            // This block handles the "migration failed" error by deleting the incompatible store file.
            // This allows the app to launch with a fresh empty database.
            
            let storeURL = modelConfiguration.url
            print("📍 Store URL: \(storeURL.path)")
            print("♻️ Attempting to wipe database to fix schema mismatch...")
            
            let fileManager = FileManager.default
            
            // Core Data (which SwiftData uses) creates 3 files: .sqlite, .sqlite-wal, .sqlite-shm
            // We need to delete all of them to ensure a clean slate.
            let storePaths = [
                storeURL,
                storeURL.appendingPathExtension("wal"),
                storeURL.appendingPathExtension("shm")
            ]
            
            for url in storePaths {
                do {
                    if fileManager.fileExists(atPath: url.path) {
                        try fileManager.removeItem(at: url)
                        print("   - Deleted: \(url.lastPathComponent)")
                    }
                } catch {
                    print("   - Failed to delete \(url.lastPathComponent): \(error)")
                }
            }
            
            print("✅ Database wipe complete. Re-initializing ModelContainer...")
            
            do {
                // Retry creating the container after wiping the files
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                // If it fails again, we really can't recover.
                fatalError("💀 Unrecoverable SwiftData Error after reset: \(error)")
            }
        }
    }()
}
