import AppIntents
import SwiftData
import WidgetKit

struct ToggleTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Task"
    static var description: IntentDescription = "Completes or uncompletes a task directly from the widget."
    static var openAppWhenRun: Bool = false // ✅ True Interactive Mode
    
    @Parameter(title: "Task ID")
    var taskId: String
    
    init() {}
    
    init(taskId: String) {
        self.taskId = taskId
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let context = ModelContext(SharedPersistence.sharedModelContainer)
        
        // "API Call" to Database
        let descriptor = FetchDescriptor<StudyTask>()
        
        do {
            if let tasks = try? context.fetch(descriptor),
               let task = tasks.first(where: { $0.id.uuidString == taskId }) {
                
                // Update Data
                task.isCompleted.toggle()
                try context.save()
                
                // ✅ Live Update: Force all widgets to refresh immediately
                WidgetCenter.shared.reloadAllTimelines()
                
                return .result()
            }
        } catch {
            print("Error toggling task: \(error)")
        }
        
        return .result()
    }
}
