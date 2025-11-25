import SwiftUI

struct ProfileSetupView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    
    // FIX: Changed to AppUser
    let user: AppUser
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var schoolName: String = ""
    @State private var educationLevel: String = ""
    @State private var major: String = ""
    @State private var academicYear: String = ""
    
    private let educationLevels = ["High School", "Bachelor's Degree", "Master's Degree", "PhD", "Other"]
    private let academicYears = ["2023-2024", "2024-2025", "2025-2026", "2026-2027", "2027-2028"]
    private let popularMajors = [
        "Computer Science", "Engineering", "Business", "Medicine", "Law",
        "Psychology", "Biology", "Chemistry", "Physics", "Mathematics",
        "Economics", "Political Science", "History", "English", "Art",
        "Music", "Architecture", "Education", "Nursing", "Other"
    ]
    
    // FIX: Init with AppUser
    init(user: AppUser) {
        self.user = user
        _firstName = State(initialValue: user.firstName)
        _lastName = State(initialValue: user.lastName)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    HStack {
                        TextField("First Name", text: $firstName)
                        TextField("Last Name", text: $lastName)
                    }
                }
                Section(header: Text("Academic Information")) {
                    TextField("School/University Name", text: $schoolName)
                        .textInputAutocapitalization(.words)
                    
                    Picker("Education Level", selection: $educationLevel) {
                        Text("Select Education Level").tag("")
                        ForEach(educationLevels, id: \.self) { level in
                            Text(level).tag(level)
                        }
                    }
                    
                    Picker("Major/Field of Study", selection: $major) {
                        Text("Select Major").tag("")
                        ForEach(popularMajors, id: \.self) { major in
                            Text(major).tag(major)
                        }
                    }
                    
                    Picker("Academic Year", selection: $academicYear) {
                        Text("Select Academic Year").tag("")
                        ForEach(academicYears, id: \.self) { year in
                            Text(year).tag(year)
                        }
                    }
                }
                Section(footer: Text("By completing your profile, you agree to our Terms of Service")) {
                    EmptyView()
                }
            }
            .navigationTitle("Complete Your Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        authManager.signOut()
                        dismiss()
                    }
                    .foregroundColor(.themeError)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Continue") { completeProfile() }
                        .disabled(!isFormValid)
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !schoolName.isEmpty && !educationLevel.isEmpty && !academicYear.isEmpty
    }
    
    private func completeProfile() {
        // FIX: Create AppUser
        let completedProfile = AppUser(
            id: user.id,
            firstName: firstName,
            lastName: lastName,
            email: user.email,
            schoolName: schoolName,
            gradeLevel: educationLevel, // educationLevel maps to gradeLevel
            major: major.isEmpty ? nil : major,
            academicYear: academicYear,
            profileImageData: nil
        )
        
        authManager.completeProfileSetup(profile: completedProfile)
        dismiss()
    }
}
