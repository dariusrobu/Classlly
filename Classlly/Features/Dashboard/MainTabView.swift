import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var themeManager: AppTheme
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if themeManager.selectedGameMode == .rainbow {
                RainbowTabBarView(selectedTab: $selectedTab)
            } else {
                StandardTabBarView(selectedTab: $selectedTab)
            }
        }
    }
}

// MARK: - 🏠 STANDARD TAB BAR
struct StandardTabBarView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var themeManager: AppTheme
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(profile: authManager.currentUser)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            
            CalendarView()
                .tabItem { Label("Schedule", systemImage: "calendar") }
                .tag(1)
            
            SubjectsView(embedInNavigationStack: true)
                .tabItem { Label("Subjects", systemImage: "book.closed.fill") }
                .tag(2)
            
            TasksView()
                .tabItem { Label("Tasks", systemImage: "checklist") }
                .tag(3)
            
            MoreView()
                .tabItem { Label("More", systemImage: "ellipsis") }
                .tag(4)
        }
        .tint(themeManager.selectedTheme.primaryColor)
    }
}

// MARK: - 🌈 RAINBOW TAB BAR
struct RainbowTabBarView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var themeManager: AppTheme
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content Layer
            Group {
                switch selectedTab {
                case 0: HomeView(profile: authManager.currentUser)
                case 1: CalendarView()
                case 2: SubjectsView(embedInNavigationStack: true)
                case 3: TasksView()
                case 4: MoreView()
                default: HomeView(profile: authManager.currentUser)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // ✅ UPDATED: Full-Width Custom Tab Bar
            VStack(spacing: 0) {
                // Top Border
                Rectangle()
                    .fill(Color(white: 0.2))
                    .frame(height: 1)
                
                HStack(spacing: 0) {
                    RainbowTabButton(icon: "house.fill", label: "Home", isSelected: selectedTab == 0, color: .blue) { selectedTab = 0 }
                    Spacer()
                    RainbowTabButton(icon: "calendar", label: "Sched", isSelected: selectedTab == 1, color: .green) { selectedTab = 1 }
                    Spacer()
                    RainbowTabButton(icon: "book.fill", label: "Subs", isSelected: selectedTab == 2, color: .orange) { selectedTab = 2 }
                    Spacer()
                    RainbowTabButton(icon: "checklist", label: "Tasks", isSelected: selectedTab == 3, color: .purple) { selectedTab = 3 }
                    Spacer()
                    RainbowTabButton(icon: "ellipsis", label: "More", isSelected: selectedTab == 4, color: .white) { selectedTab = 4 }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 34) // Extra padding for Home Indicator
                .background(Color.black.opacity(0.95)) // Solid dark background
                .background(.ultraThinMaterial) // Blur effect
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct RainbowTabButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .black : .medium))
                    .foregroundColor(isSelected ? color : .gray)
                
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .frame(maxWidth: .infinity) // Ensures even spacing
            .contentShape(Rectangle())
        }
    }
}
