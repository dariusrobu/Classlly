import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @EnvironmentObject var themeManager: AppTheme
    @Environment(\.modelContext) var modelContext

    @AppStorage("isFirstLaunch") private var isFirstLaunch: Bool = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = false
    
    @State private var selectedTab: Int = 0
    
    public init() {}
    
    var body: some View {
        ZStack {
            Color.themeBackground
                .ignoresSafeArea()
            
            Group {
                if authManager.isAuthenticated {
                    if authManager.hasCompletedStickyOnboarding {
                        // User is fully setup -> Main Dashboard
                        MainTabView(selection: $selectedTab)
                    } else {
                        // User is signed in but needs the "Sticky" setup
                        StickyOnboardingView()
                    }
                } else {
                    // User needs to sign in
                    SignInView()
                }
            }
        }
        .preferredColorScheme(darkModeEnabled ? .dark : .light)
        .tint(Color.themePrimary)
        .onAppear {
            if isFirstLaunch {
                isFirstLaunch = false
            }
            authManager.checkAuthentication(modelContext: modelContext)
        }
    }
}

// ... MainTabView remains unchanged ...
struct MainTabView: View {
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
