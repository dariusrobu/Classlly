import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @EnvironmentObject var themeManager: AppTheme // Access Theme Manager

    @AppStorage("isFirstLaunch") private var isFirstLaunch: Bool = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = false
    
    public init() {}
    
    var body: some View {
        ZStack {
            // Global Background
            Color.themeBackground
                .ignoresSafeArea()
            
            Group {
                if authManager.isAuthenticated {
                    MainTabView()
                        .environmentObject(authManager)
                        .environmentObject(calendarManager) // Pass Calendar Manager
                        .environmentObject(themeManager)    // Pass Theme Manager
                        .fullScreenCover(isPresented: $authManager.requiresOnboarding) {
                            AcademicOnboardingView()
                                .environmentObject(authManager)
                                .environmentObject(calendarManager)
                        }
                } else {
                    SignInView()
                        .environmentObject(authManager)
                }
            }
        }
        .preferredColorScheme(darkModeEnabled ? .dark : .light)
        .tint(themeManager.selectedTheme.accentColor) // Apply Global Accent Color
        .onAppear {
            if isFirstLaunch {
                isFirstLaunch = false
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
            
            TasksView()
                .tabItem {
                    Image(systemName: "checklist")
                    Text("Tasks")
                }
            
            SubjectsView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Subjects")
                }
            
            SettingsDashboardView()
                .tabItem {
                    Image(systemName: "ellipsis")
                    Text("More")
                }
        }
        .tint(themeManager.selectedTheme.accentColor)
    }
}
