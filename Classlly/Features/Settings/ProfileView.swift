import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        Group {
            switch themeManager.selectedGameMode {
            case .rainbow:
                RainbowProfileView()
            case .arcade:
                ArcadeProfileView()
            case .none:
                StandardProfileView()
            }
        }
    }
}

// MARK: - 🌈 RAINBOW PROFILE
struct RainbowProfileView: View {
    @EnvironmentObject var themeManager: AppTheme
    @AppStorage("userName") private var userName = "Student"
    @AppStorage("userMajor") private var userMajor = "General Studies"
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        let accent = themeManager.selectedTheme.primaryColor
        
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // 1. Hero
                        VStack(spacing: 16) {
                            ZStack {
                                Circle().fill(accent.opacity(0.1)).frame(width: 120, height: 120)
                                Circle().stroke(accent, lineWidth: 3).frame(width: 120, height: 120)
                                    .shadow(color: accent.opacity(0.8), radius: 20)
                                Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(accent)
                            }
                            
                            VStack(spacing: 8) {
                                TextField("Name", text: $userName)
                                    .font(.title).fontWeight(.black)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                    .background(Color(white: 0.1))
                                    .cornerRadius(8)
                                
                                TextField("Major", text: $userMajor)
                                    .font(.headline).fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                                    .background(Color(white: 0.1))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal, 40)
                        }
                        .padding(.top, 40)
                        
                        // 2. Stats Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            RainbowStatCard(title: "LEVEL", value: "1", icon: "arrow.up.circle.fill", color: RainbowColors.blue)
                            RainbowStatCard(title: "XP", value: "1,250", icon: "star.fill", color: RainbowColors.orange)
                            RainbowStatCard(title: "STREAK", value: "5 Days", icon: "flame.fill", color: RainbowColors.red)
                            RainbowStatCard(title: "RANK", value: "Novice", icon: "medal.fill", color: RainbowColors.purple)
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") { dismiss() }.tint(accent)
                }
            }
        }
    }
}

struct RainbowStatCard: View {
    let title: String; let value: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon).foregroundColor(color)
                Spacer()
                Text(title).font(.caption).fontWeight(.black).foregroundColor(Color.gray)
            }
            Text(value).font(.title2).fontWeight(.black).foregroundColor(.white).frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - 🏠 STANDARD PROFILE
struct StandardProfileView: View {
    @AppStorage("userName") private var userName = "Student"
    @AppStorage("userMajor") private var userMajor = "General Studies"
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(themeManager.selectedTheme.primaryColor)
                        TextField("Your Name", text: $userName).multilineTextAlignment(.center).font(.headline)
                        TextField("Your Major", text: $userMajor).multilineTextAlignment(.center).font(.subheadline).foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Profile")
    }
}

// MARK: - 🕹️ ARCADE STUB
struct ArcadeProfileView: View {
    var body: some View {
        ZStack { Color.black.ignoresSafeArea(); Text("Arcade Profile").foregroundColor(.cyan) }
    }
}
