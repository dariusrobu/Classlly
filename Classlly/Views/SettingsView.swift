import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var themeManager: AppTheme
    
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    
    public init() {}
    
    var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                Toggle("Dark Mode", isOn: $darkModeEnabled)
            }
            .listRowBackground(Color.themeSurface)
            
            Section(header: Text("Gamification & Theme")) {
                Toggle(isOn: $themeManager.isGamified) {
                    HStack {
                        Image(systemName: "gamecontroller.fill")
                            .foregroundColor(themeManager.selectedTheme.accentColor)
                        Text("Gamified Mode")
                        Spacer()
                        if themeManager.isGamified {
                            Text("ON")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.selectedTheme.accentColor)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Accent Color")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 12) {
                        ForEach(Theme.allCases) { theme in
                            Circle()
                                .fill(theme.accentColor)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: themeManager.selectedTheme == theme ? 3 : 0)
                                )
                                .onTapGesture {
                                    withAnimation {
                                        themeManager.selectedTheme = theme
                                    }
                                }
                        }
                    }
                    .padding(.bottom, 8)
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
        }
        .scrollContentBackground(.hidden) // UPDATED: Allows background to show
        .background(Color.clear) // UPDATED: Ensure container is clear
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
