import SwiftUI

struct SettingsDashboardView: View {
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .rainbow:
                RainbowSettingsView()
            case .arcade:
                ArcadeSettingsView()
            case .none:
                StandardSettingsView()
            }
        }
    }
}

// MARK: - 🌈 RAINBOW SETTINGS
struct RainbowSettingsView: View {
    @EnvironmentObject var themeManager: AppTheme
    @State private var showThemeSheet = false
    
    var body: some View {
        let accent = themeManager.selectedTheme.primaryColor
        
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SYSTEM").font(.system(size: 10, weight: .black)).foregroundColor(accent).tracking(2)
                                Text("CONFIG").font(.system(size: 34, weight: .black)).foregroundColor(.white)
                            }
                            Spacer()
                            Image(systemName: "gearshape.fill").font(.largeTitle).foregroundColor(Color(white: 0.2))
                        }
                        .padding(.horizontal).padding(.top, 10)
                        
                        // 2. Profile Card
                        NavigationLink(destination: ProfileView()) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle().fill(accent.opacity(0.2)).frame(width: 60, height: 60)
                                    Image(systemName: "person.fill").font(.title2).foregroundColor(accent)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("USER PROFILE").font(.headline).fontWeight(.black).foregroundColor(.white)
                                    Text("Edit details & preferences").font(.caption).foregroundColor(.gray)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(white: 0.1))
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(accent.opacity(0.3), lineWidth: 1))
                        }
                        .padding(.horizontal)
                        
                        // 3. Settings Sections
                        VStack(spacing: 16) {
                            RainbowSectionHeader(title: "INTERFACE", color: RainbowColors.blue)
                            RainbowSettingRow(icon: "paintpalette.fill", title: "Theme Color", color: RainbowColors.blue) { showThemeSheet = true }
                            RainbowGameModePicker()
                            
                            RainbowSectionHeader(title: "ACADEMIC", color: RainbowColors.green)
                            NavigationLink(destination: AcademicCalendarSettingsView()) {
                                RainbowSettingRowContent(icon: "calendar", title: "Academic Calendar", color: RainbowColors.green)
                            }
                            
                            RainbowSectionHeader(title: "DATA", color: RainbowColors.red)
                            RainbowSettingRowContent(icon: "arrow.down.doc.fill", title: "Export Data", color: RainbowColors.red)
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 50)
                        
                        Text("CLASSLLY v1.0").font(.caption).fontWeight(.bold).foregroundColor(Color(white: 0.2)).padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showThemeSheet) { ThemeSelectionSheet() }
        }
    }
}

// MARK: - 🌈 RAINBOW COMPONENTS
struct RainbowSectionHeader: View {
    let title: String; let color: Color
    var body: some View {
        HStack {
            Rectangle().fill(color).frame(width: 4, height: 16)
            Text(title).font(.caption).fontWeight(.black).foregroundColor(color).tracking(1)
            Spacer()
        }.padding(.top, 8)
    }
}

struct RainbowSettingRowContent: View {
    let icon: String; let title: String; let color: Color
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(color).frame(width: 24)
            Text(title).fontWeight(.bold).foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(Color(white: 0.3))
        }.padding().background(Color(white: 0.1)).cornerRadius(12)
    }
}

struct RainbowSettingRow: View {
    let icon: String; let title: String; let color: Color; let action: () -> Void
    var body: some View { Button(action: action) { RainbowSettingRowContent(icon: icon, title: title, color: color) } }
}

struct RainbowGameModePicker: View {
    @EnvironmentObject var themeManager: AppTheme
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("INTERFACE MODE").font(.caption).fontWeight(.bold).foregroundColor(.gray)
            HStack(spacing: 12) {
                ModeButton(mode: .none, label: "Std", icon: "iphone")
                ModeButton(mode: .rainbow, label: "Neon", icon: "paintpalette.fill")
                ModeButton(mode: .arcade, label: "Game", icon: "gamecontroller.fill")
            }
        }.padding().background(Color(white: 0.08)).cornerRadius(16)
    }
    
    @ViewBuilder func ModeButton(mode: GameMode, label: String, icon: String) -> some View {
        let isSelected = themeManager.selectedGameMode == mode
        Button(action: { withAnimation { themeManager.selectedGameMode = mode } }) {
            VStack { Image(systemName: icon).font(.title2); Text(label).font(.caption).fontWeight(.bold) }
                .foregroundColor(isSelected ? .black : .white)
                .frame(maxWidth: .infinity).frame(height: 70)
                .background(isSelected ? themeManager.selectedTheme.primaryColor : Color(white: 0.15))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.white : Color.clear, lineWidth: 2))
        }
    }
}

// MARK: - 🏠 STANDARD SETTINGS
struct StandardSettingsView: View {
    @EnvironmentObject var themeManager: AppTheme
    @State private var showThemeSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                Section { NavigationLink(destination: ProfileView()) { Label("Profile", systemImage: "person.circle") } }
                Section("Appearance") {
                    Button(action: { showThemeSheet = true }) { Label("Theme Color", systemImage: "paintpalette") }
                    Picker("Interface Style", selection: $themeManager.selectedGameMode) {
                        Text("Standard").tag(GameMode.none); Text("Rainbow").tag(GameMode.rainbow); Text("Arcade").tag(GameMode.arcade)
                    }
                }
                Section("Academic") { NavigationLink(destination: AcademicCalendarSettingsView()) { Label("Academic Calendar", systemImage: "calendar") } }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showThemeSheet) { ThemeSelectionSheet() }
        }
    }
}

// MARK: - 🕹️ ARCADE SETTINGS (Stub)
struct ArcadeSettingsView: View {
    var body: some View { ZStack { Color.black.ignoresSafeArea(); Text("Arcade Config").font(.largeTitle).foregroundColor(.cyan) } }
}

// MARK: - 🎨 THEME SELECTION SHEET (Missing Component)
struct ThemeSelectionSheet: View {
    @EnvironmentObject var themeManager: AppTheme
    @Environment(\.dismiss) var dismiss
    
    let colors: [Color] = [.blue, .purple, .pink, .red, .orange, .yellow, .green, .mint, .teal, .cyan, .indigo]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 20) {
                    ForEach(colors, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                    .opacity(themeManager.selectedTheme.primaryColor == color ? 1 : 0)
                            )
                            .onTapGesture {
                                // Update logic depends on how AppTheme is structured.
                                // Assuming we can set the primary color or a theme struct.
                                themeManager.selectedTheme = AppTheme.Theme(primaryColor: color, secondaryColor: .gray)
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Select Theme Color")
            .toolbar { Button("Done") { dismiss() } }
        }
        .presentationDetents([.medium])
    }
}
