import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject var themeManager: AppTheme
    // StandardSettingsView uses these, so we just pass themeManager down
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .arcade:
                ArcadeSettingsView()
            case .rainbow:
                StandardSettingsView()
            case .none:
                StandardSettingsView()
            }
        }
    }
}

// MARK: - 👔 STANDARD SETTINGS
struct StandardSettingsView: View {
    @EnvironmentObject var themeManager: AppTheme
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.modelContext) var modelContext
    
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("autoSyncEnabled") private var autoSyncEnabled = true
    
    @State private var showingDataAlert = false
    @State private var alertMessage = ""
    
    private let columns = [GridItem(.adaptive(minimum: 50, maximum: 60), spacing: 16)]
    
    var body: some View {
        Form {
            if let student = authManager.currentUser {
                Section(header: Text("Account")) {
                    NavigationLink(destination: ProfileView(profile: student)) {
                        Label("Edit Profile", systemImage: "person.circle")
                    }
                    
                    Button(action: {
                        authManager.signOut()
                    }) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
            }
            
            Section(header: Text("Experience")) {
                Picker("Interface Style", selection: $themeManager.selectedGameMode) {
                    ForEach(GameMode.allCases) { mode in
                        HStack { Image(systemName: mode.iconName); Text(mode.rawValue) }.tag(mode)
                    }
                }
                .pickerStyle(NavigationLinkPickerStyle())
            }
            
            Section(header: Text("Appearance")) {
                Toggle("Dark Mode", isOn: $themeManager.darkModeEnabled)
                
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
                NavigationLink("Academic Calendar", destination: AcademicCalendarSettingsView())
            }
            
            Section(header: Text("Data")) {
                Toggle("Auto Sync", isOn: $autoSyncEnabled)
            }
            
            Section(header: Text("Developer Options")) {
                NavigationLink(destination: NotificationDebugView()) {
                    Label {
                        Text("Notification Lab")
                    } icon: {
                        Image(systemName: "ant.fill")
                            .foregroundColor(.purple)
                    }
                }
                
                // ✅ UPDATED: Keeps profile when reloading data
                Button("Load Heavy Stress Data") {
                    DemoDataManager.shared.createHeavyStressData(
                        modelContext: modelContext,
                        cleanFirst: true,
                        keepProfile: true
                    )
                    alertMessage = "Heavy stress test data loaded! (Profile kept)"
                    showingDataAlert = true
                }
                .foregroundColor(.blue)
                
                Button("Clear All Data", role: .destructive) {
                    DemoDataManager.shared.deleteAllData(modelContext: modelContext, includeProfile: true)
                    authManager.signOut() // Sign out since we deleted the profile
                    alertMessage = "All data cleared."
                    showingDataAlert = true
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Data Operation", isPresented: $showingDataAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}

// MARK: - 🕹️ ARCADE SETTINGS
// (Ensure ArcadeSettingsView is also updated or just leave as is if you don't use it frequently)
struct ArcadeSettingsView: View {
    @EnvironmentObject var themeManager: AppTheme
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
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
                        ArcadeToggle(icon: "moon.fill", label: "DARK MODE", isOn: $themeManager.darkModeEnabled)
                        ArcadeToggle(icon: "arrow.triangle.2.circlepath", label: "AUTO SYNC", isOn: $autoSyncEnabled)
                    }
                    
                    NavigationLink(destination: NotificationDebugView()) {
                        HStack {
                            Image(systemName: "ant.fill").foregroundColor(.red)
                            Text("DEBUG PROTOCOL").font(.custom("Courier", size: 16)).fontWeight(.bold).foregroundColor(.red)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.black)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red, lineWidth: 2))
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

struct ThemeCircle: View {
    let theme: Theme; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Circle().fill(theme.primaryColor).frame(width: 36, height: 36)
            .overlay(Circle().stroke(Color.white, lineWidth: 2).padding(-2).opacity(isSelected ? 1 : 0))
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .onTapGesture(perform: action)
    }
}
