import SwiftUI
import SwiftData
import Combine

@main
struct ClassllyApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var calendarManager = AcademicCalendarManager()
    @StateObject private var themeManager = AppTheme()
    @StateObject private var dataController = DataController()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(calendarManager)
                .environmentObject(themeManager)
                .modelContainer(dataController.container)
        }
    }
}

@MainActor
class DataController: ObservableObject {
    @Published var container: ModelContainer
    
    init() {
        // Always launch with an in-memory container first for immediate UI startup
        let schema = Schema([
            Subject.self,
            StudyTask.self,
            GradeEntry.self,
            AttendanceEntry.self,
            StudyCalendarEvent.self
        ])
        self.container = try! ModelContainer(for: schema, configurations: [
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        ])
        print("✅ Immediate in-memory ModelContainer created and used for UI launch!")
        Task {
            await setupContainer()
        }
    }
    
    private func setupContainer() async {
        do {
            let schema = Schema([
                Subject.self,
                StudyTask.self,
                GradeEntry.self,
                AttendanceEntry.self,
                StudyCalendarEvent.self
            ])
            
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                groupContainer: .none,
                cloudKitDatabase: .private("iCloud.com.robudarius.classlly")
            )
            
            let iCloudContainer = try ModelContainer(for: schema, configurations: [configuration])
            await MainActor.run {
                self.container = iCloudContainer
            }
            print("✅ iCloud ModelContainer created!")
            
        } catch {
            print("❌ iCloud failed, continuing with existing container: \(error)")
        }
    }
}
