import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .rainbow:
                AnyView(RainbowInAppSettingsView())
            case .standard:
                AnyView(StandardSettingsView())
            }
        }
    }
}

// MARK: - 🌈 RAINBOW IN-APP SETTINGS
struct RainbowInAppSettingsView: View {
    @EnvironmentObject var themeManager: AppTheme
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("autoSyncEnabled") private var autoSyncEnabled = true
    
    @State private var showingDataAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        let accent = themeManager.selectedTheme.primaryColor
        
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left").font(.title3).foregroundColor(.white).padding(10).background(Color(white: 0.15)).clipShape(Circle())
                        }
                        Text("SETTINGS").font(.system(size: 28, weight: .black, design: .rounded)).foregroundColor(.white)
                        Spacer()
                    }.padding(.horizontal).padding(.top, 10)
                    
                    RainbowSettingsSection(title: "EXPERIENCE") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("INTERFACE STYLE").font(.caption).fontWeight(.bold).foregroundColor(.gray)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(GameMode.allCases) { mode in
                                        Button(action: { withAnimation { themeManager.selectedGameMode = mode } }) {
                                            VStack {
                                                Image(systemName: mode.iconName).font(.title2)
                                                Text(mode.rawValue).font(.caption).fontWeight(.bold)
                                            }
                                            .foregroundColor(themeManager.selectedGameMode == mode ? .black : .white)
                                            .frame(width: 90, height: 80)
                                            .background(themeManager.selectedGameMode == mode ? accent : Color(white: 0.15))
                                            .cornerRadius(16)
                                        }
                                    }
                                }
                            }
                        }
                        Divider().background(Color(white: 0.2))
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ACCENT COLOR").font(.caption).fontWeight(.bold).foregroundColor(.gray)
                            HStack(spacing: 16) {
                                ForEach(Theme.allCases) { theme in
                                    Circle()
                                        .fill(theme.primaryColor)
                                        .frame(width: 40, height: 40)
                                        .overlay(Circle().stroke(Color.white, lineWidth: themeManager.selectedTheme == theme ? 3 : 0))
                                        .onTapGesture { withAnimation { themeManager.setTheme(theme) } }
                                }
                            }
                        }
                    }
                    
                    RainbowSettingsSection(title: "SYSTEM") {
                        RainbowToggle(label: "Notifications", icon: "bell.fill", color: .red, isOn: $notificationsEnabled)
                        RainbowToggle(label: "Dark Mode", icon: "moon.fill", color: .purple, isOn: $themeManager.darkModeEnabled)
                        RainbowToggle(label: "Auto Sync", icon: "arrow.triangle.2.circlepath", color: .blue, isOn: $autoSyncEnabled)
                    }
                    
                    RainbowSettingsSection(title: "DATA & DEV") {
                        Button(action: {
                            DemoDataManager.shared.createHeavyStressData(modelContext: modelContext, cleanFirst: true, keepProfile: true)
                            alertMessage = "Stress data loaded!"; showingDataAlert = true
                        }) { RainbowRowLabel(text: "Load Demo Data", icon: "arrow.down.doc.fill", color: .orange) }
                        
                        Divider().background(Color(white: 0.2))
                        
                        Button(action: {
                            DemoDataManager.shared.deleteAllData(modelContext: modelContext, includeProfile: true)
                            authManager.signOut()
                        }) { RainbowRowLabel(text: "Clear All Data", icon: "trash.fill", color: .red) }
                    }
                    Spacer(minLength: 50)
                }.padding(.bottom)
            }
        }
        .navigationBarHidden(true)
        .alert("Data", isPresented: $showingDataAlert) { Button("OK", role: .cancel) { } } message: { Text(alertMessage) }
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
            // ✅ Removed Account Section
            
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
            }
            
            Section(header: Text("Appearance")) {
                Toggle("Dark Mode", isOn: $themeManager.darkModeEnabled)
                VStack(alignment: .leading, spacing: 16) {
                    Text("Accent Color").font(.caption).foregroundColor(.secondary).textCase(.uppercase)
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Theme.allCases) { theme in
                            ThemeCircle(theme: theme, isSelected: themeManager.selectedTheme == theme) { themeManager.setTheme(theme) }
                        }
                    }.padding(.vertical, 8)
                }
            }
            
            Section(header: Text("System")) {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                Toggle("Auto Sync", isOn: $autoSyncEnabled)
                NavigationLink("Academic Calendar", destination: AcademicCalendarSettingsView())
            }
            
            Section(header: Text("Developer")) {
                Button("Load Heavy Stress Data") {
                    DemoDataManager.shared.createHeavyStressData(modelContext: modelContext, cleanFirst: true, keepProfile: true)
                    alertMessage = "Data loaded!"
                    showingDataAlert = true
                }.foregroundColor(.blue)
                
                Button("Clear All Data", role: .destructive) {
                    DemoDataManager.shared.deleteAllData(modelContext: modelContext, includeProfile: true)
                    authManager.signOut()
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Data", isPresented: $showingDataAlert) { Button("OK", role: .cancel) { } } message: { Text(alertMessage) }
    }
}

// Shared Helpers
struct RainbowSettingsSection<Content: View>: View {
    let title: String; let content: Content
    init(title: String, @ViewBuilder content: () -> Content) { self.title = title; self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title).font(.caption).fontWeight(.black).foregroundColor(.gray).padding(.horizontal)
            VStack(alignment: .leading, spacing: 20) { content }
                .padding(20).background(Color(white: 0.1)).cornerRadius(24).padding(.horizontal)
        }
    }
}

struct RainbowToggle: View {
    let label: String; let icon: String; let color: Color; @Binding var isOn: Bool
    var body: some View {
        HStack { Image(systemName: icon).foregroundColor(color).frame(width: 24); Text(label).fontWeight(.bold).foregroundColor(.white); Spacer(); Toggle("", isOn: $isOn).labelsHidden().tint(color) }
    }
}

struct RainbowRowLabel: View {
    let text: String; let icon: String; let color: Color
    var body: some View {
        HStack { Image(systemName: icon).foregroundColor(color).frame(width: 24); Text(text).fontWeight(.bold).foregroundColor(.white); Spacer(); Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray) }
    }
}

struct ThemeCircle: View {
    let theme: Theme; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Circle().fill(theme.primaryColor).frame(width: 36, height: 36).overlay(Circle().stroke(Color.white, lineWidth: 2).padding(-2).opacity(isSelected ? 1 : 0)).scaleEffect(isSelected ? 1.1 : 1.0).onTapGesture(perform: action)
    }
}
