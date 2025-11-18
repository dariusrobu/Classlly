import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @EnvironmentObject var themeManager: AppTheme

    @AppStorage("isFirstLaunch") private var isFirstLaunch: Bool = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = false
    
    public init() {}
    
    var body: some View {
        ZStack {
            // --- BACKGROUND LAYER ---
            if themeManager.isGamified {
                GamifiedBackground(accentColor: themeManager.selectedTheme.accentColor)
                    .transition(.opacity.animation(.easeInOut))
            } else {
                Color.themeBackground
                    .ignoresSafeArea()
            }
            
            // --- CONTENT LAYER ---
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
        .preferredColorScheme(themeManager.isGamified ? .dark : (darkModeEnabled ? .dark : .light))
        .tint(themeManager.selectedTheme.accentColor)
        .onAppear {
            if isFirstLaunch { isFirstLaunch = false }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Image(systemName: "house.fill"); Text("Home") }
            
            CalendarView()
                .tabItem { Image(systemName: "calendar"); Text("Calendar") }
            
            NavigationView { TasksView() }
                .tabItem { Image(systemName: "checklist"); Text("Tasks") }
            
            NavigationView { SubjectsView() }
                .tabItem { Image(systemName: "book.fill"); Text("Subjects") }
            
            SettingsDashboardView()
                .tabItem { Image(systemName: "ellipsis"); Text("More") }
        }
        .tint(themeManager.selectedTheme.accentColor)
        // --- DYNAMIC BAR VISIBILITY ---
        // Only hide the bar backgrounds if Gamified Mode is ON
        .toolbarBackground(themeManager.isGamified ? .hidden : .visible, for: .tabBar)
        .toolbarBackground(themeManager.isGamified ? .hidden : .visible, for: .navigationBar)
    }
}

// MARK: - Gamified Background Component
struct GamifiedBackground: View {
    let accentColor: Color
    @State private var animate = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            GeometryReader { proxy in
                let size = proxy.size
                
                Circle()
                    .fill(accentColor)
                    .frame(width: size.width * 1.2, height: size.width * 1.2)
                    .blur(radius: 100)
                    .opacity(0.2)
                    .offset(x: -size.width * 0.2, y: -size.width * 0.5)
                
                Circle()
                    .fill(Color.purple)
                    .frame(width: size.width, height: size.width)
                    .blur(radius: 100)
                    .opacity(0.15)
                    .offset(
                        x: animate ? size.width * 0.1 : size.width * 0.3,
                        y: animate ? size.height * 0.3 : size.height * 0.5
                    )
            }
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}
