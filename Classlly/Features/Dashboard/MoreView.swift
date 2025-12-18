import SwiftUI
import SwiftData

struct MoreView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var themeManager: AppTheme
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background adaptivity based on GameMode
                if themeManager.selectedGameMode != .none {
                    Color.black.ignoresSafeArea()
                } else {
                    Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                }
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Profile Card Header
                        ProfileHeaderCard(user: authManager.currentUser)
                            .padding(.top, 10)
                        
                        // 2. Navigation Group
                        VStack(spacing: 0) {
                            // ✅ Navigation to Academic Calendar
                            MoreNavigationRow(
                                title: "Academic Calendar",
                                icon: "calendar",
                                color: .blue,
                                destination: AcademicCalendarSettingsView()
                            )
                            
                            Divider()
                                .padding(.leading, 56)
                                .opacity(themeManager.selectedGameMode == .none ? 1 : 0.2)
                            
                            // ✅ Navigation to Settings
                            MoreNavigationRow(
                                title: "Settings",
                                icon: "gearshape.fill",
                                color: .gray,
                                destination: SettingsView()
                            )
                        }
                        .background(themeManager.selectedGameMode == .none ? Color(uiColor: .secondarySystemGroupedBackground) : Color(white: 0.12))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // 3. Sign Out
                        Button(role: .destructive, action: { authManager.signOut(modelContext: modelContext) }) {
                            Text("Sign Out")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(themeManager.selectedGameMode == .none ? Color(uiColor: .secondarySystemGroupedBackground) : Color(white: 0.12))
                                .cornerRadius(16)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 110) // Space for Tab Bar
                }
            }
            .navigationTitle("More")
            .toolbarColorScheme(themeManager.selectedGameMode == .none ? nil : .dark, for: .navigationBar)
        }
    }
}

// MARK: - Profile Card Component
struct ProfileHeaderCard: View {
    let user: StudentProfile?
    @EnvironmentObject var themeManager: AppTheme
    
    var body: some View {
        VStack(spacing: 16) {
            if let data = user?.profileImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(themeManager.selectedTheme.primaryColor, lineWidth: 2))
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 4) {
                Text(user?.fullName ?? "Student")
                    .font(.headline)
                    .foregroundColor(themeManager.selectedGameMode == .none ? .primary : .white)
                
                Text(user?.schoolName ?? "University Not Set")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(themeManager.selectedGameMode == .none ? Color(uiColor: .secondarySystemGroupedBackground) : Color(white: 0.15))
        .cornerRadius(20)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.05), radius: 8)
    }
}

// MARK: - Row Component
struct MoreNavigationRow<Destination: View>: View {
    let title: String
    let icon: String
    let color: Color
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(color)
                    .cornerRadius(8)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}
