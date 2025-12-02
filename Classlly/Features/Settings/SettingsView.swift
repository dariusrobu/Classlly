import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: AppTheme
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("autoSyncEnabled") private var autoSyncEnabled = true
    
    private let columns = [
        GridItem(.adaptive(minimum: 50, maximum: 60), spacing: 16)
    ]
    
    var body: some View {
        Form {
            // MARK: - NEW EXPERIENCE SECTION
            Section(header: Text("Experience")) {
                Picker("Interface Style", selection: $themeManager.selectedGameMode) {
                    ForEach(GameMode.allCases) { mode in
                        HStack {
                            Image(systemName: mode.iconName)
                            Text(mode.rawValue)
                        }
                        .tag(mode)
                    }
                }
                .pickerStyle(NavigationLinkPickerStyle())
                
                // Info text
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text(themeManager.selectedGameMode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .listRowBackground(Color.themeSurface)
            
            Section(header: Text("Appearance")) {
                Toggle("Dark Mode", isOn: $darkModeEnabled)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Accent Color")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Theme.allCases) { theme in
                            let isSelected = themeManager.selectedTheme == theme
                            
                            Circle()
                                .fill(theme.primaryColor)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(Color.themeBackground, lineWidth: 2)
                                        .padding(-2)
                                        .overlay(
                                            Circle()
                                                .stroke(isSelected ? theme.primaryColor : Color.clear, lineWidth: 2)
                                                .padding(-5)
                                        )
                                )
                                .shadow(color: theme.primaryColor.opacity(0.2), radius: 3, x: 0, y: 2)
                                .scaleEffect(isSelected ? 1.1 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                                .onTapGesture {
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                    themeManager.setTheme(theme)
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
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
