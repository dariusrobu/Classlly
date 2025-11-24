import SwiftUI
import UIKit
import SwiftData

struct ProfileView: View {
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var themeManager: AppTheme
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
                                    gradient: Gradient(colors: [
                                        themeManager.selectedTheme.accentColor,
                                        themeManager.selectedTheme.accentColor.opacity(0.6)
                                    ]),
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
                        StatBox(title: "Subjects", value: "\(subjects.count)", color: themeManager.selectedTheme.accentColor)
                        StatBox(title: "Tasks", value: "\(tasks.count)", color: themeManager.selectedTheme.accentColor)
                        StatBox(title: "Events", value: "\(events.count)", color: themeManager.selectedTheme.accentColor)
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
                                    iconColor: themeManager.selectedTheme.accentColor,
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
                                iconColor: themeManager.selectedTheme.accentColor,
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
                    // FIX: Pass modelContext to signOut
                    authManager.signOut(context: modelContext)
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
        let alert = UIAlertController(
            title: "Clear All Data",
            message: "Are you sure you want to clear all your data? This will remove all subjects, tasks, and events. This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear All", style: .destructive) { _ in
            notificationManager.removeAllNotifications()
            
            do {
                try modelContext.delete(model: Subject.self)
                try modelContext.delete(model: StudyTask.self)
                try modelContext.delete(model: StudyCalendarEvent.self)
                try modelContext.delete(model: GradeEntry.self)
                try modelContext.delete(model: AttendanceEntry.self)
            } catch {
                print("Failed to clear all data: \(error)")
            }
            
            let successAlert = UIAlertController(
                title: "Data Cleared",
                message: "All your data has been cleared successfully.",
                preferredStyle: .alert
            )
            successAlert.addAction(UIAlertAction(title: "OK", style: .default))
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(successAlert, animated: true)
            }
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
}

// MARK: - Helper Views

struct StatBox: View {
    let title: String
    let value: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
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

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext // FIX: Added Environment Context
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var themeManager: AppTheme
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
                Button("Cancel") { dismiss() }
                    .foregroundColor(themeManager.selectedTheme.accentColor)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") { saveProfile() }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                    .foregroundColor(isFormValid ? themeManager.selectedTheme.accentColor : .adaptiveSecondary)
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
        // FIX: Pass modelContext to completeProfileSetup
        authManager.completeProfileSetup(profile: updatedProfile, context: modelContext)
        dismiss()
    }
}
