import SwiftUI
import SwiftData

struct SettingsDashboardView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var themeManager: AppTheme
    
    @AppStorage("isGamifiedMode") private var isGamifiedMode = false
    
    // Fetch all subjects to calculate Global Stats
    @Query var subjects: [Subject]
    
    public init() {}
    
    var body: some View {
        ScrollView {
            if isGamifiedMode {
                GamifiedSettingsLayout(
                    authManager: authManager,
                    subjects: subjects,
                    themeColor: themeManager.selectedTheme.accentColor
                )
            } else {
                StandardSettingsLayout(authManager: authManager)
            }
        }
        .background(Color.themeBackground)
        .navigationTitle("More")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 1. Standard Layout (List Based)
struct StandardSettingsLayout: View {
    @ObservedObject var authManager: AuthenticationManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Profile Section
            if let user = authManager.currentUser {
                NavigationLink(destination: ProfileView()) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [.themePrimary, .themeSecondary]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 60, height: 60)
                            
                            Text(getInitials(from: user.fullName))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.fullName)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.themeTextPrimary)
                            Text("View Profile & Stats")
                                .font(.subheadline)
                                .foregroundColor(.themeTextSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.themeTextSecondary)
                    }
                    .padding()
                    .background(Color.themeSurface)
                    .cornerRadius(12)
                }
                .padding()
            }
            
            // Menu List
            VStack(spacing: 16) {
                StandardMenuRow(icon: "calendar.circle.fill", title: "Academic Calendar", destination: AcademicCalendarView(), color: .blue)
                StandardMenuRow(icon: "gearshape.fill", title: "Settings", destination: SettingsView(), color: .gray)
                StandardMenuRow(icon: "book.fill", title: "App Guide", destination: AppGuideView(), color: .orange)
                StandardMenuRow(icon: "lock.shield.fill", title: "Privacy Policy", destination: PrivacyPolicyView(), color: .green)
            }
            .padding(.horizontal)
        }
    }
    
    private func getInitials(from name: String) -> String {
        let names = name.split(separator: " ")
        let initials = names.prefix(2).map { String($0.first ?? Character("")) }
        return initials.joined()
    }
}

struct StandardMenuRow<Destination: View>: View {
    let icon: String
    let title: String
    let destination: Destination
    let color: Color
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 32)
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.themeTextPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.themeTextSecondary)
            }
            .padding()
            .background(Color.themeSurface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.adaptiveBorder.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - 2. Gamified Layout (Grid & Card Based)
struct GamifiedSettingsLayout: View {
    @ObservedObject var authManager: AuthenticationManager
    var subjects: [Subject]
    var themeColor: Color
    
    // Compute Global Stats
    private var stats: (rank: String, rankColor: Color, xp: Int, level: Int) {
        var totalXP = 0
        var totalGrades = 0.0
        var subjectCount = 0
        
        for subject in subjects {
            // XP Calculation
            let gradeXP = (subject.gradeHistory ?? []).count * 100
            let attendanceXP = subject.attendedClasses * 50
            totalXP += (gradeXP + attendanceXP)
            
            // Average Calculation
            let history = subject.gradeHistory ?? []
            if !history.isEmpty {
                let sum = history.reduce(0.0) { $0 + $1.grade }
                totalGrades += (sum / Double(history.count))
                subjectCount += 1
            }
        }
        
        let globalAverage = subjectCount > 0 ? totalGrades / Double(subjectCount) : 0.0
        let level = (totalXP / 1000) + 1
        
        // Global Rank
        let rank: String
        let color: Color
        switch globalAverage {
        case 9.5...10.0: (rank, color) = ("Grandmaster", .purple)
        case 9.0..<9.5:  (rank, color) = ("Legend", .orange)
        case 8.0..<9.0:  (rank, color) = ("Master", .blue)
        case 7.0..<8.0:  (rank, color) = ("Elite", .green)
        case 5.0..<7.0:  (rank, color) = ("Student", .gray)
        default:         (rank, color) = ("Novice", .red)
        }
        
        return (rank, color, totalXP, level)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // 1. Hero Profile Card
            if let user = authManager.currentUser {
                NavigationLink(destination: ProfileView()) {
                    GamifiedProfileCard(
                        user: user,
                        stats: stats,
                        themeColor: themeColor
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 2. Menu Grid
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                GamifiedMenuCard(title: "Calendar", icon: "calendar", color: .blue, destination: AcademicCalendarView())
                GamifiedMenuCard(title: "Settings", icon: "gearshape.fill", color: .gray, destination: SettingsView())
                GamifiedMenuCard(title: "Guide", icon: "book.fill", color: .orange, destination: AppGuideView())
                GamifiedMenuCard(title: "Privacy", icon: "lock.shield.fill", color: .green, destination: PrivacyPolicyView())
            }
            .padding(.horizontal)
        }
        .padding(.top)
    }
}

struct GamifiedProfileCard: View {
    let user: UserProfile
    let stats: (rank: String, rankColor: Color, xp: Int, level: Int)
    let themeColor: Color
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar & Name
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Text(getInitials(from: user.fullName))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text(user.fullName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(user.schoolName)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Divider().background(Color.white.opacity(0.3))
            
            // Global Stats Row
            HStack(spacing: 12) {
                // Rank
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .foregroundColor(stats.rankColor)
                    Text(stats.rank)
                        .fontWeight(.bold)
                        .foregroundColor(stats.rankColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white)
                .cornerRadius(20)
                
                // Level
                HStack(spacing: 4) {
                    Image(systemName: "shield.fill")
                        .foregroundColor(.white)
                    Text("Lvl \(stats.level)")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                // XP
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.yellow)
                    Text("\(stats.xp) XP")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [themeColor, themeColor.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
        .shadow(color: themeColor.opacity(0.4), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
    
    private func getInitials(from name: String) -> String {
        let names = name.split(separator: " ")
        let initials = names.prefix(2).map { String($0.first ?? Character("")) }
        return initials.joined()
    }
}

struct GamifiedMenuCard<Destination: View>: View {
    let title: String
    let icon: String
    let color: Color
    let destination: Destination
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(color)
                        .clipShape(Circle())
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.themeTextPrimary)
            }
            .padding()
            .background(Color.themeSurface)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 5, x: 0, y: 2)
        }
    }
}
