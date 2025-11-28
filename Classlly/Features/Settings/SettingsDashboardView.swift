import SwiftUI

struct SettingsDashboardView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authManager: AuthenticationManager
    @AppStorage("isGamified") private var isGamified = false
    
    public init() {}
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Profile Section
                Section {
                    NavigationLink(destination: ProfileView()) {
                        if let user = authManager.currentUser {
                            ProfileHeaderRow(user: user, isGamified: isGamified)
                        } else {
                            // Fallback state if user data is missing
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                    .overlay(Image(systemName: "person.fill").foregroundColor(.secondary))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Guest User")
                                        .font(.headline)
                                        .foregroundColor(.themeTextPrimary)
                                    Text("Sign in to sync data")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listRowBackground(Color.themeSurface)
                
                // MARK: - Features
                Section {
                    NavigationLink(destination: AcademicCalendarView()) {
                        MoreTabRow(
                            icon: isGamified ? "calendar.circle.fill" : "calendar",
                            title: "Academic Calendar",
                            subtitle: "Manage semesters & holidays",
                            color: .themePrimary,
                            isGamified: isGamified
                        )
                    }
                    
                    NavigationLink(destination: SettingsView()) {
                        MoreTabRow(
                            icon: isGamified ? "gearshape.fill" : "gearshape",
                            title: "Settings",
                            subtitle: "App preferences & appearance",
                            color: .themeSecondary,
                            isGamified: isGamified
                        )
                    }
                }
                .listRowBackground(Color.themeSurface)
                
                // MARK: - Support & Legal
                Section {
                    NavigationLink(destination: PrivacyPolicyView()) {
                        MoreTabRow(
                            icon: isGamified ? "lock.shield.fill" : "lock.shield",
                            title: "Privacy Policy",
                            subtitle: nil,
                            color: .themeSuccess,
                            isGamified: isGamified
                        )
                    }
                }
                .listRowBackground(Color.themeSurface)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.themeBackground)
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Helper Views

struct ProfileHeaderRow: View {
    let user: UserProfile
    let isGamified: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                if isGamified {
                    // Gamified: Gradient Avatar
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.themePrimary, .themeSecondary]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 60, height: 60)
                        .shadow(color: .themePrimary.opacity(0.4), radius: 4, x: 0, y: 2)
                } else {
                    // Minimalist: Clean Circle with Initials
                    Circle()
                        .fill(Color.themePrimary.opacity(0.1))
                        .frame(width: 60, height: 60)
                }
                
                Text(getInitials(from: user.fullName))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isGamified ? .white : .themePrimary)
            }
            
            // Text Info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.fullName)
                    .font(.headline)
                    .foregroundColor(.themeTextPrimary)
                
                if isGamified {
                    Text("Level 5 Scholar") // Placeholder for gamified rank
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.themeSecondary)
                } else {
                    Text("View Profile")
                        .font(.subheadline)
                        .foregroundColor(.themeTextSecondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func getInitials(from name: String) -> String {
        let names = name.split(separator: " ")
        let initials = names.prefix(2).map { String($0.first ?? Character("")) }
        return initials.joined()
    }
}

struct MoreTabRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let color: Color
    let isGamified: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                if isGamified {
                    // Gamified: Colored Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                } else {
                    // Minimalist: Simple Icon
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                        .frame(width: 32)
                }
            }
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.themeTextPrimary)
                
                if let subtitle = subtitle, !isGamified {
                    // Show subtitle only in minimalist mode for detail
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.themeTextSecondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
