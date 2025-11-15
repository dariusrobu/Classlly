//
//  ContentView.swift
//  Classlly
//
//  Created by Robu Darius on 14.11.2025.
//


// File: Classlly/Views/ContentView.swift
// Note: This is the root view of the app. It handles switching
// between the SignInView and the MainTabView based on the
// authentication state. It also manages the onboarding flow.

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var calendarManager: AcademicCalendarManager
    @EnvironmentObject var themeManager: AppTheme // Make sure this is here

    @AppStorage("isFirstLaunch") private var isFirstLaunch: Bool = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = false
    
    public init() {}
    
    var body: some View {
        // --- 1. WRAP IN ZSTACK ---
        ZStack {
            // --- 2. SET GLOBAL "OFF-BLACK" BACKGROUND ---
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
        .tint(themeManager.selectedTheme.accentColor) // Use the theme's accent color
        .onAppear {
            if isFirstLaunch {
                isFirstLaunch = false
            }
        }
    }
}

// --- 3. REVERTED TAB BAR ---
struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var themeManager: AppTheme // Make sure this is here
    
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
                    Text("Calendar") // Back to "Calendar"
                }
            
            TasksView()
                .tabItem {
                    Image(systemName: "checklist")
                    Text("Tasks")
                }
            
            Classlly.SubjectsView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Subjects")
                }
            
            SettingsDashboardView()
                .tabItem {
                    Image(systemName: "ellipsis") // Back to "ellipsis"
                    Text("More") // Back to "More"
                }
        }
        .tint(themeManager.selectedTheme.accentColor)
    }
}