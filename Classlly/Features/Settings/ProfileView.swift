import SwiftUI
import SwiftData
import Observation

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthenticationManager.self) private var authManager
    
    // FIXED: Query AppUser, not User
    @Query(sort: \AppUser.dateCreated, order: .reverse) private var users: [AppUser]
    
    private var currentUser: AppUser? {
        guard let userId = authManager.userSession?.uid else { return nil }
        return users.first { $0.id == userId }
    }
    
    var body: some View {
        List {
            if let user = currentUser {
                Section {
                    HStack {
                        Text(user.initials)
                            .font(.title)
                            .fontWeight(.bold)
                            .frame(width: 50, height: 50)
                            .background(Color.accentColor.opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text(user.fullName ?? "Student")
                                .font(.headline)
                            Text(user.email ?? "No Email")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section("Academic Info") {
                    LabeledContent("University", value: user.universityName ?? "-")
                    LabeledContent("Faculty", value: user.facultyName ?? "-")
                    LabeledContent("Group", value: user.group ?? "-")
                }
            } else {
                ContentUnavailableView("Profile Not Found", systemImage: "person.slash")
            }
            
            Section {
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
            }
        }
        .navigationTitle("Profile")
    }
}
