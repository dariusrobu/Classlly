import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var themeManager: AppTheme // ✅ Access the Theme Manager
    
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("autoSyncEnabled") private var autoSyncEnabled = true
    @AppStorage("isGamifiedMode") private var isGamifiedMode = false
    
    public init() {}
    
    var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                Toggle("Dark Mode", isOn: $darkModeEnabled)
                
                // Gamified Mode Toggle
                Toggle(isOn: $isGamifiedMode) {
                    HStack {
                        Image(systemName: "gamecontroller.fill")
                            .foregroundColor(themeManager.selectedTheme.accentColor)
                        Text("Gamified Dashboard")
                    }
                }
                
                // ✅ Theme Color Picker
                Picker("App Theme", selection: $themeManager.selectedTheme) {
                    ForEach(Theme.allCases) { theme in
                        HStack {
                            Circle()
                                .fill(theme.accentColor)
                                .frame(width: 16, height: 16)
                            Text(theme.rawValue)
                        }
                        .tag(theme)
                    }
                }
                .pickerStyle(.navigationLink)
            }
            .listRowBackground(Color.themeSurface)
            
            Section(header: Text("Notifications")) {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                NavigationLink(destination: NotificationSettingsView()) {
                    Text("Manage Notifications")
                }
            }
            .listRowBackground(Color.themeSurface)

            Section(header: Text("Data")) {
                Toggle("Auto Sync", isOn: $autoSyncEnabled)
            }
            .listRowBackground(Color.themeSurface)
        }
        .scrollContentBackground(.hidden)
        .background(Color.themeBackground)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
