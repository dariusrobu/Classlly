import SwiftUI

struct MainTabView: View {
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

// MARK: - 🏠 STANDARD TAB BAR (Native)
struct StandardTabBarView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
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
            
            // Added More Tab here too for consistency
            SettingsDashboardView()
                .tabItem { Label("More", systemImage: "ellipsis") }
                .tag(4)
        }
        .tint(themeManager.selectedTheme.primaryColor)
    }
}

// MARK: - 🌈 RAINBOW TAB BAR (Custom Floating)
struct RainbowTabBarView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 1. Content Layer
            Group {
                switch selectedTab {
                case 0: HomeView()
                case 1: CalendarView()
                case 2: SubjectsView(embedInNavigationStack: true)
                case 3: TasksView()
                case 4: SettingsDashboardView() // ✅ Added More/Settings View
                default: HomeView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 2. Floating Tab Bar Layer
            HStack(spacing: 0) {
                RainbowTabButton(icon: "house.fill", label: "Home", isSelected: selectedTab == 0, color: RainbowColors.blue) { selectedTab = 0 }
                Spacer()
                RainbowTabButton(icon: "calendar", label: "Sched", isSelected: selectedTab == 1, color: RainbowColors.green) { selectedTab = 1 }
                Spacer()
                RainbowTabButton(icon: "book.fill", label: "Subs", isSelected: selectedTab == 2, color: RainbowColors.orange) { selectedTab = 2 }
                Spacer()
                RainbowTabButton(icon: "checklist", label: "Tasks", isSelected: selectedTab == 3, color: RainbowColors.purple) { selectedTab = 3 }
                Spacer()
                // ✅ Added "More" Button
                RainbowTabButton(icon: "ellipsis", label: "More", isSelected: selectedTab == 4, color: .gray) { selectedTab = 4 }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(white: 0.1).opacity(0.95))
            .background(.ultraThinMaterial)
            .cornerRadius(35)
            .overlay(
                RoundedRectangle(cornerRadius: 35)
                    .stroke(LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.4), radius: 10, y: 5)
            .padding(.horizontal, 20)
            .padding(.bottom, 10) // Safe Area margin
        }
        .ignoresSafeArea(.keyboard)
    }
}

// Helper for Rainbow Tab Button
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
                    .shadow(color: isSelected ? color.opacity(0.6) : .clear, radius: 8)
                
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .frame(width: 50)
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
    }
}
