import SwiftUI

struct SettingsView: View {
    @Environment(AuthenticationManager.self) private var authManager
    
    var body: some View {
        List {
            Section("General") {
                NavigationLink("Appearance") { Text("Appearance Settings") }
                NavigationLink("Notifications") { Text("Notification Settings") }
            }
            
            Section("Account") {
                if let email = authManager.userSession?.email {
                    LabeledContent("Email", value: email)
                }
                
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
        .environment(AuthenticationManager())
}
