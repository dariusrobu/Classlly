import SwiftUI
import SwiftData

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.colorScheme) var colorScheme
    
    @Bindable var user: UserProfile
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var schoolName: String
    @State private var gradeLevel: String
    @State private var major: String
    @State private var academicYear: String
    
    private let gradeLevels = ["High School", "Bachelor's Degree", "Master's Degree", "PhD"]
    
    // ✅ FIXED: Changed to simple Year numbers
    private let academicYears = ["Year 1", "Year 2", "Year 3", "Year 4", "Year 5", "Year 6"]
    
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
            Section(header: Text("Personal Information").foregroundColor(.secondary)) {
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
            }
            
            Section(header: Text("Academic Information").foregroundColor(.secondary)) {
                TextField("School/University", text: $schoolName)
                
                Picker("Grade Level", selection: $gradeLevel) {
                    ForEach(gradeLevels, id: \.self) { Text($0) }
                }
                
                Picker("Major", selection: $major) {
                    ForEach(popularMajors, id: \.self) { Text($0) }
                }
                
                // ✅ Updated Label
                Picker("Current Year", selection: $academicYear) {
                    ForEach(academicYears, id: \.self) { Text($0) }
                }
            }
        }
        .navigationTitle("Edit Profile")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    user.firstName = firstName
                    user.lastName = lastName
                    user.schoolName = schoolName
                    user.gradeLevel = gradeLevel
                    user.major = major.isEmpty ? nil : major
                    user.academicYear = academicYear
                    try? modelContext.save()
                    dismiss()
                }
            }
        }
    }
}
