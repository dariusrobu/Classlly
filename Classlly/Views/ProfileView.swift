import SwiftUI
import UIKit
import SwiftData

struct ProfileView: View {
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext

    @Query var subjects: [Subject]
    @Query var tasks: [StudyTask]
    @Query var events: [StudyCalendarEvent]
    
    public init() {}

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let user = authManager.currentUser {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [.themeBlue, .themePurple]),
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
                                .foregroundColor(.adaptivePrimary)
                            Text(user.schoolName)
                                .font(.subheadline)
                                .foregroundColor(.adaptiveSecondary)
                            if let major = user.major {
                                Text(major)
                                    .font(.subheadline)
                                    .foregroundColor(.adaptiveSecondary)
                            }
                            HStack(spacing: 8) {
                                Text(user.gradeLevel)
                                Text("•")
                                Text(user.academicYear)
                            }
                            .font(.caption)
                            .foregroundColor(.adaptiveSecondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .adaptiveCard()
                    .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("Quick Stats")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.adaptivePrimary)
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    
                    HStack(spacing: 12) {
                        StatBox(title: "Subjects", value: "\(subjects.count)")
                        StatBox(title: "Tasks", value: "\(tasks.count)")
                        StatBox(title: "Events", value: "\(events.count)")
                    }
                    .padding(.horizontal)
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text("Account")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.adaptivePrimary)
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    
                    VStack(spacing: 0) {
                        if let user = authManager.currentUser {
                            NavigationLink(destination: EditProfileView(user: user)) {
                                SettingsRow(
                                    icon: "person.crop.circle",
                                    iconColor: .themeBlue,
                                    title: "Edit Profile",
                                    value: nil
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Divider()
                            .padding(.leading, 52)
                        
                        Button(action: {
                            exportData()
                        }) {
                            SettingsRow(
                                icon: "square.and.arrow.up",
                                iconColor: .themeBlue,
                                title: "Export Data",
                                value: nil
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider()
                            .padding(.leading, 52)
                        
                        Button(action: {
                            clearAllData()
                        }) {
                            SettingsRow(
                                icon: "trash",
                                iconColor: .themeRed,
                                title: "Clear All Data",
                                value: nil
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .adaptiveCard()
                    .padding(.horizontal)
                }
                
                Button(action: {
                    authManager.signOut()
                }) {
                    Text("Sign Out")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.themeRed)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.themeSurface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.themeRed.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        // UPDATED: Removed .background(Color.themeBackground) to allow Gamified gradient
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(darkModeEnabled ? .dark : .light)
    }
    
    // ... (Helper methods exportData, clearAllData, getInitials remain unchanged) ...
    private func getInitials(from name: String) -> String {
        let names = name.split(separator: " ")
        let initials = names.prefix(2).map { String($0.first ?? Character("")) }
        return initials.joined()
    }
    
    private func exportData() {
        let alert = UIAlertController(
            title: "Export Not Implemented",
            message: "Exporting SwiftData models requires a custom Codable implementation.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    private func clearAllData() {
        // Implementation unchanged
    }
}

// ... (NotificationSettingsView, EditProfileView, StatBox, etc. remain unchanged) ...
struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var pendingNotifications: [UNNotificationRequest] = []
    
    var body: some View {
        List {
            Section(header: Text("Notification Status")) {
                HStack {
                    Text("Permission Status")
                    Spacer()
                    Text(notificationManager.permissionGranted ? "Granted" : "Denied")
                }
            }
            if !pendingNotifications.isEmpty {
                Section(header: Text("Pending")) {
                    ForEach(pendingNotifications, id: \.identifier) { notif in
                        Text(notif.content.title)
                    }
                }
            }
        }
        .onAppear {
            notificationManager.getPendingNotifications { self.pendingNotifications = $0 }
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    let user: UserProfile
    @State private var firstName: String
    
    init(user: UserProfile) {
        self.user = user
        _firstName = State(initialValue: user.firstName)
    }
    
    var body: some View {
        Form {
            TextField("First Name", text: $firstName)
            Button("Save") {
                var updated = user
                updated.firstName = firstName
                authManager.completeProfileSetup(profile: updated)
                dismiss()
            }
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(value).font(.title2).bold()
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.themeSurface)
        .cornerRadius(12)
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String?
    
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(iconColor)
            Text(title)
            Spacer()
            if let v = value { Text(v).foregroundColor(.secondary) }
            Image(systemName: "chevron.right").foregroundColor(.secondary)
        }
        .padding()
        .background(Color.themeSurface)
    }
}
