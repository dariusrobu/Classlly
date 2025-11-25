import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: AppTheme; @Environment(\.colorScheme) var colorScheme
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true; @AppStorage("darkModeEnabled") private var darkModeEnabled = false; @AppStorage("autoSyncEnabled") private var autoSyncEnabled = true
    public init() {}
    var body: some View {
        Form {
            Section(header: Text("Experience")) {
                Toggle(isOn: $themeManager.isGamified) {
                    HStack {
                        Image(systemName: "gamecontroller.fill").foregroundColor(themeManager.isGamified ? .orange : .gray)
                        VStack(alignment: .leading) { Text("Gamified Mode").font(.headline).foregroundColor(.themeTextPrimary); Text("Playful design & fun colors").font(.caption).foregroundColor(.themeTextSecondary) }
                    }
                }.tint(.orange)
            }.adaptiveListRow()
            Section(header: Text("Appearance")) {
                Picker("Theme Color", selection: $themeManager.selectedTheme) { ForEach(Theme.allCases) { theme in HStack { Circle().fill(theme.accentColor).frame(width: 20, height: 20); Text(theme.rawValue).foregroundColor(.themeTextPrimary) }.tag(theme) } }
                Toggle("Dark Mode", isOn: $darkModeEnabled)
            }.adaptiveListRow()
            Section(header: Text("Notifications")) {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                NavigationLink(destination: NotificationSettingsView()) { Text("Manage Notifications").foregroundColor(.themeTextPrimary) }
            }.adaptiveListRow()
            Section(header: Text("Data")) { Toggle("Auto Sync", isOn: $autoSyncEnabled) }.adaptiveListRow()
        }
        .scrollContentBackground(.hidden).background(Color.clear).navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
    }
}
