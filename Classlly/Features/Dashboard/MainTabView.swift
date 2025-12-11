import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        TabView {
            // Tab 1: Dashboard
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            // Tab 2: Calendar
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            
            // Tab 3: Subjects
            SubjectsView(embedInNavigationStack: true)
                .tabItem {
                    Label("Subjects", systemImage: "book.fill")
                }
            
            // Tab 4: Tasks
            TasksView(embedInNavigationStack: true)
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
            
            // Tab 5: Settings / Profile
            SettingsDashboardView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
        }
        .tint(themeManager.selectedTheme.primaryColor)
    }
}
