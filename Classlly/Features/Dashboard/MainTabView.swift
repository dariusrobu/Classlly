import SwiftUI
import SwiftData

struct MainTabView: View {
    // MARK: - Environment
    @Environment(AuthenticationManager.self) private var authManager
    @EnvironmentObject var themeManager: AppTheme
    
    // MARK: - Data
    // We fetch the profile here to pass it down to the Home/Dashboard view
    @Query private var profiles: [StudentProfile]
    
    private var currentProfile: StudentProfile? {
        profiles.first
    }
    
    var body: some View {
        TabView {
            // 1. Dashboard / Home
            HomeView(profile: currentProfile)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            // 2. Calendar / Schedule
            CalendarView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
            
            // 3. Subjects (Added)
            SubjectsView()
                .tabItem {
                    Label("Subjects", systemImage: "book.closed.fill")
                }
            
            // 4. Tasks
            TasksView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
            
            // 5. More / Settings
            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
        }
        // Ensure the TabBar looks correct in Rainbow mode (Dark) vs Standard (System)
        .preferredColorScheme(themeManager.selectedGameMode == .rainbow ? .dark : nil)
    }
}

#Preview {
    MainTabView()
        .environment(AuthenticationManager())
        .environmentObject(AppTheme.shared)
        .environmentObject(AcademicCalendarManager.shared)
        .modelContainer(for: [StudentProfile.self, Subject.self, StudyTask.self], inMemory: true)
}
