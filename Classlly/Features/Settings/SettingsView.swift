import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .arcade:
                ArcadeSettingsView()
            case .retro:
                RetroSettingsView()
            case .rainbow:
                StandardSettingsView()
                    .preferredColorScheme(.dark)
            case .none:
                StandardSettingsView()
            }
        }
    }
}

// MARK: - 👔 STANDARD SETTINGS
struct StandardSettingsView: View {
    @EnvironmentObject var themeManager: AppTheme
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("autoSyncEnabled") private var autoSyncEnabled = true
    
    private let columns = [GridItem(.adaptive(minimum: 50, maximum: 60), spacing: 16)]
    
    var body: some View {
        Form {
            Section(header: Text("Experience")) {
                Picker("Interface Style", selection: $themeManager.selectedGameMode) {
                    ForEach(GameMode.allCases) { mode in
                        HStack { Image(systemName: mode.iconName); Text(mode.rawValue) }.tag(mode)
                    }
                }
                .pickerStyle(NavigationLinkPickerStyle())
            }
            
            Section(header: Text("Appearance")) {
                Toggle("Dark Mode", isOn: $darkModeEnabled)
                VStack(alignment: .leading, spacing: 16) {
                    Text("Accent Color").font(.caption).foregroundColor(.secondary).textCase(.uppercase)
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Theme.allCases) { theme in
                            ThemeCircle(theme: theme, isSelected: themeManager.selectedTheme == theme) {
                                themeManager.setTheme(theme)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Section(header: Text("Notifications")) {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                NavigationLink("Manage Notifications", destination: NotificationSettingsView())
            }
            
            Section(header: Text("Data")) {
                Toggle("Auto Sync", isOn: $autoSyncEnabled)
            }
        }
        .navigationTitle("Settings")
    }
}

// MARK: - 🕹️ ARCADE SETTINGS
struct ArcadeSettingsView: View {
    @EnvironmentObject var themeManager: AppTheme
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("autoSyncEnabled") private var autoSyncEnabled = true
    
    private let columns = [GridItem(.adaptive(minimum: 50, maximum: 60), spacing: 16)]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    ArcadeSection(title: "SYSTEM INTERFACE", color: .cyan) {
                        Picker("", selection: $themeManager.selectedGameMode) {
                            ForEach(GameMode.allCases) { mode in Text(mode.rawValue).tag(mode) }
                        }
                        .pickerStyle(.segmented).colorScheme(.dark)
                    }
                    
                    ArcadeSection(title: "VISUAL CORE", color: .purple) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(Theme.allCases) { theme in
                                ThemeCircle(theme: theme, isSelected: themeManager.selectedTheme == theme) {
                                    themeManager.setTheme(theme)
                                }
                            }
                        }
                    }
                    
                    ArcadeSection(title: "SYSTEM CONTROLS", color: .orange) {
                        ArcadeToggle(icon: "bell.fill", label: "NOTIFICATIONS", isOn: $notificationsEnabled)
                        ArcadeToggle(icon: "moon.fill", label: "DARK MODE", isOn: $darkModeEnabled)
                        ArcadeToggle(icon: "arrow.triangle.2.circlepath", label: "AUTO SYNC", isOn: $autoSyncEnabled)
                    }
                }.padding()
            }
        }
        .navigationTitle("System Config")
    }
}

struct ArcadeToggle: View {
    let icon: String; let label: String; @Binding var isOn: Bool
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(isOn ? .yellow : .gray)
            Text(label).font(.caption).fontWeight(.black).foregroundColor(.white)
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden().tint(.yellow)
        }.padding(8).background(Color.black).cornerRadius(8)
    }
}

// MARK: - 👾 RETRO SETTINGS
struct RetroSettingsView: View {
    @EnvironmentObject var themeManager: AppTheme
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("autoSyncEnabled") private var autoSyncEnabled = true
    
    private let columns = [GridItem(.adaptive(minimum: 50, maximum: 60), spacing: 16)]
    
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.05).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("> CONFIGURATION_MENU").font(.system(.headline, design: .monospaced)).foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("UI_MODE:").font(.caption).fontDesign(.monospaced).foregroundColor(.gray)
                        Picker("", selection: $themeManager.selectedGameMode) {
                            ForEach(GameMode.allCases) { mode in Text(mode.rawValue).tag(mode) }
                        }
                        .pickerStyle(.segmented).colorScheme(.dark)
                        .overlay(Rectangle().stroke(Color.green, lineWidth: 1))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("COLOR_PALETTE:").font(.caption).fontDesign(.monospaced).foregroundColor(.gray)
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(Theme.allCases) { theme in
                                ThemeCircle(theme: theme, isSelected: themeManager.selectedTheme == theme) {
                                    themeManager.setTheme(theme)
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("FLAGS:").font(.caption).fontDesign(.monospaced).foregroundColor(.gray)
                        RetroToggle(label: "ENABLE_NOTIFICATIONS", isOn: $notificationsEnabled)
                        RetroToggle(label: "DARK_MODE_OVERRIDE", isOn: $darkModeEnabled)
                        RetroToggle(label: "AUTO_SYNC_PROTOCOL", isOn: $autoSyncEnabled)
                    }
                }.padding()
            }
        }
        .navigationTitle("CONFIG.INI")
    }
}

struct RetroToggle: View {
    let label: String; @Binding var isOn: Bool
    var body: some View {
        HStack {
            Text(label).font(.system(.body, design: .monospaced)).foregroundColor(.green)
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden().tint(.green)
        }.padding(8).border(Color.green.opacity(0.3), width: 1)
    }
}

struct ThemeCircle: View {
    let theme: Theme; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Circle().fill(theme.primaryColor).frame(width: 36, height: 36)
            .overlay(Circle().stroke(Color.white, lineWidth: 2).padding(-2).opacity(isSelected ? 1 : 0))
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .onTapGesture(perform: action)
    }
}
