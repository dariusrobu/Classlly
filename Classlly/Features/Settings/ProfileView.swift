import SwiftUI
import UIKit
import SwiftData

struct ProfileView: View {
    // ... (Properties unchanged) ...
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
                // ... (Header / Stats / Account sections unchanged) ...
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
                            confirmClearData()
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
                
                // --- SIGN OUT BUTTON ---
                Button(action: {
                    handleSignOut()
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
        .background(Color.themeBackground)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(darkModeEnabled ? .dark : .light)
    }
    
    // --- UPDATED: Pass context to manager ---
    private func handleSignOut() {
        authManager.signOut(modelContext: modelContext)
    }
    
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
    
    private func confirmClearData() {
        let alert = UIAlertController(
            title: "Clear All Data",
            message: "Are you sure you want to clear all your data? This will remove all subjects, tasks, and events. This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear All", style: .destructive) { _ in
            notificationManager.removeAllNotifications()
            DemoDataManager.shared.deleteAllData(modelContext: modelContext)
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
}

// ... (Rest of NotificationSettingsView, EditProfileView, etc. remains unchanged) ...
// [Keep the rest of the file content]

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var pendingNotifications: [UNNotificationRequest] = []
    @Environment(\.colorScheme) var colorScheme
    
    public init() {}
    
    var body: some View {
        List {
            Section(header: Text("Notification Status").foregroundColor(.adaptiveSecondary)) {
                HStack {
                    Text("Permission Status")
                    Spacer()
                    Text(notificationManager.permissionGranted ? "Granted" : "Denied")
                        .foregroundColor(notificationManager.permissionGranted ? .themeGreen : .themeRed)
                }
                HStack {
                    Text("Pending Notifications")
                    Spacer()
                    Text("\(pendingNotifications.count)")
                        .foregroundColor(.themeBlue)
                }
            }
            .listRowBackground(Color.themeSurface)
            
            Section(header: Text("Manage Notifications").foregroundColor(.adaptiveSecondary)) {
                Button("View All Pending Notifications") { loadPendingNotifications() }
                Button("Remove All Notifications", role: .destructive) { removeAllNotifications() }
            }
            .listRowBackground(Color.themeSurface)
            
            if !pendingNotifications.isEmpty {
                Section(header: Text("Pending Notifications").foregroundColor(.adaptiveSecondary)) {
                    ForEach(pendingNotifications, id: \.identifier) { notification in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(notification.content.title)
                            Text(notification.content.body)
                            if let trigger = notification.trigger as? UNCalendarNotificationTrigger {
                                Text("Scheduled: \(formatTriggerDate(trigger))")
                            }
                        }
                        .font(.caption)
                    }
                }
                .listRowBackground(Color.themeSurface)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.themeBackground)
        .navigationTitle("Notification Settings")
        .onAppear { loadPendingNotifications() }
    }
    
    private func loadPendingNotifications() {
        notificationManager.getPendingNotifications { requests in
            DispatchQueue.main.async { self.pendingNotifications = requests }
        }
    }
    
    private func removeAllNotifications() {
        notificationManager.removeAllNotifications()
        loadPendingNotifications()
    }
    
    private func formatTriggerDate(_ trigger: UNCalendarNotificationTrigger) -> String {
        if let date = trigger.nextTriggerDate() {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else {
            return "Unknown"
        }
    }
}

// Remove Codable conformance. Exporting is now handled separately.
struct ExportData {
    let subjects: [Subject]
    let tasks: [StudyTask]
    let events: [StudyCalendarEvent]
    let exportDate: Date
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    // --- FIX: Add modelContext environment variable ---
    @Environment(\.modelContext) private var modelContext
    
    let user: UserProfile
    @Environment(\.colorScheme) var colorScheme
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var schoolName: String
    @State private var gradeLevel: String
    @State private var major: String
    @State private var academicYear: String
    
    private let gradeLevels = ["Freshman", "Sophomore", "Junior", "Senior", "Graduate", "PhD", "Other"]
    private let academicYears = ["2023-2024", "2024-2025", "2025-2026", "2026-2027", "2027-2028"]
    private let popularMajors = [
        "Computer Science", "Engineering", "Business", "Medicine", "Law",
        "Psychology", "Biology", "Chemistry", "Physics", "Mathematics",
        "Economics", "Political Science", "History", "English", "Art",
        "Music", "Architecture", "Education", "Nursing", "Other"
    ]
    
    init(user: UserProfile) {
        self.user = user
        _firstName = State(initialValue: user.firstName)
        _lastName = State(initialValue: user.lastName)
        _schoolName = State(initialValue: user.schoolName)
        _gradeLevel = State(initialValue: user.gradeLevel)
        _major = State(initialValue: user.major ?? "")
        _academicYear = State(initialValue: user.academicYear)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Personal Information").foregroundColor(.adaptiveSecondary)) {
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
            }
            .listRowBackground(Color.themeSurface)
            
            Section(header: Text("Academic Information").foregroundColor(.adaptiveSecondary)) {
                TextField("School/University", text: $schoolName)
                Picker("Grade Level", selection: $gradeLevel) {
                    ForEach(gradeLevels, id: \.self) { Text($0) }
                }
                Picker("Major", selection: $major) {
                    ForEach(popularMajors, id: \.self) { Text($0) }
                }
                Picker("Academic Year", selection: $academicYear) {
                    ForEach(academicYears, id: \.self) { Text($0) }
                }
            }
            .listRowBackground(Color.themeSurface)
        }
        .scrollContentBackground(.hidden)
        .background(Color.themeBackground)
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }.foregroundColor(.themeBlue)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") { saveProfile() }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                    .foregroundColor(isFormValid ? .themeBlue : .adaptiveSecondary)
            }
        }
    }
    
    private var isFormValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !schoolName.isEmpty
    }
    
    private func saveProfile() {
        let updatedProfile = UserProfile(
            id: user.id,
            firstName: firstName,
            lastName: lastName,
            email: user.email,
            schoolName: schoolName,
            gradeLevel: gradeLevel,
            major: major.isEmpty ? nil : major,
            academicYear: academicYear,
            profileImageData: user.profileImageData
        )
        // --- FIX: Pass modelContext to the function call ---
        authManager.completeProfileSetup(profile: updatedProfile, modelContext: modelContext)
        dismiss()
    }
}

struct StatBox: View {
    let title: String
    let value: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.themeBlue)
            Text(title)
                .font(.caption)
                .foregroundColor(.adaptiveSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.themeSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.adaptiveBorder.opacity(0.3), lineWidth: 1)
        )
    }
}

struct PreferenceRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 24)
            Text(title)
                .font(.body)
                .foregroundColor(.adaptivePrimary)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(iconColor)
        }
        .padding()
        .background(Color.themeSurface)
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 24)
            Text(title)
                .font(.body)
                .foregroundColor(.adaptivePrimary)
            Spacer()
            if let value = value {
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.adaptiveSecondary)
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
