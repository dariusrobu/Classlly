import SwiftUI
import SwiftData
import UIKit

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var themeManager: AppTheme
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Query var subjects: [Subject]; @Query var tasks: [StudyTask]; @Query var events: [StudyCalendarEvent]
    public init() {}
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let user = authManager.currentUser {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle().fill(LinearGradient(gradient: Gradient(colors: [.themeBlue, .themePurple]), startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 100, height: 100).shadow(color: .themePurple.opacity(0.5), radius: 10, x: 0, y: 5)
                            Text(getInitials(from: user.fullName)).font(.system(size: 40, weight: .bold, design: .rounded)).foregroundColor(.white)
                        }
                        VStack(spacing: 4) {
                            Text(user.fullName).font(.title2).fontWeight(.bold).foregroundColor(.themeTextPrimary)
                            Text(user.schoolName).font(.subheadline).foregroundColor(.themeTextSecondary)
                            if let major = user.major { Text(major).font(.subheadline).foregroundColor(.themeTextSecondary) }
                            HStack(spacing: 8) { Text(user.gradeLevel); Text("•"); Text(user.academicYear) }.font(.caption).foregroundColor(.themeTextSecondary).opacity(0.8)
                        }
                    }.padding().frame(maxWidth: .infinity).adaptiveCard().padding(.horizontal)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Stats").font(.headline).fontWeight(.bold).foregroundColor(.themeTextPrimary).padding(.horizontal)
                    HStack(spacing: 12) {
                        ProfileStatBox(title: "Subjects", value: "\(subjects.count)", color: GameColor.electricBlue)
                        ProfileStatBox(title: "Tasks", value: "\(tasks.count)", color: GameColor.neonOrange)
                        ProfileStatBox(title: "Events", value: "\(events.count)", color: GameColor.emeraldGreen)
                    }.padding(.horizontal)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("Account").font(.headline).fontWeight(.bold).foregroundColor(.themeTextPrimary).padding(.horizontal)
                    VStack(spacing: 0) {
                        if let user = authManager.currentUser { NavigationLink(destination: EditProfileView(user: user)) { SettingsRow(icon: "person.crop.circle", iconColor: .themeBlue, title: "Edit Profile", value: nil) }.buttonStyle(PlainButtonStyle()) }
                        Divider().padding(.leading, 52).background(Color.adaptiveBorder)
                        Button(action: { exportData() }) { SettingsRow(icon: "square.and.arrow.up", iconColor: .themeBlue, title: "Export Data", value: nil) }.buttonStyle(PlainButtonStyle())
                        Divider().padding(.leading, 52).background(Color.adaptiveBorder)
                        Button(action: { clearAllData() }) { SettingsRow(icon: "trash", iconColor: .themeRed, title: "Clear All Data", value: nil) }.buttonStyle(PlainButtonStyle())
                    }.adaptiveCard().padding(.horizontal)
                }
                Button(action: { authManager.signOut() }) { Text("Sign Out").font(.body).fontWeight(.semibold).foregroundColor(.themeRed).frame(maxWidth: .infinity).padding().adaptiveCard() }.padding(.horizontal)
            }.padding(.vertical)
        }.background(Color.clear).navigationTitle("Profile").navigationBarTitleDisplayMode(.inline)
    }
    private func getInitials(from name: String) -> String { let names = name.split(separator: " "); let initials = names.prefix(2).map { String($0.first ?? Character("")) }; return initials.joined() }
    private func exportData() { /* ... same logic ... */ }
    private func clearAllData() { /* ... same logic ... */ }
}

struct ProfileStatBox: View {
    let title: String; let value: String; let color: Color; @EnvironmentObject var themeManager: AppTheme
    var body: some View {
        VStack(spacing: 8) {
            Text(value).font(.title2).fontWeight(.bold).foregroundColor(themeManager.isGamified ? .white : .themeBlue)
            Text(title).font(.caption).foregroundColor(themeManager.isGamified ? .white.opacity(0.7) : .adaptiveSecondary)
        }.frame(maxWidth: .infinity).padding().adaptiveCard(color: themeManager.isGamified ? color : nil)
    }
}

struct SettingsRow: View {
    let icon: String; let iconColor: Color; let title: String; let value: String?; @EnvironmentObject var themeManager: AppTheme
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon).font(.title2).foregroundColor(iconColor).frame(width: 24)
            Text(title).font(.body).foregroundColor(.themeTextPrimary)
            Spacer()
            if let value = value { Text(value).font(.subheadline).foregroundColor(.themeTextSecondary) }
            Image(systemName: "chevron.right").font(.system(size: 14, weight: .medium)).foregroundColor(.secondary)
        }.padding().contentShape(Rectangle())
    }
}
