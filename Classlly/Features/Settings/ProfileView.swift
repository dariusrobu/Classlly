import SwiftUI
import SwiftData

struct ProfileView: View {
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext

    @Query var subjects: [Subject]
    @Query var tasks: [StudyTask]
    
    public init() {}

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let user = authManager.currentUser {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [.themePrimary, .themeSecondary]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 100, height: 100)
                            
                            Text(getInitials(from: user.fullName))
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        }
                        VStack(spacing: 4) {
                            Text(user.fullName)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.themeTextPrimary)
                            Text(user.schoolName)
                                .font(.subheadline)
                                .foregroundColor(.themeTextSecondary)
                            if let major = user.major {
                                Text(major)
                                    .font(.subheadline)
                                    .foregroundColor(.themeTextSecondary)
                            }
                            HStack(spacing: 8) {
                                Text(user.gradeLevel)
                                Text("•")
                                Text(user.academicYear)
                            }
                            .font(.caption)
                            .foregroundColor(.themeTextSecondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.themeSurface)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Stats
                VStack(alignment: .leading, spacing: 0) {
                    Text("Quick Stats")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.themeTextPrimary)
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    
                    HStack(spacing: 12) {
                        StatBox(title: "Subjects", value: "\(subjects.count)")
                        StatBox(title: "Tasks", value: "\(tasks.count)")
                    }
                    .padding(.horizontal)
                }

                // Settings
                VStack(alignment: .leading, spacing: 0) {
                    Text("Account")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.themeTextPrimary)
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    
                    VStack(spacing: 0) {
                        if let user = authManager.currentUser {
                            NavigationLink(destination: EditProfileView(user: user)) {
                                SettingsRow(
                                    icon: "person.crop.circle",
                                    iconColor: .themePrimary,
                                    title: "Edit Profile",
                                    value: nil
                                )
                            }
                        }
                        
                        Divider().padding(.leading, 52)
                        
                        Button(action: {
                            authManager.signOut()
                        }) {
                            Text("Sign Out")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.themeError)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(Color.themeSurface)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color.themeBackground)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func getInitials(from name: String) -> String {
        let names = name.split(separator: " ")
        let initials = names.prefix(2).map { String($0.first ?? Character("")) }
        return initials.joined()
    }
}

// Helper Components
struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.themePrimary)
            Text(title)
                .font(.caption)
                .foregroundColor(.themeTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.themeSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String?
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 24)
            Text(title)
                .font(.body)
                .foregroundColor(.themeTextPrimary)
            Spacer()
            if let value = value {
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.themeTextSecondary)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.themeSurface)
        .contentShape(Rectangle())
    }
}
