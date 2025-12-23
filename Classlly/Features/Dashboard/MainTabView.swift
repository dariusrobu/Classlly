import SwiftUI

struct MainTabView: View {
    // FIXED: Use modern Environment syntax
    @Environment(AuthenticationManager.self) private var authManager
    
    var body: some View {
        TabView {
            // Dashboard / Home
            Text("Dashboard (Placeholder)")
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            // Calendar / Schedule
            Text("Schedule (Placeholder)")
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
            
            // Tasks
            Text("Tasks (Placeholder)")
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
            
            // More / Settings
            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
        .environment(AuthenticationManager())
}
