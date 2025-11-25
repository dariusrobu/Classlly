import SwiftUI

struct SettingsDashboardView: View {
    @Environment(\.colorScheme) var colorScheme; @EnvironmentObject var authManager: AuthenticationManager; @EnvironmentObject var themeManager: AppTheme
    public init() {}
    var body: some View {
        NavigationView {
            List {
                if let user = authManager.currentUser {
                    NavigationLink(destination: ProfileView()) {
                        HStack(spacing: 16) {
                            ZStack { Circle().fill(LinearGradient(gradient: Gradient(colors: [.themePrimary, .themeSecondary]), startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 60, height: 60); Text(getInitials(from: user.fullName)).font(.title2).fontWeight(.bold).foregroundColor(.white) }
                            VStack(alignment: .leading, spacing: 4) { Text(user.fullName).font(.headline).fontWeight(.semibold); Text("View Profile & Stats").font(.subheadline).foregroundColor(.secondary) }
                        }.padding(.vertical, 8)
                    }.adaptiveListRow()
                }
                Section {
                    NavigationLink(destination: AcademicCalendarView()) { Label("Academic Calendar", systemImage: "calendar.circle.fill") }.adaptiveListRow()
                    NavigationLink(destination: SettingsView()) { Label("Settings", systemImage: "gearshape.fill") }.adaptiveListRow()
                }
                Section { NavigationLink(destination: PrivacyPolicyView()) { Label("Terms & Privacy Policy", systemImage: "lock.shield.fill") }.adaptiveListRow() }
            }.listStyle(InsetGroupedListStyle()).scrollContentBackground(.hidden).background(Color.clear).navigationTitle("More").navigationBarTitleDisplayMode(.inline)
        }
    }
    private func getInitials(from name: String) -> String { let names = name.split(separator: " "); let initials = names.prefix(2).map { String($0.first ?? Character("")) }; return initials.joined() }
}
