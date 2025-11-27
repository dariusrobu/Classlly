import SwiftUI
import SwiftData

struct ProfileSetupView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var schoolName: String = ""
    @State private var educationLevel: String = ""
    @State private var major: String = ""
    @State private var academicYear: String = ""
    
    private let educationLevels = ["High School", "Bachelor's Degree", "Master's Degree", "PhD"]
    
    // ✅ FIXED: Changed to simple Year numbers
    private let academicYears = ["Year 1", "Year 2", "Year 3", "Year 4", "Year 5", "Year 6"]
    
    private let popularMajors = [
        "Computer Science", "Engineering", "Business", "Medicine", "Law",
        "Psychology", "Biology", "Chemistry", "Physics", "Mathematics",
        "Economics", "Political Science", "History", "English", "Art",
        "Music", "Architecture", "Education", "Nursing", "Other"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                }
                
                Section(header: Text("Academic Information")) {
                    TextField("School/University Name", text: $schoolName)
                        .textInputAutocapitalization(.words)
                    
                    Picker("Grade Level", selection: $educationLevel) {
                        Text("Select Grade Level").tag("")
                        ForEach(educationLevels, id: \.self) { level in Text(level).tag(level) }
                    }
                    
                    Picker("Major/Field of Study", selection: $major) {
                        Text("Select Major").tag("")
                        ForEach(popularMajors, id: \.self) { major in Text(major).tag(major) }
                    }
                    
                    // ✅ Updated Label
                    Picker("Current Year", selection: $academicYear) {
                        Text("Select Year").tag("")
                        ForEach(academicYears, id: \.self) { year in Text(year).tag(year) }
                    }
                }
            }
            .navigationTitle("Complete Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let temp = authManager.tempOnboardingData {
                    if firstName.isEmpty { firstName = temp.first }
                    if lastName.isEmpty { lastName = temp.last }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        authManager.signOut()
                        dismiss()
                    }
                    .foregroundColor(.themeError)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Finish") {
                        completeProfile()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !schoolName.isEmpty &&
        !educationLevel.isEmpty &&
        !academicYear.isEmpty
    }
    
    private func completeProfile() {
        authManager.completeProfileSetup(
            firstName: firstName,
            lastName: lastName,
            schoolName: schoolName,
            gradeLevel: educationLevel,
            major: major,
            academicYear: academicYear,
            context: modelContext
        )
        dismiss()
    }
}
