import SwiftUI

struct SettingsDashboardView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authManager: AuthenticationManager
    
    public init() {}
    
    var body: some View {
        // ✅ REMOVED NavigationView
        List {
            if let user = authManager.currentUser {
                NavigationLink(destination: ProfileView()) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle().fill(LinearGradient(gradient: Gradient(colors: [.themePrimary, .themeSecondary]), startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 60, height: 60)
                            Text(getInitials(from: user.fullName)).font(.title2).fontWeight(.bold).foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.fullName).font(.headline).fontWeight(.semibold)
                            Text("View Profile & Stats").font(.subheadline).foregroundColor(.secondary)
                        }
                    }.padding(.vertical, 8)
                }.listRowBackground(Color.themeSurface)
            }
            
            Section {
                NavigationLink(destination: AcademicCalendarView()) { Label("Academic Calendar", systemImage: "calendar.circle.fill") }
                NavigationLink(destination: SettingsView()) { Label("Settings", systemImage: "gearshape.fill") }
            }.listRowBackground(Color.themeSurface)
            
            Section(header: Text("Support")) {
                NavigationLink(destination: AppGuideView()) { Label("App Guide", systemImage: "book.fill").foregroundColor(.primary) }
            }.listRowBackground(Color.themeSurface)
            
            Section {
                NavigationLink(destination: PrivacyPolicyView()) { Label("Terms & Privacy Policy", systemImage: "lock.shield.fill") }
            }.listRowBackground(Color.themeSurface)
        }
        .listStyle(InsetGroupedListStyle())
        .scrollContentBackground(.hidden)
        .background(Color.themeBackground)
        .navigationTitle("More")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func getInitials(from name: String) -> String {
        let names = name.split(separator: " ")
        let initials = names.prefix(2).map { String($0.first ?? Character("")) }
        return initials.joined()
    }
}
