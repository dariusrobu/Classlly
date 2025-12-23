import SwiftUI
import SwiftData

struct ProfileSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss
    
    // Form Fields
    @State private var universityName: String = ""
    @State private var facultyName: String = ""
    @State private var yearOfStudy: String = ""
    @State private var group: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Academic Details") {
                    TextField("University", text: $universityName)
                    TextField("Faculty", text: $facultyName)
                    TextField("Year of Study", text: $yearOfStudy)
                    TextField("Group", text: $group)
                }
                
                Button("Save Profile") {
                    saveProfile()
                }
                .disabled(universityName.isEmpty)
            }
            .navigationTitle("Setup Profile")
        }
    }
    
    private func saveProfile() {
        guard let uid = authManager.userSession?.uid else { return }
        
        // Create new AppUser
        let newUser = AppUser(id: uid, email: authManager.userSession?.email, fullName: authManager.userSession?.fullName)
        newUser.universityName = universityName
        newUser.facultyName = facultyName
        newUser.yearOfStudy = yearOfStudy
        newUser.group = group
        
        modelContext.insert(newUser)
        
        // Notify Manager
        authManager.completeOnboarding()
    }
}

#Preview {
    ProfileSetupView()
        .environment(AuthenticationManager())
}
