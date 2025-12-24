import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject var themeManager: AppTheme
    @Environment(AuthenticationManager.self) private var authManager
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .rainbow:
                RainbowSettingsView(authManager: authManager)
            case .standard:
                StandardSettingsView(authManager: authManager)
            }
        }
    }
}

// MARK: - 🌈 RAINBOW SETTINGS VIEW
struct RainbowSettingsView: View {
    @EnvironmentObject var themeManager: AppTheme
    var authManager: AuthenticationManager
    
    var body: some View {
        let accent = themeManager.selectedTheme.primaryColor
        
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            RadialGradient(colors: [accent.opacity(0.15), .black], center: .topLeading, startRadius: 0, endRadius: 600).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Text("SETTINGS")
                        .font(.headline).fontWeight(.black)
                        .foregroundColor(.white)
                        .tracking(1)
                    Spacer()
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Preferences Group
                        VStack(spacing: 12) {
                            Text("PREFERENCES")
                                .font(.caption).fontWeight(.black)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading)
                            
                            NavigationLink(destination: AppearanceSettingsView()) {
                                RainbowSettingsRow(icon: "paintpalette.fill", title: "Appearance", color: .pink)
                            }
                            
                            NavigationLink(destination: NotificationSettingsView()) {
                                RainbowSettingsRow(icon: "bell.fill", title: "Notifications", color: .red)
                            }
                        }
                        
                        // Account Group (Sign Out only)
                        VStack(spacing: 12) {
                            Text("ACCOUNT")
                                .font(.caption).fontWeight(.black)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading)
                            
                            Button(action: {
                                withAnimation { authManager.signOut() }
                            }) {
                                HStack {
                                    ZStack {
                                        Circle().fill(Color.red.opacity(0.2)).frame(width: 40, height: 40)
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .foregroundColor(.red)
                                    }
                                    Text("Sign Out")
                                        .fontWeight(.bold)
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                                .padding()
                                .background(Color(white: 0.1))
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05), lineWidth: 1))
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// Helper Row for Rainbow Settings
struct RainbowSettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(color.opacity(0.2)).frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)
            }
            
            Text(title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption).fontWeight(.bold)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }
}

// MARK: - 👔 STANDARD SETTINGS VIEW
struct StandardSettingsView: View {
    var authManager: AuthenticationManager
    
    var body: some View {
        List {
            Section("General") {
                NavigationLink(destination: AppearanceSettingsView()) {
                    Label("Appearance", systemImage: "paintpalette.fill")
                }
                NavigationLink(destination: NotificationSettingsView()) {
                    Label("Notifications", systemImage: "bell.fill")
                }
            }
            
            Section("Account") {
                if let email = authManager.userSession?.email {
                    LabeledContent("Email", value: email)
                }
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
            }
        }
        .navigationTitle("Settings")
    }
}

// MARK: - 🎨 APPEARANCE SETTINGS
struct AppearanceSettingsView: View {
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                
                // 1. Live Preview Section
                VStack(spacing: 16) {
                    Text("LIVE PREVIEW")
                        .font(.caption).fontWeight(.black)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading)
                    
