import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var themeManager: AppTheme // Inject
    
    let user: AppUser
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
    
    init(user: AppUser) {
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
            Section(header: Text("Personal Information")) {
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
            }
            .adaptiveListRow() // FIX
            
            Section(header: Text("Academic Information")) {
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
            .adaptiveListRow() // FIX
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
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
                    .foregroundColor(isFormValid ? .themeBlue : .secondary)
            }
        }
    }
    
    private var isFormValid: Bool { !firstName.isEmpty && !lastName.isEmpty && !schoolName.isEmpty }
    
    private func saveProfile() {
        let updatedProfile = AppUser(
            id: user.id, firstName: firstName, lastName: lastName, email: user.email,
            schoolName: schoolName, gradeLevel: gradeLevel, major: major.isEmpty ? nil : major,
            academicYear: academicYear, profileImageData: user.profileImageData
        )
        authManager.completeProfileSetup(profile: updatedProfile)
        dismiss()
    }
}
