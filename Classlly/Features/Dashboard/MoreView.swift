import SwiftUI

struct MoreView: View {
    @Environment(AuthenticationManager.self) private var authManager
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: ProfileView()) {
                        Label("Profile", systemImage: "person.circle")
                    }
                    
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        authManager.signOut()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("More")
        }
    }
}

#Preview {
    MoreView()
        .environment(AuthenticationManager())
}
