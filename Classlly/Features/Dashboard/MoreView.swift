import SwiftUI
import SwiftData

struct MoreView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @EnvironmentObject var themeManager: AppTheme
    @Query private var profiles: [StudentProfile]
    
    private var currentProfile: StudentProfile? {
        profiles.first
    }
    
    var body: some View {
        NavigationStack {
            Group {
                switch themeManager.selectedGameMode {
                case .rainbow:
                    RainbowMoreView(profile: currentProfile, authManager: authManager)
                case .standard:
                    StandardMoreView(profile: currentProfile, authManager: authManager)
                }
            }
        }
    }
}

// MARK: - 🌈 RAINBOW MORE VIEW (Dark Mode / Card Style)
struct RainbowMoreView: View {
    let profile: StudentProfile?
    var authManager: AuthenticationManager
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        let accent = themeManager.selectedTheme.primaryColor
        
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            RadialGradient(colors: [accent.opacity(0.15), .black], center: .topLeading, startRadius: 0, endRadius: 600).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // 1. Profile Card with Gradient Border
                    NavigationLink(destination: ProfileView()) {
                        HStack(spacing: 16) {
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [accent, RainbowColors.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 70, height: 70)
                                    .shadow(color: accent.opacity(0.5), radius: 10, x: 0, y: 4)
                                
                                if let data = profile?.profileImageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 66, height: 66)
                                        .clipShape(Circle())
                                } else {
                                    Text(profile?.name.prefix(1).uppercased() ?? "S")
                                        .font(.title).fontWeight(.black)
                                        .foregroundColor(.white)
                                }
                            }
                            
                            // Text Info
                            VStack(alignment: .leading, spacing: 4) {
                                Text(profile?.name ?? "Student Name")
                                    .font(.title2).fontWeight(.black) // Bolder
                                    .foregroundColor(.white)
                                
                                Text(profile?.email ?? authManager.userSession?.email ?? "student@classlly.com")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                if let uni = profile?.university, !uni.isEmpty {
                                    Text(uni.uppercased())
                                        .font(.caption).fontWeight(.heavy) // Bolder
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(accent.opacity(0.2)) // Colored background
                                        .foregroundColor(accent)
                                        .cornerRadius(6)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .fontWeight(.bold)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(20)
                        .background(Color(white: 0.1))
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    LinearGradient(colors: [accent.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: 2
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // 2. Menu Items
                    VStack(spacing: 4) {
                        MoreMenuItem(icon: "calendar.badge.clock", title: "Academic Calendar", color: RainbowColors.blue) {
                            AcademicCalendarSettingsView()
                        }
                        
                        Divider().background(Color.gray.opacity(0.2)).padding(.leading, 60)
                        
                        MoreMenuItem(icon: "gearshape.fill", title: "Settings", color: RainbowColors.orange) {
                            SettingsView()
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color(white: 0.1))
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.05), lineWidth: 1))
                    
                    // 3. Sign Out Button (Enhanced)
                    Button(action: {
                        withAnimation {
                            authManager.signOut()
                        }
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                        .font(.headline).fontWeight(.bold)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1)) // Red tint
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.red.opacity(0.3), lineWidth: 1))
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle("More")
        .navigationBarHidden(true)
    }
}

struct MoreMenuItem<Destination: View>: View {
    let icon: String
    let title: String
    let color: Color
    let destination: () -> Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(color.opacity(0.2)).frame(width: 40, height: 40)
                    Image(systemName: icon).foregroundColor(color).font(.system(size: 18, weight: .black))
                }
                
                Text(title)
                    .font(.body).fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption).fontWeight(.bold)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}


// MARK: - 👔 STANDARD MORE VIEW (Light Mode)
struct StandardMoreView: View {
    let profile: StudentProfile?
    var authManager: AuthenticationManager
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Profile Card
                    NavigationLink(destination: ProfileView()) {
                        HStack(spacing: 16) {
                            Circle()
                                .fill(themeManager.selectedTheme.primaryColor.opacity(0.1))
                                .frame(width: 60, height: 60)
                                .overlay {
                                    if let data = profile?.profileImageData, let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage).resizable().scaledToFill().clipShape(Circle())
                                    } else {
                                        Image(systemName: "person.fill")
                                            .font(.title2)
                                            .foregroundColor(themeManager.selectedTheme.primaryColor)
                                    }
                                }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(profile?.name ?? "Student Name")
                                    .font(.title3).fontWeight(.bold) // Bolder
                                    .foregroundColor(.primary)
                                Text(profile?.university ?? "University Student")
                                    .font(.subheadline).fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").fontWeight(.semibold).foregroundColor(.gray.opacity(0.5))
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Actions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("GENERAL")
                            .font(.caption).fontWeight(.black)
                            .foregroundColor(.secondary)
                            .padding(.leading, 8)
                        
                        VStack(spacing: 0) {
                            NavigationLink(destination: AcademicCalendarSettingsView()) {
                                ColorfulIconRow(icon: "calendar", color: .blue, title: "Academic Calendar")
                            }
                            Divider().padding(.leading, 56)
                            NavigationLink(destination: SettingsView()) {
                                ColorfulIconRow(icon: "gearshape.fill", color: .gray, title: "Settings")
                            }
                        }
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                    
                    // Sign Out
                    Button(action: { authManager.signOut() }) {
                        Text("Sign Out")
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("More")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Helper for Standard View
struct ColorfulIconRow: View {
    let icon: String
    let color: Color
    let title: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.body).fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption).fontWeight(.bold)
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(16)
    }
}

#Preview {
    MoreView()
        .environment(AuthenticationManager())
        .environmentObject(AppTheme.shared)
}
