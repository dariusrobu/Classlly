import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @EnvironmentObject var themeManager: AppTheme
    @Environment(\.modelContext) var modelContext
    @Environment(\.horizontalSizeClass) var sizeClass

    @AppStorage("isFirstLaunch") private var isFirstLaunch: Bool = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = false
    
    // Tab Selection
    @State private var selectedTab: TabIdentifier? = .home
    
    public init() {}
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            Group {
                if authManager.isAuthenticated {
                    if sizeClass == .regular {
                        NavigationStack { HomeView() }
                            .environmentObject(authManager)
                    } else {
                        MainTabView(selectedTab: $selectedTab)
                            .environmentObject(authManager)
                    }
                } else {
                    SignInView().environmentObject(authManager)
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
        // ✅ HANDLE WIDGET DEEP LINKS
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        print("Deep Link: \(url.absoluteString)")
        
        switch url.host {
        case "home": selectedTab = .home
        case "calendar": selectedTab = .calendar
        case "tasks": selectedTab = .tasks
        case "subjects": selectedTab = .subjects
        case "subject":
            selectedTab = .subjects
            // Note: Deep linking to specific detail view requires more complex navigation state
            // For now, we just go to the Subjects list.
        default: break
        }
    }
}

// (Keep the existing Enum and MainTabView structs here...)
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
            NavigationStack { HomeView() }.tag(TabIdentifier.home as TabIdentifier?).tabItem { Label("Home", systemImage: "house.fill") }
            NavigationStack { CalendarView() }.tag(TabIdentifier.calendar as TabIdentifier?).tabItem { Label("Calendar", systemImage: "calendar") }
            NavigationStack { TasksView() }.tag(TabIdentifier.tasks as TabIdentifier?).tabItem { Label("Tasks", systemImage: "checklist") }
            NavigationStack { SubjectsView() }.tag(TabIdentifier.subjects as TabIdentifier?).tabItem { Label("Subjects", systemImage: "book.fill") }
            NavigationStack { SettingsDashboardView() }.tag(TabIdentifier.settings as TabIdentifier?).tabItem { Label("More", systemImage: "ellipsis") }
        }
        .tint(themeManager.selectedTheme.accentColor)
    }
}
