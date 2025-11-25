import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @EnvironmentObject var themeManager: AppTheme

    @AppStorage("isFirstLaunch") private var isFirstLaunch: Bool = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = false
    
    public init() {}
    
    var body: some View {
        ZStack {
            if themeManager.isGamified {
                GameColor.background.ignoresSafeArea()
            } else {
                Color.themeBackground.ignoresSafeArea()
            }
            
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
        .tint(themeManager.isGamified ? GameColor.electricBlue : themeManager.selectedTheme.accentColor)
        .onAppear {
            if isFirstLaunch { isFirstLaunch = false }
            updateTabBarAppearance()
        }
        .onChange(of: themeManager.isGamified) { _, _ in
            updateTabBarAppearance()
        }
    }
    
    private func updateTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        if themeManager.isGamified {
            appearance.backgroundColor = UIColor(GameColor.background)
            let systemFont = UIFont.systemFont(ofSize: 12, weight: .heavy)
            let font: UIFont
            if let descriptor = systemFont.fontDescriptor.withDesign(.rounded) {
                font = UIFont(descriptor: descriptor, size: 12)
            } else { font = systemFont }
            
            let textAttributes: [NSAttributedString.Key: Any] = [.font: font]
            let itemAppearance = UITabBarItemAppearance()
            itemAppearance.normal.titleTextAttributes = textAttributes
            itemAppearance.selected.titleTextAttributes = textAttributes
            
            appearance.stackedLayoutAppearance = itemAppearance
            appearance.inlineLayoutAppearance = itemAppearance
            appearance.compactInlineLayoutAppearance = itemAppearance
        } else {
            appearance.configureWithDefaultBackground()
        }
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        TabView {
            HomeView().tabItem { Image(systemName: "house.fill"); Text("Home") }
            CalendarView().tabItem { Image(systemName: "calendar"); Text("Calendar") }
            TasksView().tabItem { Image(systemName: "checklist"); Text("Tasks") }
            SubjectsView().tabItem { Image(systemName: "book.fill"); Text("Subjects") }
            SettingsDashboardView().tabItem { Image(systemName: "ellipsis"); Text("More") }
        }
        .tint(themeManager.isGamified ? GameColor.electricBlue : themeManager.selectedTheme.accentColor)
    }
}
