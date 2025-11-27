import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @EnvironmentObject var themeManager: AppTheme
    @Environment(\.modelContext) var modelContext

    @AppStorage("isFirstLaunch") private var isFirstLaunch: Bool = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = false
    
    @State private var selectedTab: TabIdentifier? = .home
    
    public init() {}
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            Group {
                if authManager.isAuthenticated {
                    // Unified Tab Bar for BOTH iPhone and iPad
                    MainTabView(selectedTab: $selectedTab)
                        .environmentObject(authManager)
                        .environmentObject(calendarManager) // ✅ ENSURE INJECTION
                        .environmentObject(themeManager)    // ✅ ENSURE INJECTION
                } else {
                    SignInView()
                        .environmentObject(authManager)
                        .environmentObject(calendarManager) // Pass to SignInView too if needed
                }
            }
        }
        .fullScreenCover(isPresented: $authManager.requiresOnboarding) {
            AcademicOnboardingView()
                .environmentObject(authManager)
                .environmentObject(calendarManager)
        }
        .preferredColorScheme(darkModeEnabled ? .dark : .light)
        .tint(themeManager.selectedTheme.accentColor)
        .onAppear {
            if isFirstLaunch { isFirstLaunch = false }
            authManager.loadUser(context: modelContext)
        }
    }
}

enum TabIdentifier: String, CaseIterable {
    case home = "Home"
    case calendar = "Calendar"
    case tasks = "Tasks"
    case subjects = "Subjects"
    case settings = "More"
}

struct MainTabView: View {
    @Binding var selectedTab: TabIdentifier?
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { HomeView() }
                .tag(TabIdentifier.home as TabIdentifier?)
                .tabItem { Label("Home", systemImage: "house.fill") }
            
            NavigationStack { CalendarView() }
                .tag(TabIdentifier.calendar as TabIdentifier?)
                .tabItem { Label("Calendar", systemImage: "calendar") }
            
            NavigationStack { TasksView() }
                .tag(TabIdentifier.tasks as TabIdentifier?)
                .tabItem { Label("Tasks", systemImage: "checklist") }
            
            NavigationStack { SubjectsView() }
                .tag(TabIdentifier.subjects as TabIdentifier?)
                .tabItem { Label("Subjects", systemImage: "book.fill") }
            
            NavigationStack { SettingsDashboardView() }
                .tag(TabIdentifier.settings as TabIdentifier?)
                .tabItem { Label("More", systemImage: "ellipsis") }
        }
        .tint(themeManager.selectedTheme.accentColor)
    }
}
