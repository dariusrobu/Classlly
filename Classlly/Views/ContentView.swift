import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @EnvironmentObject var themeManager: AppTheme
    @Environment(\.modelContext) var modelContext // Needed to access DB

    @AppStorage("isFirstLaunch") private var isFirstLaunch: Bool = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = false
    
    public init() {}
    
    var body: some View {
        ZStack {
            Color.themeBackground
                .ignoresSafeArea()
            
            Group {
                if authManager.isAuthenticated {
                    MainTabView()
                        .environmentObject(authManager)
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
        .tint(themeManager.selectedTheme.accentColor)
        .onAppear {
            if isFirstLaunch {
                isFirstLaunch = false
            }
            // Trigger check against SwiftData/CloudKit
            authManager.checkAuthentication(modelContext: modelContext)
        }
    }
}

// ... (MainTabView remains unchanged)
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
