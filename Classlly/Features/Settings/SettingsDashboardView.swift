import SwiftUI

struct SettingsDashboardView: View {
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .rainbow:
                RainbowSettingsView()
            case .arcade:
                // Uses the robust implementation from SettingsView.swift
                ArcadeSettingsView()
            case .none:
                // Uses the robust implementation from SettingsView.swift
                StandardSettingsView()
            }
        }
    }
}

// MARK: - 決 RAINBOW SETTINGS
struct RainbowSettingsView: View {
    @EnvironmentObject var themeManager: AppTheme
    @State private var showThemeSheet = false
    
    // Define RainbowColors locally if not available globally, or rely on global definition.
    // Assuming RainbowColors is defined in your Color extensions.
    // If not, we can use standard Colors as fallbacks.
    
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
                        // Note: Ensure RainbowColors struct exists in your project.
                        // If these throw errors, change 'RainbowColors.blue' to 'Color.blue', etc.
                        VStack(spacing: 16) {
                            RainbowSectionHeader(title: "INTERFACE", color: .blue)
                            RainbowSettingRow(icon: "paintpalette.fill", title: "Theme Color", color: .blue) { showThemeSheet = true }
                            RainbowGameModePicker()
                            
                            RainbowSectionHeader(title: "ACADEMIC", color: .green)
                            NavigationLink(destination: AcademicCalendarSettingsView()) {
                                RainbowSettingRowContent(icon: "calendar", title: "Academic Calendar", color: .green)
                            }
                            
                            RainbowSectionHeader(title: "DATA", color: .red)
                            RainbowSettingRowContent(icon: "arrow.down.doc.fill", title: "Export Data", color: .red)
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

// MARK: - 決 RAINBOW COMPONENTS
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

// MARK: - 耳 THEME SELECTION SHEET (FIXED)
struct ThemeSelectionSheet: View {
    @EnvironmentObject var themeManager: AppTheme
    @Environment(\.dismiss) var dismiss
    
    // Fix: Use the Enum cases directly instead of a raw Color array
    let themes = Theme.allCases
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 20) {
                    ForEach(themes) { theme in
                        Circle()
                            .fill(theme.primaryColor)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                    .opacity(themeManager.selectedTheme == theme ? 1 : 0)
                            )
                            .onTapGesture {
                                // Fix: Directly assign the Enum case
                                themeManager.selectedTheme = theme
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
