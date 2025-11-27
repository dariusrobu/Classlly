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
    
    public init() {}
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            Group {
                if authManager.isAuthenticated {
                    if sizeClass == .regular {
                        // --- iPad: Single Dashboard Stack ---
                        NavigationStack {
                            HomeView()
                        }
                        .environmentObject(authManager)
                    } else {
                        // --- iPhone: Tab Bar Navigation ---
                        iPhoneTabView
                            .environmentObject(authManager)
                    }
                } else {
                    SignInView()
                        .environmentObject(authManager)
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
    
    // Separated iPhone Tab View for clarity
    var iPhoneTabView: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "house.fill") }
            
            NavigationStack { CalendarView() }
                .tabItem { Label("Calendar", systemImage: "calendar") }
            
            NavigationStack { TasksView() }
                .tabItem { Label("Tasks", systemImage: "checklist") }
            
            NavigationStack { SubjectsView() }
                .tabItem { Label("Subjects", systemImage: "book.fill") }
            
            NavigationStack { SettingsDashboardView() }
                .tabItem { Label("More", systemImage: "ellipsis") }
        }
    }
}
