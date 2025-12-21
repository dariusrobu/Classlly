import SwiftUI
import SwiftData

struct MoreView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var themeManager: AppTheme
    @Environment(\.modelContext) var modelContext
    
    // Fetch profile for editing
    @Query private var profiles: [StudentProfile]
    @State private var showingProfileEdit = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - 🎨 RAINBOW BACKGROUND
                if themeManager.selectedGameMode == .rainbow {
                    let accent = themeManager.selectedTheme.primaryColor
                    Color.black.ignoresSafeArea()
                    RadialGradient(colors: [accent.opacity(0.3), .black], center: .topTrailing, startRadius: 0, endRadius: 600)
                        .ignoresSafeArea()
                } else if themeManager.selectedGameMode == .arcade {
                    Color.black.ignoresSafeArea()
                } else {
                    Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                }
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Profile Header
                        Button(action: {
                            if !profiles.isEmpty { showingProfileEdit = true }
                        }) {
                            RainbowProfileCard(user: profiles.first)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 10)
                        
                        // 2. Navigation Group
                        VStack(spacing: 16) {
                            RainbowNavigationCard(
                                title: "Academic Calendar",
                                subtitle: "Manage your semesters",
                                icon: "calendar.badge.clock",
                                color: .blue,
                                destination: AcademicCalendarSettingsView()
                            )
                            
                            RainbowNavigationCard(
                                title: "Settings",
                                subtitle: "App preferences & data",
                                icon: "gearshape.fill",
                                color: .purple,
                                destination: SettingsView()
                            )
                            
                            RainbowNavigationCard(
                                title: "Privacy Policy",
                                subtitle: "How we protect your data",
                                icon: "hand.raised.fill",
                                color: .green,
                                destination: PrivacyPolicyView()
                            )
                        }
                        .padding(.horizontal)
                        
                        // 3. Sign Out Button
                        Button(action: { authManager.signOut() }) {
                            Text("SIGN OUT")
                                .font(.headline)
                                .fontWeight(.black)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(white: 0.1))
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.red.opacity(0.5), lineWidth: 1))
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                    .padding(.bottom, 110)
                }
            }
            .navigationTitle("More")
            .navigationBarHidden(themeManager.selectedGameMode == .rainbow)
            .sheet(isPresented: $showingProfileEdit) {
                if let profile = profiles.first {
                    NavigationStack {
                        ProfileView(profile: profile)
                    }
                }
            }
        }
    }
}

// MARK: - 🌈 COMPONENTS
struct RainbowProfileCard: View {
    let user: StudentProfile?
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        HStack(spacing: 20) {
            // Avatar
            if let data = user?.profileImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage).resizable().scaledToFill()
                    .frame(width: 70, height: 70).clipShape(Circle())
                    .overlay(Circle().stroke(themeManager.selectedTheme.primaryColor, lineWidth: 2))
                    .shadow(color: themeManager.selectedTheme.primaryColor.opacity(0.5), radius: 10)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable().frame(width: 70, height: 70)
                    .foregroundColor(themeManager.selectedTheme.primaryColor.opacity(0.5))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(user?.name ?? "Student")
                    .font(.title3).fontWeight(.heavy).foregroundColor(.white)
                Text(user?.university ?? "University Not Set")
                    .font(.caption).fontWeight(.bold).foregroundColor(.gray)
                
                HStack(spacing: 4) {
                    Image(systemName: "pencil").font(.caption2).foregroundColor(themeManager.selectedTheme.primaryColor)
                    Text("Edit Profile").font(.caption2).fontWeight(.bold).foregroundColor(themeManager.selectedTheme.primaryColor)
                }
                .padding(.top, 4)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.gray.opacity(0.5))
        }
        .padding(20)
        .background(Color(white: 0.1))
        .cornerRadius(24)
        .padding(.horizontal)
    }
}

struct RainbowNavigationCard<Destination: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let destination: Destination
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(color.opacity(0.2)).frame(width: 44, height: 44)
                    Image(systemName: icon).font(.system(size: 20)).foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        // ✅ FIXED: .none -> .standard
                        .font(.headline).fontWeight(.bold)
                        .foregroundColor(themeManager.selectedGameMode == .standard ? .primary : .white)
                    Text(subtitle)
                        .font(.caption).foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray)
            }
            .padding(16)
            // ✅ FIXED: .none -> .standard
            .background(themeManager.selectedGameMode == .standard ? Color(uiColor: .secondarySystemGroupedBackground) : Color(white: 0.1))
            .cornerRadius(20)
        }
    }
}
