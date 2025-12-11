import SwiftUI
import SwiftData

struct ProfileSetupView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.modelContext) private var modelContext
    
    // Changed from UserProfile to StudentProfile
    let user: StudentProfile
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var schoolName: String = ""
    @State private var educationLevel: String = ""
    @State private var major: String = ""
    @State private var academicYear: String = ""
    
    // Image Handling
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    
    private let educationLevels = ["High School", "Bachelor's Degree", "Master's Degree", "PhD", "Other"]
    private let academicYears = ["2023-2024", "2024-2025", "2025-2026", "2026-2027", "2027-2028"]
    private let popularMajors = [
        "Computer Science", "Engineering", "Business", "Medicine", "Law",
        "Psychology", "Biology", "Chemistry", "Physics", "Mathematics",
        "Economics", "Political Science", "History", "English", "Art",
        "Music", "Architecture", "Education", "Nursing", "Other"
    ]
    
    init(user: StudentProfile) {
        self.user = user
        _firstName = State(initialValue: user.firstName)
        _lastName = State(initialValue: user.lastName)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Picture Section
                Section {
                    HStack {
                        Spacer()
                        Button(action: { showingImagePicker = true }) {
                            ZStack {
                                if let inputImage = inputImage {
                                    Image(uiImage: inputImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 100, height: 100)
                                    
                                    Image(systemName: "camera.fill")
                                        .font(.title)
                                        .foregroundColor(.gray)
                                }
                                
                                // Edit badge
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.blue) // Fixed hardcoded color
                                            .background(Circle().fill(Color.white))
                                    }
                                }
                                .frame(width: 100, height: 100)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)
                
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
                        ForEach(educationLevels, id: \.self) { Text($0).tag($0) }
                    }
                    
                    Picker("Major/Field of Study", selection: $major) {
                        Text("Select Major").tag("")
                        ForEach(popularMajors, id: \.self) { Text($0).tag($0) }
                    }
                    
                    Picker("Academic Year", selection: $academicYear) {
                        Text("Select Academic Year").tag("")
                        ForEach(academicYears, id: \.self) { Text($0).tag($0) }
                    }
                }
                
                Section(footer: Text("By completing your profile, you agree to our Terms of Service and Privacy Policy")) {
                    EmptyView()
                }
            }
            .navigationTitle("Complete Your Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        authManager.signOut(modelContext: modelContext)
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Continue") {
                        completeProfile()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker { image in
                    self.inputImage = image
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private var isFormValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !schoolName.isEmpty && !educationLevel.isEmpty && !academicYear.isEmpty
    }
    
    private func completeProfile() {
        // Update the existing user object properties
        user.firstName = firstName
        user.lastName = lastName
        user.schoolName = schoolName
        user.gradeLevel = educationLevel
        user.major = major.isEmpty ? nil : major
        user.academicYear = academicYear
        user.profileImageData = inputImage?.jpegData(compressionQuality: 0.8)
        
        // Pass the updated StudentProfile object
        authManager.completeProfileSetup(profile: user, modelContext: modelContext)
        dismiss()
    }
}