                    ThemePreviewSection()
                        .padding(.horizontal)
                }
                
                // 2. Mode Selection
                VStack(spacing: 16) {
                    Text("DISPLAY MODE")
                        .font(.caption).fontWeight(.black)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading)
                    
                    HStack(spacing: 12) {
                        ModeCard(
                            title: "Standard",
                            icon: "book.closed.fill",
                            description: "Clean & Professional",
                            isSelected: themeManager.selectedGameMode == .standard
                        ) {
                            withAnimation { themeManager.selectedGameMode = .standard }
                        }
                        
                        ModeCard(
                            title: "Rainbow",
                            icon: "sparkles",
                            description: "Vibrant & Neon",
                            isSelected: themeManager.selectedGameMode == .rainbow
                        ) {
                            withAnimation { themeManager.selectedGameMode = .rainbow }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // 3. Color Theme
                VStack(spacing: 16) {
                    Text("ACCENT THEME")
                        .font(.caption).fontWeight(.black)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(Theme.allCases) { theme in
                                ThemeColorButton(theme: theme, isSelected: themeManager.selectedTheme == theme) {
                                    withAnimation { themeManager.selectedTheme = theme }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // 4. System Settings
                VStack(spacing: 16) {
                    Text("SYSTEM")
                        .font(.caption).fontWeight(.black)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading)
                    
                    Toggle(isOn: $themeManager.darkModeEnabled) {
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundStyle(themeManager.selectedTheme.primaryColor)
                            Text("Dark Mode")
                                .fontWeight(.medium)
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .disabled(themeManager.selectedGameMode == .rainbow)
                    .opacity(themeManager.selectedGameMode == .rainbow ? 0.6 : 1.0)
                }
                
                if themeManager.selectedGameMode == .rainbow {
                    Text("Note: Rainbow mode automatically enables Dark Mode for the best visual experience.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer(minLength: 50)
            }
            .padding(.vertical)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 🧩 PREVIEW COMPONENTS

struct ThemePreviewSection: View {
    @EnvironmentObject var themeManager: AppTheme
    // Fetch Real Data
    @Query private var profiles: [StudentProfile]
    @Query(sort: \Subject.title) private var subjects: [Subject]
    
    // Fallback data if DB is empty
    private var previewProfileName: String {
        profiles.first?.name ?? "Student Name"
    }
    
    private var previewSubject: Subject {
        if let first = subjects.first { return first }
        // Dummy subject for visual preview
        let s = Subject(title: "Mathematics", colorHex: "#FF5733")
        s.courseClassroom = "Room 302"
        return s
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header Mockup
            HStack {
                Circle()
                    .fill(themeManager.selectedGameMode == .rainbow ?
                          AnyShapeStyle(LinearGradient(colors: [themeManager.selectedTheme.primaryColor, themeManager.selectedTheme.secondaryColor], startPoint: .topLeading, endPoint: .bottomTrailing)) :
                            AnyShapeStyle(themeManager.selectedTheme.primaryColor.opacity(0.1)))
                    .frame(width: 40, height: 40)
                    .overlay {
                        if themeManager.selectedGameMode == .standard {
                            Image(systemName: "person.fill")
                                .foregroundStyle(themeManager.selectedTheme.primaryColor)
                        }
                    }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(themeManager.selectedGameMode == .rainbow ? "WELCOME BACK," : "Good Morning,")
                        .font(.caption).fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    Text(previewProfileName)
                        .font(.headline).fontWeight(.black)
                        .foregroundStyle(themeManager.selectedGameMode == .rainbow ? .white : .primary)
                }
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Card Mockup
            if themeManager.selectedGameMode == .rainbow {
                RainbowPreviewCard(subject: previewSubject, theme: themeManager.selectedTheme)
            } else {
                StandardPreviewCard(subject: previewSubject, theme: themeManager.selectedTheme)
            }
        }
        .padding(20)
        .background(themeManager.selectedGameMode == .rainbow ? Color.black : Color(uiColor: .systemGroupedBackground))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        // Force dark scheme for preview container if in rainbow mode
        .environment(\.colorScheme, themeManager.selectedGameMode == .rainbow ? .dark : (themeManager.darkModeEnabled ? .dark : .light))
    }
}

struct RainbowPreviewCard: View {
    let subject: Subject
    let theme: Theme
    
    var body: some View {
        // Use THEME color for the preview to show the user what they are selecting
        let primary = theme.primaryColor
        let secondary = theme.secondaryColor
        
        HStack(spacing: 16) {
            VStack {
                Text("NOW")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.white)
                Rectangle().fill(Color.white.opacity(0.5)).frame(width: 1)
            }
            .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(subject.title)
                    .font(.title3).fontWeight(.black)
                    .foregroundColor(.white)
                
                HStack {
                    Label(subject.courseClassroom, systemImage: "mappin.circle.fill")
                    Text("•")
                    Text("Lecture")
                }
                .font(.caption).fontWeight(.bold)
                .foregroundColor(.white.opacity(0.8))
            }
            Spacer()
        }
        .padding(20)
        .background(
            // 🌈 FIX: Use theme colors for gradient so live preview updates!
            LinearGradient(
                colors: [primary, secondary.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
        .shadow(color: primary.opacity(0.4), radius: 10, x: 0, y: 5)
    }
}

struct StandardPreviewCard: View {
    let subject: Subject
    let theme: Theme
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("Now")
                    .font(.title3).fontWeight(.bold)
                    .foregroundColor(.primary)
                Text("ends 12:00")
                    .font(.caption).foregroundColor(.secondary)
            }
            .frame(minWidth: 70)
            
            Rectangle().fill(Color.primary.opacity(0.1)).frame(width: 1, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(subject.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption)
                    Text(subject.courseClassroom)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            Spacer()
            
            Image(systemName: "book.fill")
                .font(.title2)
                // 👔 FIX: Use theme color for icon so live preview updates!
                .foregroundColor(theme.primaryColor)
        }
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct ModeCard: View {
    let title: String
    let icon: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(isSelected ? .white : .primary)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.white)
                    }
                }
                
                Spacer()
                
                Text(title)
                    .font(.headline).fontWeight(.bold)
                    .foregroundStyle(isSelected ? .white : .primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .padding(16)
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue : Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : Color.primary.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.black.opacity(0.05), radius: 10, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ThemeColorButton: View {
    let theme: Theme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.primaryColor, theme.secondaryColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: theme.primaryColor.opacity(0.4), radius: 5, y: 3)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 2)
                        .scaleEffect(1.2)
                        .opacity(isSelected ? 1 : 0)
                )
                
                Text(theme.rawValue)
                    .font(.caption2).fontWeight(.bold)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
        }
    }
}

struct ColorfulRow: View {
    let icon: String
    let color: Color
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color)
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            Text(title)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        SettingsView()
            .environmentObject(AppTheme.shared)
            .modelContainer(for: [StudentProfile.self, Subject.self, StudyTask.self], inMemory: true)
    }
}
