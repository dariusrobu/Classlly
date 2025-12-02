import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @EnvironmentObject var themeManager: AppTheme
    @Environment(\.modelContext) var modelContext

    @AppStorage("isFirstLaunch") private var isFirstLaunch: Bool = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = false
    
    // FIX 1: Track the selected tab state here
    @State private var selectedTab: Int = 0
    
    public init() {}
    
    var body: some View {
        ZStack {
            Color.themeBackground
                .ignoresSafeArea()
            
            Group {
                if authManager.isAuthenticated {
                    // FIX 2: Pass the selection binding
                    MainTabView(selection: $selectedTab)
                    // FIX 3: REMOVED .id(...)
                    // This prevents the TabView from being destroyed when theme changes.
                } else {
                    SignInView()
                }
            }
        }
        .preferredColorScheme(darkModeEnabled ? .dark : .light)
        // This .tint updates global controls (TabBar, NavBar) automatically
        // because ContentView observes themeManager.
        .tint(Color.themePrimary)
        .onAppear {
            if isFirstLaunch {
                isFirstLaunch = false
            }
            authManager.checkAuthentication(modelContext: modelContext)
        }
    }
}

struct MainTabView: View {
    // FIX 4: Bind to the parent state
    @Binding var selection: Int
    
    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Image(systemName: "house.fill"); Text("Home") }
                .tag(0)
            
            CalendarView()
                .tabItem { Image(systemName: "calendar"); Text("Calendar") }
                .tag(1)
            
            TasksView()
                .tabItem { Image(systemName: "checklist"); Text("Tasks") }
                .tag(2)
            
            SubjectsView()
                .tabItem { Image(systemName: "book.fill"); Text("Subjects") }
                .tag(3)
            
            SettingsDashboardView()
                .tabItem { Image(systemName: "ellipsis"); Text("More") }
                .tag(4)
        }
    }
}
