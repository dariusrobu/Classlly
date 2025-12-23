import SwiftUI

struct SettingsDashboardView: View {
    // MARK: - Environments
    @Environment(AuthenticationManager.self) private var authManager
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            List {
                // Account Section
                Section {
                    NavigationLink(destination: ProfileView()) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.title)
                                // FIXED: Use Color.accentColor instead of .accent
                                .foregroundStyle(Color.accentColor)
                            
                            VStack(alignment: .leading) {
                                Text(authManager.userSession?.fullName ?? "Student")
                                    .font(.headline)
                                Text("Manage Profile")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // General Settings
                Section("General") {
                    NavigationLink(destination: SettingsView()) {
                        Label("App Preferences", systemImage: "gear")
                    }
                    
                    NavigationLink(destination: Text("Notifications Placeholder")) {
                        Label("Notifications", systemImage: "bell.badge")
                    }
                    
                    NavigationLink(destination: Text("Appearance Placeholder")) {
                        Label("Appearance", systemImage: "paintbrush")
                    }
                }
                
                // Support & About
                Section("Support") {
                    Link(destination: URL(string: "https://apple.com")!) {
                        Label("Help Center", systemImage: "questionmark.circle")
                    }
                    
                    LabeledContent("Version", value: "1.0.0")
                }
                
                // Sign Out
                Section {
                    Button(role: .destructive) {
                        authManager.signOut()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Dashboard")
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsDashboardView()
        .environment(AuthenticationManager())
}
